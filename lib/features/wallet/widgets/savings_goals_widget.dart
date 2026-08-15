import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/pages/savings_goal_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/providers/balance_visibility_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/widgets/savings_plan_editor_dialog.dart';

class SavingsGoalsWidget extends ConsumerWidget {
  const SavingsGoalsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final goals = ref.watch(savingsGoalProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(investDisplayCurrencyProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);

    if (goals.isEmpty) {
      return _buildAddGoalButton(context, lc);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: context.isTablet ? 190 : 174,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: goals.length + 1,
            itemBuilder: (context, index) {
              if (index == goals.length) {
                return _buildAddSmallCard(context, ref, lc);
              }
              final goal = goals[index];
              return _buildGoalCard(context, ref, goal, lc, currencyService,
                  displayCurrency, isVisible);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddGoalButton(BuildContext context, String lc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance,
              size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            lc == 'tr' ? 'Henüz birikim planı yok' : 'No savings plan yet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            lc == 'tr'
                ? 'Birikim hesabı, BES veya hayat sigortası ekleyin.'
                : 'Add savings, pension or life insurance.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => showSavingsPlanEditor(context),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.tr(AppStrings.addAccount, lc)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSmallCard(BuildContext context, WidgetRef? ref, String lc) {
    return InkWell(
      onTap: () => showSavingsPlanEditor(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add,
                color: AppColors.primary.withValues(alpha: 0.5), size: 32),
            const SizedBox(height: 4),
            Text(AppStrings.tr(AppStrings.addAccount, lc),
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
      BuildContext context,
      WidgetRef ref,
      SavingsGoal goal,
      String lc,
      CurrencyService currencyService,
      String displayCurrency,
      bool isVisible) {
    final currencyFormat = NumberFormat.currency(
        locale: displayCurrency == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: currencyService.getSymbol(displayCurrency),
        decimalDigits: 0);

    // Convert native amount to TRY first, then to the global display currency
    final inTRY =
        currencyService.convertToTRY(goal.currentAmount, goal.currencyCode);
    final displayAmount =
        currencyService.convertFromTRY(inTRY, displayCurrency);

    return InkWell(
      onLongPress: () => _showDeleteConfirmation(context, ref, goal, lc),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SavingsGoalDetailPage(goal: goal)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180, // Wider for more info
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.shadowSm(context),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(goal.colorValue).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_planIcon(goal.planType),
                      size: 16, color: Color(goal.colorValue)),
                ),
                if (goal.interestRate != null || goal.isContractPlan)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _planBadge(goal, lc),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              goal.name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.adaptiveSp(14),
                  color: AppColors.textPrimary(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(displayAmount).mask(isVisible),
              style: TextStyle(
                  fontSize: context.adaptiveSp(16),
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.bold),
            ),
            if (goal.isContractPlan && goal.periodicContribution > 0)
              Text(
                '${_periodLabel(goal.contributionPeriod, lc)} · ${goal.currencyCode} ${goal.periodicContribution.toStringAsFixed(goal.periodicContribution.truncateToDouble() == goal.periodicContribution ? 0 : 2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (goal.maturityDate != null) ...[
              const SizedBox(height: 6),
              Text(
                '${AppStrings.tr(AppStrings.maturity, lc)}: ${DateFormat('dd.MM.yyyy').format(goal.maturityDate!)}',
                style: TextStyle(
                    fontSize: 10, color: AppColors.textSecondary(context)),
              ),
            ] else
              const SizedBox(height: 16), // Spacer if no date
          ],
        ),
      ),
    );
  }

  IconData _planIcon(SavingsPlanType type) => switch (type) {
        SavingsPlanType.savings => Icons.savings,
        SavingsPlanType.bes => Icons.account_balance,
        SavingsPlanType.lifeInsurance => Icons.health_and_safety,
      };

  String _planBadge(SavingsGoal goal, String lc) => switch (goal.planType) {
        SavingsPlanType.savings => '%${goal.interestRate ?? 0}',
        SavingsPlanType.bes =>
          'BES +%${goal.governmentContributionRate.toStringAsFixed(0)}',
        SavingsPlanType.lifeInsurance => lc == 'tr' ? 'HAYAT' : 'LIFE',
      };

  String _periodLabel(ContributionPeriod period, String lc) => switch (period) {
        ContributionPeriod.monthly => lc == 'tr' ? 'Aylık' : 'Monthly',
        ContributionPeriod.quarterly => lc == 'tr' ? '3 aylık' : 'Quarterly',
        ContributionPeriod.semiAnnual => lc == 'tr' ? '6 aylık' : 'Semiannual',
        ContributionPeriod.yearly => lc == 'tr' ? 'Yıllık' : 'Yearly',
      };

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, dynamic goal, String lc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr(AppStrings.remove, lc)),
        content: Text(AppStrings.tr(AppStrings.confirmRemove, lc)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.tr(AppStrings.cancel, lc))),
          TextButton(
            onPressed: () async {
              if (ref.read(walletProvider).any(
                  (transaction) => transaction.id == goal.ledgerSourceId)) {
                await ref
                    .read(walletProvider.notifier)
                    .deleteTransaction(goal.ledgerSourceId);
              }
              await ref.read(savingsGoalProvider.notifier).deleteGoal(goal.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.tr(AppStrings.remove, lc)),
          ),
        ],
      ),
    );
  }
}
