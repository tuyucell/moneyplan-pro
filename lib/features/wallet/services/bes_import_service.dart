import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/bes_models.dart';
import 'package:uuid/uuid.dart';

class BesImportService {
  static Future<BesAccount?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv', 'txt'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase() ?? '';

      if (extension == 'pdf') {
        return _importFromPdf(file);
      } else if (extension == 'csv') {
        return _importFromCsv(file);
      } else {
        return _importFromText(file);
      }
    }
    return null;
  }

  static Future<BesAccount?> _importFromPdf(File file) async {
    try {
      final document = PdfDocument(inputBytes: await file.readAsBytes());
      final text = PdfTextExtractor(document).extractText();
      document.dispose();

      return _parseRawText(text);
    } catch (e) {
      debugPrint('PDF Import Error: $e');
      return null;
    }
  }

  static Future<BesAccount?> _importFromCsv(File file) async {
    try {
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(
              fieldDelimiter: '\t', shouldParseNumbers: false))
          .toList();

      // If tab delimiter fails or yields single column, try semicolon (common in TR)
      var finalFields = fields;
      if (fields.isNotEmpty && fields[0].length < 2) {
        final content = await file.readAsString();
        finalFields = const CsvToListConverter(
                fieldDelimiter: ';', shouldParseNumbers: false)
            .convert(content);
      }

      // Still no luck? Try comma
      if (finalFields.isNotEmpty && finalFields[0].length < 2) {
        final content = await file.readAsString();
        finalFields = const CsvToListConverter(
                fieldDelimiter: ',', shouldParseNumbers: false)
            .convert(content);
      }

      return _parseTableFields(finalFields);
    } catch (e) {
      debugPrint('CSV Import Error: $e');
      return null;
    }
  }

  static Future<BesAccount?> _importFromText(File file) async {
    final content = await file.readAsString();
    // Try to treat text as a tab-separated table first
    final fields = const CsvToListConverter(
            fieldDelimiter: '\t', shouldParseNumbers: false)
        .convert(content);
    if (fields.isNotEmpty && fields[0].length >= 2) {
      return _parseTableFields(fields);
    }
    return _parseRawText(content);
  }

  static BesAccount? _parseTableFields(List<List<dynamic>> fields) {
    var govContribution = 0.0;
    final assets = <BesAsset>[];
    final transactions = <BesTransaction>[];

    for (final row in fields) {
      if (row.isEmpty) continue;

      final firstCell = row[0].toString().trim();
      final secondCell = row.length > 1 ? row[1].toString().trim() : '';

      // Summary Rows (Özet)
      if (firstCell.contains('Özet') ||
          secondCell.contains('Katkı Payı') ||
          secondCell.contains('Devlet Katkısı')) {
        if (secondCell.contains('Devlet Katkısı')) {
          // Typically: Özet | Devlet Katkısı | Anapara | Güncel Değer
          if (row.length >= 4) {
            govContribution = _parseTurkishNumber(row[3].toString());
          }
        } else if (secondCell.contains('Kendi') ||
            secondCell.contains('Katkı Payı')) {
          if (row.length >= 3) {
            final principal = _parseTurkishNumber(row[2].toString());
            transactions.add(BesTransaction(
              id: const Uuid().v4(),
              date: DateTime.now(),
              amount: principal,
              type: 'contribution',
              description: 'Toplam Ödenen Katkı Payı (Dökümandan)',
            ));
          }
        }
      }
      // Fund Rows (Fon)
      else if (firstCell.contains('Fon') || secondCell.contains('Fonu')) {
        if (row.length >= 4) {
          final fundName = secondCell;
          final unitsText = row[2].toString();
          final currentValue = _parseTurkishNumber(row[3].toString());

          // Parse units (e.g. "185.200 Adet" or "185,200")
          final unitsMatch = RegExp(r'([\d\.,]+)').firstMatch(unitsText);
          final units = unitsMatch != null
              ? _parseTurkishNumber(unitsMatch.group(1))
              : 1.0;

          if (units > 0) {
            assets.add(BesAsset(
              fundCode: fundName,
              units: units,
              averageCost: currentValue / units,
              lastUpdated: DateTime.now(),
            ));
          }
        }
      }
    }

    if (assets.isEmpty && transactions.isEmpty && govContribution == 0) {
      return null;
    }

    return BesAccount(
      assets: assets,
      transactions: transactions,
      governmentContribution: govContribution,
      lastDataUpdate: DateTime.now(),
    );
  }

  static BesAccount? _parseRawText(String text) {
    var govContribution = 0.0;
    final assets = <BesAsset>[];

    // State contribution search
    final govMatch = RegExp(
            r'Devlet Katkı(?:sı)?\s*(?:Bakiyesi|Tutarı)?\s*[:\s]*([\d\.,]+)',
            caseSensitive: false)
        .firstMatch(text);
    if (govMatch != null) {
      govContribution = _parseTurkishNumber(govMatch.group(1));
    }

    return BesAccount(
      assets: assets,
      transactions: [],
      governmentContribution: govContribution,
      lastDataUpdate: DateTime.now(),
    );
  }

  static double _parseTurkishNumber(String? value) {
    if (value == null || value.isEmpty) return 0;

    // Scenarios:
    // 1. "125.4" (Dot as decimal, but in TR it's usually comma)
    // 2. "1.234,56" (Dot thousands, comma decimal)
    // 3. "1234,56" (No thousands, comma decimal)

    var sanitized = value.trim();

    // If it contains both dot and comma, assume standard TR format
    if (sanitized.contains('.') && sanitized.contains(',')) {
      sanitized = sanitized.replaceAll('.', '').replaceAll(',', '.');
    }
    // If it only contains comma, it's the decimal separator
    else if (sanitized.contains(',')) {
      sanitized = sanitized.replaceAll(',', '.');
    }
    // If it only contains a dot, we need to guess.
    // Usually if it's 3 digits after dot (like 125.400), it might be thousands in TR.
    // However, the user input "125.4" looks like a simple decimal.
    // We'll treat a single dot as a decimal unless it's followed by exactly 3 digits?
    // That's risky. Let's assume dot is decimal if it's the only separator.

    return double.tryParse(sanitized) ?? 0;
  }
}
