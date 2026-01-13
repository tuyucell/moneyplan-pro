import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import '../../../../core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/providers/balance_visibility_provider.dart';

class WalletSummaryCards extends ConsumerWidget {
  final double totalIncome;
  final double totalExpense;
  final NumberFormat currencyFormat;

  const WalletSummaryCards({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: AppStrings.tr(AppStrings.totalIncome, lc),
            amount: currencyFormat.format(totalIncome).mask(ref.watch(balanceVisibilityProvider)),
            color: AppColors.success,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: AppStrings.tr(AppStrings.totalExpense, lc),
            amount: currencyFormat.format(totalExpense).mask(ref.watch(balanceVisibilityProvider)),
            color: AppColors.error,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: context.adaptiveSp(13),
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: context.adaptiveSp(18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
