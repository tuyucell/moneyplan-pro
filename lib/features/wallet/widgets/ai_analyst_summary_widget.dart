import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/wallet/providers/portfolio_provider.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'package:invest_guide/features/wallet/providers/bank_account_provider.dart';
import 'package:invest_guide/core/services/currency_service.dart';

class AiAnalystSummaryWidget extends ConsumerWidget {
  const AiAnalystSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final monthSummary = ref.watch(currentMonthSummaryProvider);
    final bankAccounts = ref.watch(bankAccountProvider);

    // AI Analysis Logic
    final isNegativeFlow = monthSummary.remainingBalance < 0;
    final totalIncome = monthSummary.totalIncome;
    final totalOutflow = monthSummary.totalOutflow;

    // Status Logic
    var riskLevel = 'Analiz Bekliyor';
    var riskColor = Colors.grey as Color;
    var icon = Icons.hourglass_empty;
    var analysisTitle = 'AI Portföy Analizi';

    if (isNegativeFlow) {
      analysisTitle = 'AI Finansal Strateji';
      final debtRatio = totalIncome > 0 ? (totalOutflow / totalIncome) : 10.0;

      if (debtRatio > 2.0) {
        riskLevel = 'Kritik Borç Yükü';
        riskColor = AppColors.error;
        icon = Icons.error_outline;
      } else {
        riskLevel = 'Bütçe Açığı Var';
        riskColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
      }
    } else if (portfolio.isNotEmpty) {
      analysisTitle = 'AI Portföy Analizi';
      final cryptoCount = portfolio
          .where((p) => p.symbol.length >= 3 && !p.symbol.contains('.'))
          .length;
      final totalCount = portfolio.length;
      final cryptoRatio = totalCount > 0 ? cryptoCount / totalCount : 0.0;

      if (cryptoRatio > 0.7) {
        riskLevel = 'Yüksek Risk';
        riskColor = AppColors.error;
        icon = Icons.warning_amber_rounded;
      } else if (totalCount < 3) {
        riskLevel = 'Çeşitlilik Az';
        riskColor = Colors.orange;
        icon = Icons.pie_chart_outline;
      } else {
        riskLevel = 'Dengeli & Sağlıklı';
        riskColor = AppColors.success;
        icon = Icons.check_circle_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4FD8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFF6B4FD8), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysisTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(icon, size: 14, color: riskColor),
                    const SizedBox(width: 4),
                    Text(
                      riskLevel,
                      style: TextStyle(
                          color: riskColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showAnalysisResult(context, ref, riskLevel,
                riskColor, portfolio, monthSummary, bankAccounts),
            child: const Text('Detay'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisResult(
      BuildContext context,
      WidgetRef ref,
      String riskLevel,
      Color riskColor,
      List portfolio,
      dynamic monthSummary,
      List<dynamic> bankAccounts) {
    var suggestions = <String>[];

    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(financeDisplayCurrencyProvider);
    final symbol = currencyService.getSymbol(displayCurrency);

    // 1. Cash Flow & Debt Analysis (The User's specific concern)
    final balanceTRY = monthSummary.remainingBalance;

    if (balanceTRY < 0) {
      final deficitTRY = balanceTRY.abs();
      final deficitDisplay =
          currencyService.convertFromTRY(deficitTRY, displayCurrency);
      final totalIncomeTRY = monthSummary.totalIncome;
      final incomeToOutflowRatio = totalIncomeTRY > 0
          ? (monthSummary.totalOutflow / totalIncomeTRY)
          : 10.0;

      suggestions.add(
          'Aylık bütçen ${deficitDisplay.toStringAsFixed(0)} $symbol açık veriyor.');

      if (incomeToOutflowRatio > 1.2) {
        suggestions.add(
            'Harcamaların gelirinin ${incomeToOutflowRatio.toStringAsFixed(1)} katı. İlk adım: Giderleri gelirin en az %80\'ine çekmek için bir kemer sıkma planı yapmalısın.');

        // Debt Consolidation advice
        suggestions.add(
            'Strateji 1: Kart borçlarını düşük faizli bir ihtiyaç kredisiyle kapatmayı veya yapılandırmayı değerlendir.');

        // Limit survival calculation (In TRY for consistency)
        double totalLimitTRY = 0;
        for (var acc in bankAccounts) {
          totalLimitTRY += currencyService.convertToTRY(
              acc.overdraftLimit, acc.currencyCode);
        }

        if (totalLimitTRY > 0) {
          final survivalMonths = totalLimitTRY / deficitTRY;
          if (survivalMonths < 1) {
            suggestions.add(
                'Acil Durum: Mevcut banka limitlerin bu ayı bile kurtarmayabilir. Derhal ek gelir modellerini değerlendirmelisin.');
          } else {
            suggestions.add(
                'Mevcut limitlerin bu tempo ile yaklaşık ${survivalMonths.toStringAsFixed(1)} ay daha dayanabilir.');
          }
        }
      }

      final interestDisplay = currencyService.convertFromTRY(
          monthSummary.totalInterest, displayCurrency);
      if (monthSummary.totalInterest > 0) {
        suggestions.add(
            'Maliyet: Bu ay ${interestDisplay.toStringAsFixed(0)} $symbol faiz yükü biniyor. Bu para her ay havaya gidiyor.');
      }
    }

    // 2. Portfolio Analysis
    if (portfolio.isEmpty && balanceTRY >= 0) {
      suggestions
          .add('Analiz yapabilmem için önce portföyüne varlık eklemelisin.');
      suggestions.add('Yatırım sekmesinden varlık ekleyebilirsin.');
    } else if (portfolio.isNotEmpty) {
      // ... existing portfolio logic inside the updated suggestion block
      final cryptoCount = portfolio
          .where((p) => p.symbol.length >= 3 && !p.symbol.contains('.'))
          .length;
      final totalCount = portfolio.length;
      final cryptoRatio = totalCount > 0 ? cryptoCount / totalCount : 0.0;

      if (cryptoRatio > 0.7) {
        suggestions.add(
            'Portföyün büyük oranda kripto varlıklardan oluşuyor (Yüksek Volatilite).');
        suggestions.add('Fon veya Altın ekleyerek dengeleyebilirsin.');
      } else if (totalCount < 3) {
        suggestions
            .add('Yatırım çeşitliliğin düşük. Tek bir varlığa bağımlı kalma.');
      } else if (balanceTRY >= 0) {
        suggestions.add('Portföy dağılımın dengeli görünüyor.');
      }
    }

    if (balanceTRY >= 0 && portfolio.isNotEmpty) {
      suggestions.add(
          'Kasanda artı bakiye var, tasarruf oranını %${monthSummary.savingsRate.toStringAsFixed(1)} seviyesine çekerek finansal özgürlük süreni kısaltabilirsin.');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF6B4FD8)),
                SizedBox(width: 8),
                Text('Yapay Zeka Görüşü',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: riskColor.withValues(alpha: 0.3)),
              ),
              child: Text(riskLevel,
                  style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  ...suggestions.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(s,
                                    style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
