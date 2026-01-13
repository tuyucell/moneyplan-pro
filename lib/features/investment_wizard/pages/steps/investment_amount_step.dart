import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/investment_plan_provider.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class InvestmentAmountStep extends ConsumerWidget {
  final TextEditingController investmentController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback? onJumpToIncome;

  const InvestmentAmountStep({
    super.key,
    required this.investmentController,
    required this.onNext,
    required this.onPrevious,
    this.onJumpToIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(investmentPlanProvider);
    final maxAmount =
        plan.hasDebt ? plan.monthlyAfterDebt : plan.monthlyAvailable;
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final numberFormat = NumberFormat('#,##0', lc == 'tr' ? 'tr_TR' : 'en_US');

    Widget buildQuickAmountButton(String label, double amount) {
      final safeAmount = amount < 0 ? 0.0 : amount;
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: safeAmount > 0
              ? () {
                  investmentController.text = safeAmount.toInt().toString();
                  ref
                      .read(investmentPlanProvider.notifier)
                      .updateMonthlyInvestmentAmount(safeAmount);
                }
              : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(
                color: safeAmount > 0 ? AppColors.primary : Colors.grey),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
              '$label (${numberFormat.format(safeAmount)} ${plan.currencyCode})'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.investmentAmountTitle, lc),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                maxAmount > 0
                    ? '${AppStrings.tr(AppStrings.maxInvestMsg, lc).replaceAll(RegExp(r'[:₺\$]'), '')}: ${numberFormat.format(maxAmount)} ${plan.currencyCode}'
                    : (lc == 'tr'
                        ? 'Önce bütçe açığınızı kapatmanız önerilir.'
                        : 'We recommend balancing your budget first.'),
                style: TextStyle(
                  fontSize: 14,
                  color: maxAmount > 0
                      ? AppColors.textSecondary(context)
                      : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (plan.hasDebt && plan.monthlyDebtPayment > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lc == 'tr'
                        ? '💡 Borcun bittiğinde (${plan.monthsToPayOffDebt} ay sonra) yatırım kapasiten ${numberFormat.format(plan.potentialInvestmentAmount)} ${plan.currencyCode}\'ye yükselecek!'
                        : '💡 Once debt is paid (in ${plan.monthsToPayOffDebt} months), your capacity will rise to ${numberFormat.format(plan.potentialInvestmentAmount)} ${plan.currencyCode}!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          InvestmentInputField(
            controller: investmentController,
            label: AppStrings.tr(AppStrings.monthlyInvestLabel, lc)
                .replaceAll(RegExp(r'\s*\(.*\)\s*'), ''),
            hint: AppStrings.tr(AppStrings.hintAmount, lc),
            icon: Icons.account_balance_wallet,
            suffix: plan.currencyCode,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              ref
                  .read(investmentPlanProvider.notifier)
                  .updateMonthlyInvestmentAmount(amount);
            },
          ),
          const SizedBox(height: 24),
          buildQuickAmountButton('25%', maxAmount * 0.25),
          const SizedBox(height: 12),
          buildQuickAmountButton('50%', maxAmount * 0.50),
          const SizedBox(height: 12),
          buildQuickAmountButton('75%', maxAmount * 0.75),
          const SizedBox(height: 12),
          buildQuickAmountButton('100%', maxAmount),
          const SizedBox(height: 32),
          if (onJumpToIncome != null)
            Center(
              child: TextButton.icon(
                onPressed: onJumpToIncome,
                icon: const Icon(Icons.trending_up, size: 18),
                label: Text(
                  lc == 'tr'
                      ? 'Gelirimi Artır / Bütçemi Düzenle'
                      : 'Increase Income / Edit Budget',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 16),
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
                  onPressed: plan.monthlyInvestmentAmount > 0 ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.tr(AppStrings.seePlanBtn, lc),
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
