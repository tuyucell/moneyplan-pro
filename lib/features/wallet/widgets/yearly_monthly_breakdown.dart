import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import '../models/yearly_summary.dart';

class YearlyMonthlyBreakdown extends ConsumerWidget {
  final YearlySummary summary;
  final NumberFormat currencyFormat;
  final Function(int) onMonthTap;

  const YearlyMonthlyBreakdown({
    super.key,
    required this.summary,
    required this.currencyFormat,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final monthSummary = summary.monthlySummaries[index];
        final monthName = AppStrings.getMonthName(index + 1, lc);
        final isCompleted = DateTime.now().year > summary.year || 
                           (DateTime.now().year == summary.year && DateTime.now().month > index + 1);
        final isCurrent = DateTime.now().year == summary.year && DateTime.now().month == index + 1;

        String statusLabel;
        if (isCurrent) {
          statusLabel = AppStrings.tr(AppStrings.currentMonthLabel, lc);
        } else if (isCompleted) {
          statusLabel = AppStrings.tr(AppStrings.completed, lc);
        } else {
          statusLabel = AppStrings.tr(AppStrings.upcoming, lc);
        }

        return Container(
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border(context),
            ),
          ),
          child: InkWell(
            onTap: () => onMonthTap(index + 1),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? AppColors.primary : AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MiniText(
                              text: '${AppStrings.tr(AppStrings.incomeAbbr, lc)}: ${currencyFormat.format(monthSummary.totalIncome)}', 
                              color: AppColors.success
                            ),
                            const SizedBox(width: 12),
                            _MiniText(
                              text: '${AppStrings.tr(AppStrings.expenseAbbr, lc)}: ${currencyFormat.format(monthSummary.totalOutflow)}', 
                              color: AppColors.error
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(monthSummary.remainingBalance),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: monthSummary.isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: AppColors.textTertiary(context), size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniText extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
