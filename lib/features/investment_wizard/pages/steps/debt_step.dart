import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/investment_plan_provider.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class DebtStep extends ConsumerWidget {
  final TextEditingController debtAmountController;
  final TextEditingController debtPaymentController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const DebtStep({
    super.key,
    required this.debtAmountController,
    required this.debtPaymentController,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(investmentPlanProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.debtStatusTitle, lc),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tr(AppStrings.debtStatusDesc, lc),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.tr(AppStrings.haveDebtQuestion, lc),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InvestmentChoiceButton(
                  label: AppStrings.tr(AppStrings.no, lc),
                  isSelected: !plan.hasDebt,
                  onTap: () {
                    ref
                        .read(investmentPlanProvider.notifier)
                        .updateHasDebt(false);
                    debtAmountController.clear();
                    debtPaymentController.clear();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InvestmentChoiceButton(
                  label: AppStrings.tr(AppStrings.yes, lc),
                  isSelected: plan.hasDebt,
                  onTap: () {
                    ref
                        .read(investmentPlanProvider.notifier)
                        .updateHasDebt(true);
                  },
                ),
              ),
            ],
          ),
          if (plan.hasDebt) ...[
            const SizedBox(height: 24),
            InvestmentInputField(
              controller: debtAmountController,
              label: AppStrings.tr(AppStrings.totalDebtLabel, lc)
                  .replaceAll(RegExp(r'\s*\(.*\)\s*'), ''),
              hint: AppStrings.tr(AppStrings.hintAmount, lc),
              icon: Icons.credit_card,
              suffix: plan.currencyCode,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                ref
                    .read(investmentPlanProvider.notifier)
                    .updateDebtAmount(amount);
              },
            ),
            const SizedBox(height: 20),
            InvestmentInputField(
              controller: debtPaymentController,
              label: AppStrings.tr(AppStrings.monthlyDebtPaymentLabel, lc)
                  .replaceAll(RegExp(r'\s*\(.*\)\s*'), ''),
              hint: AppStrings.tr(AppStrings.hintAmount, lc),
              icon: Icons.payment,
              suffix: plan.currencyCode,
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0;
                ref
                    .read(investmentPlanProvider.notifier)
                    .updateMonthlyDebtPayment(amount);
              },
            ),
            if (plan.monthsToPayOffDebt > 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.warning),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.tr(AppStrings.debtPayoffEstimateTitle, lc),
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tr(AppStrings.debtPayoffMsg, lc)
                          .replaceAll(
                              '{months}', plan.monthsToPayOffDebt.toString())
                          .replaceAll(
                              '{years}',
                              plan.yearsToPayOffDebt > 0
                                  ? '(${plan.yearsToPayOffDebt.toStringAsFixed(1)} ${AppStrings.tr(AppStrings.years, lc)})'
                                  : ''),
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                    AppStrings.tr(AppStrings.continueBtn, lc),
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
