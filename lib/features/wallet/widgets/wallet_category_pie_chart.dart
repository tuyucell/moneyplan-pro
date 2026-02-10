import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import '../models/transaction_category.dart';
import '../providers/budget_provider.dart';

class WalletCategoryPieChart extends ConsumerStatefulWidget {
  final Map<String, double> categoryAmounts;
  final double total;
  final TransactionType type;
  final NumberFormat currencyFormat;
  final DateTime selectedDate;
  final Function(String, String, TransactionType) onCategoryTap;

  const WalletCategoryPieChart({
    super.key,
    required this.categoryAmounts,
    required this.total,
    required this.type,
    required this.currencyFormat,
    required this.selectedDate,
    required this.onCategoryTap,
  });

  @override
  ConsumerState<WalletCategoryPieChart> createState() =>
      _WalletCategoryPieChartState();
}

class _WalletCategoryPieChartState
    extends ConsumerState<WalletCategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.total == 0 || widget.categoryAmounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = widget.categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 categories for the chart + "Other"
    final chartEntries = sortedEntries.take(5).toList();
    final otherEntries = sortedEntries.skip(5).toList();
    if (otherEntries.isNotEmpty) {
      final otherTotal =
          otherEntries.fold(0.0, (sum, entry) => sum + entry.value);
      chartEntries.add(MapEntry('other', otherTotal));
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _showingSections(chartEntries),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Detailed List Below Chart
        ...sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final category = TransactionCategory.findById(categoryEntry.key);
          final percentage = (categoryEntry.value / widget.total * 100);
          final isLast = index == sortedEntries.length - 1;

          final budgetLimit = widget.type == TransactionType.expense
              ? ref.watch(categoryBudgetProvider((
                  categoryId: categoryEntry.key,
                  year: widget.selectedDate.year,
                  month: widget.selectedDate.month
                )))
              : null;

          final isOverBudget =
              budgetLimit != null && categoryEntry.value > budgetLimit.limit;

          return InkWell(
            onTap: () => widget.onCategoryTap(
              categoryEntry.key,
              category?.name ?? 'Bilinmeyen',
              widget.type,
            ),
            borderRadius: BorderRadius.circular(isLast ? 16 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.grey200),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColor(index),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category?.name ??
                          (categoryEntry.key == 'other'
                              ? 'Diğer'
                              : 'Bilinmeyen'),
                      style: TextStyle(
                        fontSize: context.adaptiveSp(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.currencyFormat.format(categoryEntry.value),
                        style: TextStyle(
                          fontSize: context.adaptiveSp(15),
                          fontWeight: FontWeight.bold,
                          color: isOverBudget
                              ? AppColors.error
                              : (widget.type == TransactionType.income
                                  ? AppColors.success
                                  : AppColors.textPrimary(context)),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: context.adaptiveSp(12),
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right,
                      color: AppColors.grey400, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<PieChartSectionData> _showingSections(
      List<MapEntry<String, double>> entries) {
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final entry = entries[i];
      final percentage = (entry.value / widget.total * 100);
      final category = TransactionCategory.findById(entry.key);

      return PieChartSectionData(
        color: _getColor(i),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
        badgeWidget: _Badge(
          _getCategoryIcon(category?.id),
          size: 30,
          borderColor: _getColor(i),
        ),
        badgePositionPercentageOffset: 1.3,
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF0293ee),
      Color(0xFFf8b250),
      Color(0xFF845bef),
      Color(0xFF13d38e),
      Color(0xFFd9534f),
      Color(0xFF5bc0de),
      Color(0xFFe91e63),
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String? categoryId) {
    switch (categoryId) {
      case 'salary':
        return Icons.attach_money;
      case 'freelance':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      case 'rental':
        return Icons.home_work;
      case 'food_market':
      case 'food_grocery':
      case 'food_restaurant':
        return Icons.restaurant;
      case 'transportation':
      case 'transportation_fuel':
        return Icons.directions_car;
      case 'bills':
      case 'bills_electric':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'rent':
        return Icons.home;
      default:
        return Icons.category;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
  });

  final IconData icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOrdinal(0.2),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(icon, size: size * 0.6, color: borderColor),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withOrdinal(double opacity) {
    return withValues(alpha: opacity);
  }
}
