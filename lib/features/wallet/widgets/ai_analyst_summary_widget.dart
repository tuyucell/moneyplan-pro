import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/providers/portfolio_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/services/ai_processing_service.dart';
import 'package:moneyplan_pro/features/subscription/presentation/widgets/pro_feature_gate.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/feature_usage_provider.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';

class AiAnalystSummaryWidget extends ConsumerStatefulWidget {
  const AiAnalystSummaryWidget({super.key});

  @override
  ConsumerState<AiAnalystSummaryWidget> createState() =>
      _AiAnalystSummaryWidgetState();
}

class _AiAnalystSummaryWidgetState
    extends ConsumerState<AiAnalystSummaryWidget> {
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final monthSummary = ref.watch(currentMonthSummaryProvider);

    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Status Logic
    var riskLevel = AppStrings.tr(AppStrings.waitingForAnalysis, lc);
    Color riskColor = Colors.grey;
    var icon = Icons.hourglass_empty;

    if (monthSummary.remainingBalance < 0) {
      riskLevel = AppStrings.tr(AppStrings.budgetDeficit, lc);
      riskColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (portfolio.isNotEmpty) {
      riskLevel = AppStrings.tr(AppStrings.balancedHealthy, lc);
      riskColor = AppColors.success;
      icon = Icons.check_circle_outline;
    }

    return ProFeatureGate(
      featureName: AppStrings.tr(AppStrings.aiAnalyst, lc),
      child: Container(
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
                    AppStrings.tr(AppStrings.aiAnalyst, lc),
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
            ElevatedButton(
              onPressed: () => _handleAnalysis(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4FD8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(AppStrings.tr(AppStrings.askAi, lc),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAnalysis() async {
    setState(() => _isAnalyzing = true);

    final portfolio = ref.read(portfolioProvider);
    final monthSummary = ref.read(currentMonthSummaryProvider);
    final bankAccounts = ref.read(bankAccountProvider);
    final displayCurrency = ref.read(financeDisplayCurrencyProvider);

    // Track usage for Free users
    if (!ref.read(isProUserProvider)) {
      await ref.read(featureUsageProvider).trackUsage('ai_analyst');
    }

    final response = await AIProcessingService.getPersonalizedAnalysis(
      monthlyIncome: monthSummary.totalIncome,
      monthlyExpenses: monthSummary.totalOutflow,
      remainingBalance: monthSummary.remainingBalance,
      portfolio: portfolio,
      bankAccounts: bankAccounts,
      currency: displayCurrency,
    );

    setState(() => _isAnalyzing = false);

    if (mounted && response != null) {
      final language = ref.read(languageProvider);
      final lc = language.code;
      _showAnalysisResult(response, lc);
    }
  }

  void _showAnalysisResult(String response, String lc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6B4FD8)),
                const SizedBox(width: 8),
                Text(AppStrings.tr(AppStrings.aiAnalysis, lc),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  response,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppStrings.tr(AppStrings.gotIt, lc),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
