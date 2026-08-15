import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/balance_visibility_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/core/utils/responsive.dart';
import 'package:moneyplan_pro/features/wallet/models/limit_usage_summary.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/services/installment_schedule_service.dart';

class LimitUsageCard extends ConsumerWidget {
  final NumberFormat currencyFormat;
  final String displayCurrency;

  const LimitUsageCard({
    super.key,
    required this.currencyFormat,
    required this.displayCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(bankAccountProvider);
    final accountStats = ref.watch(accountStatsProvider);
    final transactions = ref.watch(walletProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);

    final balancesInTry = <String, double>{};
    final pendingInstallmentsInTry = <String, double>{};
    for (final account in accounts) {
      final balances = accountStats[account.id]?.balances ??
          <String, double>{account.currencyCode: account.initialBalance};
      balancesInTry[account.id] = balances.entries.fold<double>(
        0,
        (total, entry) =>
            total + currencyService.convertToTRY(entry.value, entry.key),
      );

      if (account.accountType == 'Kredi Kartı') {
        pendingInstallmentsInTry[account.id] = currencyService.convertToTRY(
          InstallmentScheduleService.pendingTotal(
            account: account,
            transactions: transactions,
          ),
          account.currencyCode,
        );
      }
    }

    final summary = LimitUsageSummary.fromAccounts(
      accounts: accounts,
      balancesInBaseCurrency: balancesInTry,
      pendingInstallmentsInBaseCurrency: pendingInstallmentsInTry,
      convertToBaseCurrency: currencyService.convertToTRY,
    );
    if (!summary.hasData) return const SizedBox.shrink();

    String money(double amount) => currencyFormat
        .format(currencyService.convertFromTRY(amount, displayCurrency))
        .mask(isVisible);

    final total = summary.total;
    final percentage = total.limit <= 0
        ? (total.used > 0 ? 100.0 : 0.0)
        : total.utilizationRate * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.donut_large,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LİMİT KULLANIMI',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: context.adaptiveSp(13),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Borçlanma limitleri nakit bakiyeye dahil değildir.',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: context.adaptiveSp(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        centerSpaceRadius: 38,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                        sections: _chartSections(total),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: total.isOverLimit
                                ? AppColors.error
                                : AppColors.textPrimary(context),
                            fontSize: context.adaptiveSp(19),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'kullanım',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: context.adaptiveSp(9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _totalLine(context, 'Toplam limit', money(total.limit)),
                    const SizedBox(height: 9),
                    _totalLine(
                      context,
                      'Toplam kullanılan',
                      money(total.used),
                      valueColor: total.used > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    const SizedBox(height: 9),
                    _totalLine(
                      context,
                      'Toplam kalan',
                      money(total.remaining),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _usageRow(
            context,
            title: 'Kredi kartları',
            icon: Icons.credit_card,
            color: AppColors.primary,
            bucket: summary.creditCards,
            money: money,
            isVisible: isVisible,
          ),
          const SizedBox(height: 12),
          _usageRow(
            context,
            title: 'KMH / eksi hesap',
            icon: Icons.account_balance,
            color: AppColors.warning,
            bucket: summary.overdrafts,
            money: money,
            isVisible: isVisible,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _chartSections(LimitUsageBucket total) {
    if (total.limit <= 0 && total.used <= 0) return const [];
    final usedForChart = total.limit > 0
        ? total.used.clamp(0, total.limit).toDouble()
        : total.used;
    final remainingForChart = total.limit > 0 ? total.remaining : 0.0;
    return [
      PieChartSectionData(
        value: usedForChart > 0 ? usedForChart : 0.0001,
        color: total.isOverLimit ? AppColors.error : AppColors.warning,
        radius: 13,
        showTitle: false,
      ),
      if (remainingForChart > 0)
        PieChartSectionData(
          value: remainingForChart,
          color: AppColors.grey200,
          radius: 13,
          showTitle: false,
        ),
    ];
  }

  Widget _totalLine(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: context.adaptiveSp(10),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary(context),
            fontSize: context.adaptiveSp(12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _usageRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required LimitUsageBucket bucket,
    required String Function(double amount) money,
    required bool isVisible,
  }) {
    final percent = bucket.limit <= 0
        ? (bucket.used > 0 ? 100.0 : 0.0)
        : bucket.utilizationRate * 100;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: context.adaptiveSp(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                isVisible ? '${percent.toStringAsFixed(0)}%' : '•••',
                style: TextStyle(
                  color: bucket.isOverLimit ? AppColors.error : color,
                  fontSize: context.adaptiveSp(11),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: bucket.utilizationRate.clamp(0, 1).toDouble(),
              minHeight: 5,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                bucket.isOverLimit ? AppColors.error : color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniMetric(context, 'Limit', money(bucket.limit)),
              ),
              Expanded(
                child: _miniMetric(
                  context,
                  'Kullanılan',
                  money(bucket.used),
                  alignEnd: true,
                ),
              ),
              Expanded(
                child: _miniMetric(
                  context,
                  'Kalan',
                  money(bucket.remaining),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    BuildContext context,
    String label,
    String value, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: context.adaptiveSp(8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: context.adaptiveSp(10),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
