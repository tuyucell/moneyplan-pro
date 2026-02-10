import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import '../../../../core/constants/colors.dart';
import '../models/transaction_category.dart';
import '../providers/budget_provider.dart';

class WalletCategoryBreakdown extends ConsumerWidget {
  final Map<String, double> categoryAmounts;
  final double total;
  final TransactionType type;
  final NumberFormat currencyFormat;
  final DateTime selectedDate;
  final Function(String, String, TransactionType) onCategoryTap;

  const WalletCategoryBreakdown({
    super.key,
    required this.categoryAmounts,
    required this.total,
    required this.type,
    required this.currencyFormat,
    required this.selectedDate,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (total == 0 || categoryAmounts.isEmpty) return const SizedBox.shrink();

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final category = TransactionCategory.findById(categoryEntry.key);
          final percentage = (categoryEntry.value / total * 100);
          final isLast = index == sortedEntries.length - 1;

          final budgetLimit = type == TransactionType.expense 
              ? ref.watch(categoryBudgetProvider((
                  categoryId: categoryEntry.key, 
                  year: selectedDate.year, 
                  month: selectedDate.month
                )))
              : null;
          
          final budgetUsage = budgetLimit != null 
              ? (categoryEntry.value / budgetLimit.limit).clamp(0.0, 1.0)
              : null;
          final isOverBudget = budgetLimit != null && categoryEntry.value > budgetLimit.limit;

          return InkWell(
            onTap: () => onCategoryTap(
              categoryEntry.key, 
              category?.name ?? 'Bilinmeyen', 
              type
            ),
            borderRadius: BorderRadius.circular(isLast ? 16 : 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(
                  bottom: BorderSide(color: AppColors.grey200),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category?.name ?? 'Bilinmeyen',
                          style: TextStyle(
                            fontSize: context.adaptiveSp(15),
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey900,
                          ),
                        ),
                      ),
                      Text(
                        currencyFormat.format(categoryEntry.value),
                        style: TextStyle(
                          fontSize: context.adaptiveSp(15),
                          fontWeight: FontWeight.bold,
                          color: type == TransactionType.income
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.grey400, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: AppColors.grey200,
                                valueColor: AlwaysStoppedAnimation(
                                  type == TransactionType.income
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            if (budgetUsage != null) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: budgetUsage,
                                  backgroundColor: AppColors.grey200,
                                  valueColor: AlwaysStoppedAnimation(
                                    isOverBudget ? AppColors.error : AppColors.primary,
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: context.adaptiveSp(13),
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (budgetLimit != null)
                            Text(
                              'Hedef: ${currencyFormat.format(budgetLimit.limit)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOverBudget ? AppColors.error : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
