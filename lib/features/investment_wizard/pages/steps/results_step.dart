import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/investment_plan_provider.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class ResultsStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ResultsStep({
    super.key,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final plan = ref.watch(investmentPlanProvider);
    final notifier = ref.read(investmentPlanProvider.notifier);
    final results = notifier.calculateInvestmentPlan();
    final numberFormat = NumberFormat('#,##0', lc == 'tr' ? 'tr_TR' : 'en_US');
    final currencySymbol = plan.currencyDisplay;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.yourPlanTitle, lc),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tr(AppStrings.planProjectionsDesc, lc),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tr(AppStrings.monthlyInvestLabelShort, lc),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${numberFormat.format(plan.monthlyInvestmentAmount)} $currencySymbol',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.hasDebt && plan.monthlyDebtPayment > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              lc == 'tr'
                                  ? '(${plan.monthsToPayOffDebt} ay sonra başlayacak)'
                                  : '(Starts in ${plan.monthsToPayOffDebt} months)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (plan.hasDebt) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.tr(AppStrings.debtPayoffDurationLabel, lc),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        plan.yearsToPayOffDebt < 1
                            ? '${plan.monthsToPayOffDebt} ${AppStrings.tr(AppStrings.months, lc).toLowerCase()}'
                            : '${plan.yearsToPayOffDebt.toStringAsFixed(1)} ${AppStrings.tr(AppStrings.years, lc).toLowerCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Investment Projections
          Text(
            AppStrings.tr(AppStrings.investmentProjectionsTitle, lc),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),

          InvestmentProjectionCard(
            period: '5 ${AppStrings.tr(AppStrings.years, lc)}',
            values: results['projections']['5_years'],
            numberFormat: numberFormat,
            currencySymbol: currencySymbol,
            selectedProfile: plan.riskProfile,
            onProfileSelected: (profile) {
              ref
                  .read(investmentPlanProvider.notifier)
                  .updateRiskProfile(profile);
            },
          ),
          const SizedBox(height: 12),
          InvestmentProjectionCard(
            period: '10 ${AppStrings.tr(AppStrings.years, lc)}',
            values: results['projections']['10_years'],
            numberFormat: numberFormat,
            currencySymbol: currencySymbol,
            selectedProfile: plan.riskProfile,
            onProfileSelected: (profile) {
              ref
                  .read(investmentPlanProvider.notifier)
                  .updateRiskProfile(profile);
            },
          ),
          const SizedBox(height: 24),

          // Inflation Info Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr(AppStrings.inflationNoteTitle, lc),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.tr(AppStrings.inflationNoteDesc, lc),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                  child: Text(AppStrings.tr(AppStrings.back, lc),
                      style: TextStyle(color: AppColors.textPrimary(context))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.tr(AppStrings.nextRecsBtn, lc),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
