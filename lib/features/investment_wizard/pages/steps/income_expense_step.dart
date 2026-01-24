import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/currency_service.dart';
import '../../providers/investment_plan_provider.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class IncomeExpenseStep extends ConsumerWidget {
  final TextEditingController incomeController;
  final TextEditingController expensesController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const IncomeExpenseStep({
    super.key,
    required this.incomeController,
    required this.expensesController,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(investmentPlanProvider);
    final available = plan.monthlyAvailable;
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // We can use a simpler formatter or the existing one depending on needs.
    // The previous code hardcoded 'tr_TR', let's stick to it or make it dynamic if needed.
    // Ideally use NumberFormat.currency or similar, but for now simple format is okay.
    final numberFormat = NumberFormat('#,##0', lc == 'tr' ? 'tr_TR' : 'en_US');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.monthlyIncomeLabel, lc)
                .replaceAll(' (₺)', '')
                .replaceAll(' (\$)', ''), // Using label as title part
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lc == 'tr'
                ? 'Aylık ortalama gelir ve giderlerinizi girin.'
                : 'Enter your average monthly income and expenses.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),

          // Currency Selection
          Text(
            lc == 'tr' ? 'Para Birimi' : 'Currency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: plan.currencyCode,
                isExpanded: true,
                items: ref
                    .read(currencyServiceProvider)
                    .getAvailableCurrencies()
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(investmentPlanProvider.notifier)
                        .updateCurrencyCode(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          InvestmentInputField(
            controller: incomeController,
            label: AppStrings.tr(AppStrings.monthlyIncomeLabel, lc)
                .replaceAll(RegExp(r'\s*\(.*\)\s*'), ''),
            hint: AppStrings.tr(AppStrings.hintAmount, lc),
            icon: Icons.attach_money,
            suffix: plan.currencyDisplay,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              ref
                  .read(investmentPlanProvider.notifier)
                  .updateMonthlyIncome(amount);
            },
          ),
          const SizedBox(height: 20),
          InvestmentInputField(
            controller: expensesController,
            label: AppStrings.tr(AppStrings.monthlyExpensesLabel, lc)
                .replaceAll(RegExp(r'\s*\(.*\)\s*'), ''),
            hint: AppStrings.tr(AppStrings.hintAmount, lc),
            icon: Icons.shopping_cart,
            suffix: plan.currencyDisplay,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0;
              ref
                  .read(investmentPlanProvider.notifier)
                  .updateMonthlyExpenses(amount);
            },
          ),
          const SizedBox(height: 24),
          if (available > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${AppStrings.tr(AppStrings.monthlyAvailableLabel, lc).replaceAll(RegExp(r'[:₺\$]'), '')}: ${numberFormat.format(available)} ${plan.currencyDisplay}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (available < 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${lc == 'tr' ? 'Aylık bütçe açığınız' : 'Monthly budget deficit'}: ${numberFormat.format(available.abs())} ${plan.currencyDisplay}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
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
                  onPressed: plan.monthlyIncome > 0 ? onNext : null,
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
