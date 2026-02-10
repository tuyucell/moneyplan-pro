import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import '../../../../core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/providers/balance_visibility_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/bes_provider.dart';
import '../providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/watchlist/providers/asset_cache_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';

class WalletBalanceCard extends ConsumerWidget {
  final double remainingBalance;
  final double totalIncome;
  final double totalOutflow;
  final double totalPendingExpense;
  final bool isPositive;
  final NumberFormat currencyFormat;

  const WalletBalanceCard({
    super.key,
    required this.remainingBalance,
    required this.totalIncome,
    required this.totalOutflow,
    required this.totalPendingExpense,
    required this.isPositive,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final hasPendingExpense = totalPendingExpense > 0;

    return Container(
      padding: context.adaptivePadding, // Use adaptive padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppColors.primary : AppColors.error)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr(AppStrings.remainingBalance, lc),
                style: TextStyle(
                  fontSize: context.adaptiveSp(16),
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // ... info icon container (keep somewhat fixed or slightly adaptive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.tr(AppStrings.netStatus, lc),
                      style: TextStyle(
                        fontSize: context.adaptiveSp(11),
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat
                    .format(remainingBalance.abs())
                    .mask(ref.watch(balanceVisibilityProvider)),
                style: TextStyle(
                  fontSize: context.adaptiveSp(36),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (remainingBalance < 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    '(${AppStrings.tr(AppStrings.deficit, lc)})',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: context.adaptiveSp(14),
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr(AppStrings.monthSummary, lc),
                      style: TextStyle(
                        fontSize: context.adaptiveSp(12),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MiniSummaryItem(
                          label: '${AppStrings.tr(AppStrings.income, lc)}:',
                          amount: currencyFormat
                              .format(totalIncome)
                              .mask(ref.watch(balanceVisibilityProvider)),
                          textColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        _MiniSummaryItem(
                          label: '${AppStrings.tr(AppStrings.expense, lc)}:',
                          amount: currencyFormat
                              .format(totalOutflow)
                              .mask(ref.watch(balanceVisibilityProvider)),
                          textColor: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasPendingExpense)
                Column(
                  children: [
                    Text(
                      currencyFormat.format(totalPendingExpense),
                      style: TextStyle(
                        fontSize: context.adaptiveSp(13),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.tr(AppStrings.unpaid, lc),
                      style: TextStyle(
                        fontSize: context.adaptiveSp(9),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          _buildNetWorthSection(context, ref, lc),
        ],
      ),
    );
  }

  Widget _buildNetWorthSection(BuildContext context, WidgetRef ref, String lc) {
    final portfolioAssets = ref.watch(portfolioProvider);
    final besAccount = ref.watch(besProvider);
    final savingsGoals = ref.watch(savingsGoalProvider);

    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(financeDisplayCurrencyProvider);

    double investmentsValueTRY = 0;
    for (final asset in portfolioAssets) {
      final marketAsset = ref.watch(assetProvider(asset.id)).asData?.value;
      if (marketAsset?.currentPriceUsd != null) {
        // Market price is in USD
        final valueUSD = marketAsset!.currentPriceUsd! * asset.units;
        investmentsValueTRY += currencyService.convertToTRY(valueUSD, 'USD');
      }
    }

    if (besAccount != null) {
      investmentsValueTRY += besAccount.getTotalValue();
    }

    for (final goal in savingsGoals) {
      investmentsValueTRY +=
          currencyService.convertToTRY(goal.currentAmount, goal.currencyCode);
    }

    final investmentsValueDisplay =
        currencyService.convertFromTRY(investmentsValueTRY, displayCurrency);
    final netWorth = remainingBalance + investmentsValueDisplay;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NET VARLIK (HEPSİ)',
              style: TextStyle(
                fontSize: context.adaptiveSp(11),
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat
                  .format(netWorth)
                  .mask(ref.watch(balanceVisibilityProvider)),
              style: TextStyle(
                fontSize: context.adaptiveSp(20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Yatırımlar',
                style: TextStyle(
                    color: Colors.white70, fontSize: context.adaptiveSp(10)),
              ),
              Text(
                currencyFormat
                    .format(investmentsValueDisplay)
                    .mask(ref.watch(balanceVisibilityProvider)),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniSummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color textColor;

  const _MiniSummaryItem({
    required this.label,
    required this.amount,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
