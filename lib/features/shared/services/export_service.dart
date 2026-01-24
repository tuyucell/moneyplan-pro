import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';

class ExportService {
  static String _sanitize(String text) {
    return text
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  static Future<void> exportToCsv(List<WalletTransaction> transactions) async {
    final rows = <List<dynamic>>[];

    // Header
    rows.add([
      'ID',
      'Tarih',
      'Kategori',
      'Açıklama',
      'Miktar',
      'Para Birimi',
      'Tür',
      'Ödeme Yöntemi',
      'Abonelik mi?',
      'Ödendi mi?',
      'Vade Tarihi',
    ]);

    for (var t in transactions) {
      final category = TransactionCategory.findById(t.categoryId);
      rows.add([
        t.id,
        DateFormat('dd.MM.yyyy').format(t.date),
        category?.name ?? t.categoryId,
        t.note ?? '',
        t.amount,
        t.currencyCode,
        t.type.name == 'income' ? 'Gelir' : 'Gider',
        t.paymentMethod.name,
        t.isSubscription ? 'Evet' : 'Hayır',
        t.isPaid ? 'Evet' : 'Hayır',
        t.dueDate != null ? DateFormat('dd.MM.yyyy').format(t.dueDate!) : '',
      ]);
    }

    final csvStr = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/moneyplan_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvStr, flush: true);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)],
        text: _sanitize('MoneyPlan Pro İşlem Dökümü (CSV)'));
  }

  static Future<void> exportToPdf(List<WalletTransaction> transactions) async {
    try {
      // Create a new PDF document.
      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      // Premium Colors
      final indigoBrush = PdfSolidBrush(PdfColor(79, 70, 229)); // indigo-600
      final successBrush = PdfSolidBrush(PdfColor(16, 185, 129)); // emerald-500
      final errorBrush = PdfSolidBrush(PdfColor(239, 68, 68)); // red-500

      // Fonts
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 26,
          style: PdfFontStyle.bold);
      final subTitleFont = PdfStandardFont(PdfFontFamily.helvetica, 14);
      final normalFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final headerFont = PdfStandardFont(PdfFontFamily.helvetica, 10,
          style: PdfFontStyle.bold);

      // 1. HEADER - Premium Look
      page.graphics.drawRectangle(
        brush: indigoBrush,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, 60),
      );

      page.graphics.drawString(
        'INVESTGUIDE PRO',
        titleFont,
        bounds: Rect.fromLTWH(20, 15, pageSize.width, 30),
        brush: PdfBrushes.white,
      );

      page.graphics.drawString(
        'Finansal Islem Raporu',
        subTitleFont,
        bounds: Rect.fromLTWH(pageSize.width - 200, 20, 180, 20),
        brush: PdfBrushes.white,
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // Date & Info
      page.graphics.drawString(
        'Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
        normalFont,
        bounds: Rect.fromLTWH(0, 75, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // 2. SUMMARY SECTION - Styled Cards
      double totalIncome = 0;
      double totalExpense = 0;
      for (final t in transactions) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else {
          totalExpense += t.amount;
        }
      }

      final summaryGrid = PdfGrid();
      summaryGrid.columns.add(count: 3);
      summaryGrid.rows.add();
      summaryGrid.rows[0].cells[0].value = 'Toplam Gelir';
      summaryGrid.rows[0].cells[1].value = 'Toplam Gider';
      summaryGrid.rows[0].cells[2].value = 'Net Durum';

      summaryGrid.rows.add();
      summaryGrid.rows[1].cells[0].value =
          '+ ${totalIncome.toStringAsFixed(2)} TRY';
      summaryGrid.rows[1].cells[1].value =
          '- ${totalExpense.abs().toStringAsFixed(2)} TRY';
      summaryGrid.rows[1].cells[2].value =
          '${(totalIncome + totalExpense).toStringAsFixed(2)} TRY';

      // Style Summary Grid
      for (var i = 0; i < 3; i++) {
        summaryGrid.rows[0].cells[i].style = PdfGridCellStyle(
          backgroundBrush: indigoBrush,
          textBrush: PdfBrushes.white,
          font: headerFont,
          cellPadding: PdfPaddings(left: 10, top: 5, bottom: 5),
        );
        summaryGrid.rows[1].cells[i].style = PdfGridCellStyle(
          font: headerFont,
          cellPadding: PdfPaddings(left: 10, top: 10, bottom: 10),
        );
      }

      // Specific colors for summary values
      summaryGrid.rows[1].cells[0].style.textBrush = successBrush;
      summaryGrid.rows[1].cells[1].style.textBrush = errorBrush;
      summaryGrid.rows[1].cells[2].style.textBrush =
          (totalIncome + totalExpense) >= 0 ? successBrush : errorBrush;

      summaryGrid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 100, pageSize.width, 60),
      );

      // 3. TRANSACTIONS GRID
      final grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      final header = grid.headers[0];
      header.cells[0].value = 'Tarih';
      header.cells[1].value = 'Kategori';
      header.cells[2].value = 'Aciklama';
      header.cells[3].value = 'Miktar';
      header.cells[4].value = 'Durum';

      header.style = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(31, 41, 55)), // dark gray
        textBrush: PdfBrushes.white,
        font: headerFont,
        cellPadding: PdfPaddings(left: 5, top: 8, bottom: 8),
      );

      for (final t in transactions) {
        final category = TransactionCategory.findById(t.categoryId);
        final row = grid.rows.add();
        row.cells[0].value = DateFormat('dd.MM.yyyy').format(t.date);
        row.cells[1].value = _sanitize(category?.name ?? t.categoryId);
        row.cells[2].value = _sanitize(t.note ?? '-');
        row.cells[3].value = '${t.amount.toStringAsFixed(2)} ${t.currencyCode}';
        row.cells[4].value = t.isPaid ? 'Odendi' : 'Bekliyor';

        if (t.type == TransactionType.income) {
          row.cells[3].style = PdfGridCellStyle(textBrush: successBrush);
        } else {
          row.cells[3].style = PdfGridCellStyle(textBrush: errorBrush);
        }
      }

      grid.style.cellPadding = PdfPaddings(left: 5, top: 5);
      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 180, pageSize.width, pageSize.height - 220),
      );

      // 4. FOOTER
      final footerY = pageSize.height - 30;
      page.graphics.drawLine(
        PdfPen(PdfColor(209, 213, 219)), // gray-300
        Offset(0, footerY),
        Offset(pageSize.width, footerY),
      );

      page.graphics.drawString(
        'InvestGuide AI tarafindan otomatik olarak hazirlanmistir. | www.investguide.app',
        PdfStandardFont(PdfFontFamily.helvetica, 8),
        bounds: Rect.fromLTWH(0, footerY + 5, pageSize.width, 20),
        brush: PdfSolidBrush(PdfColor(107, 114, 128)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Save the document.
      final bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/moneyplan_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(path)],
          text: _sanitize('MoneyPlan Pro Finansal Rapor (PDF)'));
    } catch (e) {
      debugPrint('Export Error: $e');
      rethrow;
    }
  }
}
