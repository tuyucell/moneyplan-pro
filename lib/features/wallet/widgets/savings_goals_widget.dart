import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/wallet/pages/savings_goal_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/providers/balance_visibility_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';

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
      return _buildAddGoalButton(context, lc, currencyService, displayCurrency);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: context.isTablet ? 170 : 150,
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

  Widget _buildAddGoalButton(BuildContext context, String lc,
      CurrencyService currencyService, String displayCurrency) {
    final symbol = currencyService.getSymbol(displayCurrency);
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
            AppStrings.tr(AppStrings.noSavingsAccounts, lc),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.tr(AppStrings.addAccountInstruction, lc),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalDialog(context, null, lc, symbol),
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
    final currencyService = ref?.read(currencyServiceProvider);
    final displayCurrency = ref?.read(investDisplayCurrencyProvider) ?? 'TRY';
    final symbol = currencyService?.getSymbol(displayCurrency) ?? '₺';

    return InkWell(
      onTap: () => _showAddGoalDialog(context, ref, lc, symbol),
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
      dynamic goal,
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
                  child: Icon(Icons.savings,
                      size: 16, color: Color(goal.colorValue)),
                ),
                if (goal.interestRate != null)
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
                      '%${goal.interestRate}',
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

  void _showAddGoalDialog(
      BuildContext context, WidgetRef? ref, String lc, String currencySymbol) {
    if (ref == null && context.mounted) return;
    final notNullRef = ref!;

    final nameController = TextEditingController();
    final balanceController =
        TextEditingController(); // Renamed for clarity, maps to currentAmount
    final interestController = TextEditingController();
    DateTime? selectedDate;

    final currencyService = notNullRef.read(currencyServiceProvider);
    final availableCurrencies = currencyService.getAvailableCurrencies();
    var selectedCurrency = notNullRef.read(investDisplayCurrencyProvider);
    var selectedColor = 0xFFFFA726;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppStrings.tr(AppStrings.addAccount, lc)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      labelText: AppStrings.tr(AppStrings.enterAccountName, lc),
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: balanceController,
                        decoration: InputDecoration(
                            labelText: AppStrings.tr(AppStrings.balance, lc),
                            border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        items: availableCurrencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: interestController,
                        decoration: InputDecoration(
                            labelText:
                                AppStrings.tr(AppStrings.interestRate, lc),
                            border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 3650)));
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: AppStrings.tr(AppStrings.maturity, lc),
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            selectedDate != null
                                ? DateFormat('dd.MM').format(selectedDate!)
                                : AppStrings.tr(AppStrings.select, lc),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.tr(AppStrings.cancel, lc))),
            Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final balance =
                        double.tryParse(balanceController.text) ?? 0;
                    final interest = double.tryParse(interestController.text);

                    if (name.isNotEmpty) {
                      // We use 'target' as placeholder or 0 since it's a deposit account mainly
                      // But effectively for 'SavingsGoal' logic we might want target to be balance * interest?
                      // For now let's set target same as balance or higher.
                      // Actually SavingsGoal requires targetAmount. Let's set it to balance * 1.5 arbitrary or 0 if allowed (but progress bar might break).
                      // Let's treat target as 'Goal' if user wants, but for this context 'targetAmount' logic is less relevant.
                      // We'll set targetAmount to balance for now to show "full" or just hide progress bar logic in new card.

                      ref.read(savingsGoalProvider.notifier).addGoal(
                            name,
                            balance > 0 ? balance : 1000,
                            selectedColor,
                            currentAmount: balance,
                            interestRate: interest,
                            maturityDate: selectedDate,
                            currencyCode: selectedCurrency,
                          );
                      // Update current amount immediately?
                      // addGoal in provider creates with currentAmount=0 usually in default create method.
                      // Wait, I updated addGoal only to pass interest/maturity, but it calls SavingsGoal.create which has currentAmount=0 default.
                      // I should have updated addGoal logic to accept currentAmount or update it after.
                      // Let's assume for now user edits balance later or I fix provider in next step.
                      // Actually, let's fix provider to accept currentAmount in addGoal first or simply update it here if possible.
                      // Accessing the last added item is risky.

                      // FIX: I will update the provider code to accept initial amount or assume 0.
                      // But for "Bank Account", starting with 0 is weird.
                      // I'll make a second call to update amount if needed, or just let user update it.
                      // Ideally I modify provider addGoal again.
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(AppStrings.tr(AppStrings.save, lc)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
            onPressed: () {
              ref.read(savingsGoalProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.tr(AppStrings.remove, lc)),
          ),
        ],
      ),
    );
  }
}
