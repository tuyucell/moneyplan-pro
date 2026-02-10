import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class SavingsGoalDetailPage extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailPage({super.key, required this.goal});

  @override
  ConsumerState<SavingsGoalDetailPage> createState() =>
      _SavingsGoalDetailPageState();
}

class _SavingsGoalDetailPageState extends ConsumerState<SavingsGoalDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Listen to changes in the list to update local state if needed,
    // or just find the goal from the list to get the latest version.
    final goals = ref.watch(savingsGoalProvider);
    final upToDateGoal = goals.firstWhere((g) => g.id == widget.goal.id,
        orElse: () => widget.goal);

    // If deleted, pop
    if (!goals.any((g) => g.id == widget.goal.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final progress = upToDateGoal.progressPercentage;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(upToDateGoal.name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context))),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined,
                color: AppColors.textSecondary(context)),
            onPressed: () =>
                _showEditGoalDialog(context, ref, upToDateGoal, lc),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Big Circular Progress
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: AppColors.border(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(upToDateGoal.colorValue)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.savings_outlined,
                          size: 48, color: Color(upToDateGoal.colorValue)),
                      const SizedBox(height: 8),
                      Text(
                        '%${(progress * 100).toStringAsFixed(1)}',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      context,
                      AppStrings.tr(AppStrings.saved, lc),
                      currencyFormat.format(upToDateGoal.currentAmount),
                      AppColors.success),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                      context,
                      AppStrings.tr(AppStrings.goalTarget, lc),
                      currencyFormat.format(upToDateGoal.targetAmount),
                      Color(upToDateGoal.colorValue)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Actions
            ElevatedButton.icon(
              onPressed: () =>
                  _showAddMoneyDialog(context, ref, upToDateGoal, lc),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.tr(AppStrings.addMoney, lc)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  _showWithdrawDialog(context, ref, upToDateGoal, lc),
              icon: const Icon(Icons.remove),
              label: Text(AppStrings.tr(AppStrings.withdrawSpend, lc)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 56),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.textTertiary(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.tr(AppStrings.savingsMotivationTip, lc),
                      style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm(context),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(
      BuildContext context, WidgetRef ref, SavingsGoal goal, String lc) {
    final controller = TextEditingController();
    var deductFromWallet = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(AppStrings.tr(AppStrings.addToPiggyBank, lc)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '${AppStrings.tr(AppStrings.balance, lc)} (₺)',
                    prefixText: '₺ ',
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: deductFromWallet,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => deductFromWallet = val ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => deductFromWallet = !deductFromWallet),
                      child: Text(
                        AppStrings.tr(AppStrings.deductFromWallet, lc),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (deductFromWallet)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4),
                  child: Text(
                    AppStrings.tr(AppStrings.savingsCategoryInfo, lc),
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary(context)),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.tr(AppStrings.cancel, lc))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  await ref
                      .read(savingsGoalProvider.notifier)
                      .updateGoalAmount(goal.id, goal.currentAmount + amount);

                  if (deductFromWallet) {
                    final transaction = WalletTransaction(
                      id: const Uuid().v4(),
                      categoryId: 'savings',
                      amount: amount,
                      date: DateTime.now(),
                      type: TransactionType.expense,
                      note:
                          '${goal.name} ${AppStrings.tr(AppStrings.savingsAddNote, lc)}',
                    );
                    await ref
                        .read(walletProvider.notifier)
                        .addTransaction(transaction);

                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              AppStrings.tr(AppStrings.addedToPiggyBank, lc))),
                    );
                  }

                  if (mounted) navigator.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: Text(AppStrings.tr(AppStrings.save, lc)),
            ),
          ],
        );
      }),
    );
  }

  void _showWithdrawDialog(
      BuildContext context, WidgetRef ref, SavingsGoal goal, String lc) {
    final controller = TextEditingController();
    var addToWallet = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(AppStrings.tr(AppStrings.withdrawSpend, lc)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '${AppStrings.tr(AppStrings.balance, lc)} (₺)',
                    prefixText: '₺ ',
                    border: const OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: addToWallet,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => addToWallet = val ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => addToWallet = !addToWallet),
                      child: Text(
                        AppStrings.tr(AppStrings.addToWalletIncome, lc),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppStrings.tr(AppStrings.cancel, lc))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  if (amount > goal.currentAmount) {
                    messenger.showSnackBar(SnackBar(
                        content: Text(AppStrings.tr(
                            AppStrings.insufficientBalance, lc))));
                    return;
                  }

                  await ref
                      .read(savingsGoalProvider.notifier)
                      .updateGoalAmount(goal.id, goal.currentAmount - amount);

                  if (addToWallet) {
                    final transaction = WalletTransaction(
                      id: const Uuid().v4(),
                      categoryId: 'other_income',
                      amount: amount,
                      date: DateTime.now(),
                      type: TransactionType.income,
                      note:
                          '${goal.name} ${AppStrings.tr(AppStrings.savingsWithdrawNote, lc)}',
                    );
                    await ref
                        .read(walletProvider.notifier)
                        .addTransaction(transaction);
                  }

                  if (mounted) navigator.pop();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white),
              child: Text(AppStrings.tr(AppStrings.withdraw, lc)),
            ),
          ],
        );
      }),
    );
  }

  void _showEditGoalDialog(
      BuildContext context, WidgetRef ref, SavingsGoal goal, String lc) {
    final nameController = TextEditingController(text: goal.name);
    final targetController =
        TextEditingController(text: goal.targetAmount.toString());
    var selectedColor = goal.colorValue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppStrings.tr(AppStrings.editGoal, lc)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                        labelText: AppStrings.tr(AppStrings.goalName, lc),
                        border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: targetController,
                    decoration: InputDecoration(
                        labelText:
                            '${AppStrings.tr(AppStrings.goalTarget, lc)} (₺)',
                        border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(AppStrings.tr(AppStrings.selectColor, lc),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      0xFFFFA726, // Orange
                      0xFFEF5350, // Red
                      0xFF42A5F5, // Blue
                      0xFF66BB6A, // Green
                      0xFFAB47BC, // Purple
                      0xFF26C6DA, // Cyan
                    ].map((colorValue) {
                      final isSelected = selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = colorValue),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.textPrimary(context),
                                    width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppStrings.tr(AppStrings.cancel, lc))),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final target = double.tryParse(targetController.text) ?? 0;
                  if (name.isNotEmpty && target > 0) {
                    await ref
                        .read(savingsGoalProvider.notifier)
                        .updateGoalDetails(goal.id,
                            name: name,
                            targetAmount: target,
                            colorValue: selectedColor);
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: Text(AppStrings.tr(AppStrings.save, lc)),
              ),
            ],
          );
        },
      ),
    );
  }
}
