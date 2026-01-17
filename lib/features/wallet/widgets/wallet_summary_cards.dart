import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import '../../../../core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/providers/balance_visibility_provider.dart';

class WalletSummaryCards extends ConsumerWidget {
  final Map<String, double> incomeByCurrency;
  final Map<String, double> expenseByCurrency;
  final NumberFormat currencyFormat;

  const WalletSummaryCards({
    super.key,
    required this.incomeByCurrency,
    required this.expenseByCurrency,
    required this.currencyFormat,
  });

  String _formatAmount(String code, double amount) {
    if (code == 'TRY') {
      return NumberFormat.currency(
              locale: 'tr_TR', symbol: '₺', decimalDigits: 0)
          .format(amount);
    } else if (code == 'USD') {
      return NumberFormat.currency(
              locale: 'en_US', symbol: '\$', decimalDigits: 0)
          .format(amount);
    } else if (code == 'EUR') {
      return NumberFormat.currency(
              locale: 'de_DE', symbol: '€', decimalDigits: 0)
          .format(amount);
    }
    return NumberFormat.currency(
            locale: 'tr_TR', symbol: '$code ', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final isMasked = !ref.watch(balanceVisibilityProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            title: AppStrings.tr(AppStrings.totalIncome, lc),
            amounts: incomeByCurrency.entries
                .map((e) => _formatAmount(e.key, e.value).mask(!isMasked))
                .toList(),
            color: AppColors.success,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: AppStrings.tr(AppStrings.totalExpense, lc),
            amounts: expenseByCurrency.entries
                .map((e) => _formatAmount(e.key, e.value).mask(!isMasked))
                .toList(),
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
  final List<String> amounts;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amounts,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (amounts.isEmpty ? ['₺0'] : amounts)
                .map((amt) => Text(
                      amt,
                      style: TextStyle(
                        fontSize: context.adaptiveSp(16),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
