import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';

class WalletChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final NumberFormat currencyFormat;

  const WalletChart({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (totalIncome == 0 && totalExpense == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Görsel Özet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: totalIncome > 0 ? totalIncome.toInt() : 1,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(8),
                      right: Radius.circular(0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      totalIncome > 0 ? currencyFormat.format(totalIncome) : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: totalExpense > 0 ? totalExpense.toInt() : 1,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(0),
                      right: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      totalExpense > 0 ? currencyFormat.format(totalExpense) : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(label: 'Gelir', color: AppColors.success),
              _LegendItem(label: 'Gider', color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
