import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/investment_wizard/models/investment_plan_data.dart';

class ExportService {
  static Future<PdfFont> _getBoldFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return PdfTrueTypeFont(data.buffer.asUint8List(), 12,
          style: PdfFontStyle.bold);
    } catch (e) {
      debugPrint('Font load error: $e');
      return PdfStandardFont(PdfFontFamily.helvetica, 12,
          style: PdfFontStyle.bold);
    }
  }

  static Future<PdfFont> _getNormalFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      return PdfTrueTypeFont(data.buffer.asUint8List(), 10);
    } catch (e) {
      debugPrint('Font load error: $e');
      return PdfStandardFont(PdfFontFamily.helvetica, 10);
    }
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

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'MoneyPlan Pro İşlem Dökümü (CSV)',
      ),
    );
  }

  static Future<void> exportToPdf(List<WalletTransaction> transactions) async {
    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      // Custom Fonts with Turkish support
      final boldFont = await _getBoldFont();
      final normalFont = await _getNormalFont();

      // Premium Colors
      final indigoBrush = PdfSolidBrush(PdfColor(79, 70, 229)); // indigo-600
      final successBrush = PdfSolidBrush(PdfColor(16, 185, 129)); // emerald-500
      final errorBrush = PdfSolidBrush(PdfColor(239, 68, 68)); // red-500

      // 1. HEADER
      page.graphics.drawRectangle(
        brush: indigoBrush,
        bounds: Rect.fromLTWH(0, 0, pageSize.width, 60),
      );

      page.graphics.drawString(
        'MONEYPLAN PRO',
        boldFont,
        bounds: Rect.fromLTWH(20, 15, pageSize.width, 30),
        brush: PdfBrushes.white,
      );

      page.graphics.drawString(
        'Finansal İşlem Raporu',
        normalFont,
        bounds: Rect.fromLTWH(pageSize.width - 200, 20, 180, 20),
        brush: PdfBrushes.white,
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      page.graphics.drawString(
        'Rapor Tarihi: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
        normalFont,
        bounds: Rect.fromLTWH(0, 75, pageSize.width, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // 2. SUMMARY SECTION
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

      for (var i = 0; i < 3; i++) {
        summaryGrid.rows[0].cells[i].style = PdfGridCellStyle(
          backgroundBrush: indigoBrush,
          textBrush: PdfBrushes.white,
          font: boldFont,
          cellPadding: PdfPaddings(left: 10, top: 5, bottom: 5),
        );
        summaryGrid.rows[1].cells[i].style = PdfGridCellStyle(
          font: boldFont,
          cellPadding: PdfPaddings(left: 10, top: 10, bottom: 10),
        );
      }

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
      header.cells[2].value = 'Açıklama';
      header.cells[3].value = 'Miktar';
      header.cells[4].value = 'Durum';

      header.style = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(31, 41, 55)),
        textBrush: PdfBrushes.white,
        font: boldFont,
        cellPadding: PdfPaddings(left: 5, top: 8, bottom: 8),
      );

      for (final t in transactions) {
        final category = TransactionCategory.findById(t.categoryId);
        final row = grid.rows.add();
        row.cells[0].value = DateFormat('dd.MM.yyyy').format(t.date);
        row.cells[1].value = category?.name ?? t.categoryId;
        row.cells[2].value = t.note ?? '-';
        row.cells[3].value = '${t.amount.toStringAsFixed(2)} ${t.currencyCode}';
        row.cells[4].value = t.isPaid ? 'Ödendi' : 'Bekliyor';

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
        PdfPen(PdfColor(209, 213, 219)),
        Offset(0, footerY),
        Offset(pageSize.width, footerY),
      );

      page.graphics.drawString(
        'MoneyPlan Pro AI tarafından otomatik oluşturulmuştur. | www.investguide.app',
        normalFont,
        bounds: Rect.fromLTWH(0, footerY + 5, pageSize.width, 20),
        brush: PdfSolidBrush(PdfColor(107, 114, 128)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final bytes = await document.save();
      document.dispose();

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/moneyplan_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'MoneyPlan Pro Finansal Rapor (PDF)',
        ),
      );
    } catch (e) {
      debugPrint('Export Error: $e');
      rethrow;
    }
  }

  static Future<void> exportInvestmentPlanToPdf(
      InvestmentPlanData plan, Map<String, dynamic> results) async {
    try {
      final document = PdfDocument();
      final page = document.pages.add();
      final pageSize = page.getClientSize();

      final boldFont = await _getBoldFont();
      final normalFont = await _getNormalFont();
      final indigoBrush = PdfSolidBrush(PdfColor(79, 70, 229));

      // 1. HEADER
      page.graphics.drawRectangle(
          brush: indigoBrush, bounds: Rect.fromLTWH(0, 0, pageSize.width, 80));
      page.graphics.drawString('INVESTGUIDE AI', boldFont,
          bounds: Rect.fromLTWH(20, 20, pageSize.width, 30),
          brush: PdfBrushes.white);
      page.graphics.drawString('Kişiselleştirilmiş Yatırım Planı', normalFont,
          bounds: Rect.fromLTWH(20, 50, pageSize.width, 20),
          brush: PdfBrushes.white);

      // 2. USER PROFILE
      double y = 100;
      page.graphics.drawString('Finansal Özet', boldFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 20));
      y += 25;
      page.graphics.drawString(
          '• Aylık Gelir: ${plan.monthlyIncome.toStringAsFixed(0)} ${plan.currencyCode}',
          normalFont,
          bounds: Rect.fromLTWH(10, y, pageSize.width, 20));
      y += 18;
      page.graphics.drawString(
          '• Aylık Gider: ${plan.monthlyExpenses.toStringAsFixed(0)} ${plan.currencyCode}',
          normalFont,
          bounds: Rect.fromLTWH(10, y, pageSize.width, 20));
      y += 18;
      page.graphics.drawString(
          '• Planlanan Yatırım: ${plan.monthlyInvestmentAmount.toStringAsFixed(0)} ${plan.currencyCode}',
          normalFont,
          bounds: Rect.fromLTWH(10, y, pageSize.width, 20));

      // 3. AI RECOMMENDATION
      y += 40;
      page.graphics.drawString('Yapay Zeka Tavsiyesi', boldFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 20));
      y += 25;
      final description = plan.aiRecommendation?['description'] ?? '-';
      page.graphics.drawString(description, normalFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 60));

      // 4. ALLOCATION TABLE
      y += 60;
      page.graphics.drawString('Önerilen Varlık Dağılımı', boldFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 20));
      y += 25;

      final allocation =
          plan.aiRecommendation?['allocation'] as Map<String, dynamic>? ?? {};
      final allocationGrid = PdfGrid();
      allocationGrid.columns.add(count: 2);
      allocationGrid.headers.add(1);
      final h = allocationGrid.headers[0];
      h.cells[0].value = 'Varlık Sınıfı';
      h.cells[1].value = 'Oran (%)';
      h.style = PdfGridCellStyle(font: boldFont);

      allocation.forEach((key, value) {
        final row = allocationGrid.rows.add();
        row.cells[0].value = key;
        row.cells[1].value = '%$value';
      });

      allocationGrid.draw(
          page: page, bounds: Rect.fromLTWH(0, y, pageSize.width, 200));

      // 5. SUGGESTED ASSETS
      y += 150;
      page.graphics.drawString('Takip Edilmesi Önerilen Semboller', boldFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 20));
      y += 25;
      final symbols =
          (plan.aiRecommendation?['suggestedAssets'] as List<dynamic>?)
                  ?.join(', ') ??
              '-';
      page.graphics.drawString(symbols, normalFont,
          bounds: Rect.fromLTWH(0, y, pageSize.width, 40));

      // Save & Share
      final bytes = await document.save();
      document.dispose();
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/invest_plan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'Yatırım Planım (PDF)',
        ),
      );
    } catch (e) {
      debugPrint('Plan Export Error: $e');
    }
  }
}
