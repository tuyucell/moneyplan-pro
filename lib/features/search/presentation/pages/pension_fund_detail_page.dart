import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/favorites/providers/favorites_provider.dart';
import 'package:moneyplan_pro/features/search/data/models/pension_fund.dart';

class PensionFundDetailPage extends ConsumerWidget {
  final PensionFund fund;

  const PensionFundDetailPage({
    super.key,
    required this.fund,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isPensionFundFavoriteProvider(fund.id));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          'Fon Detayı',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.error : AppColors.textSecondary(context),
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).togglePensionFund(fund.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fund header
            _FundHeader(fund: fund),

            const SizedBox(height: 24),

            // Performance cards
            _PerformanceCards(fund: fund),

            const SizedBox(height: 24),

            // Performance chart
            _PerformanceChart(fund: fund),

            const SizedBox(height: 24),

            // Risk analysis
            _RiskAnalysis(fund: fund),

            const SizedBox(height: 24),

            // Fund info
            _FundInfo(fund: fund),
          ],
        ),
      ),
    );
  }
}

class _FundHeader extends StatelessWidget {
  final PensionFund fund;

  const _FundHeader({required this.fund});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: fund.type == 'interest'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fund.type == 'interest' ? 'Faizli' : 'Katılım',
                  style: TextStyle(
                    color: fund.type == 'interest' ? AppColors.primary : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fund.name,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.business,
                size: 16,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
              Text(
                fund.institution,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceCards extends StatelessWidget {
  final PensionFund fund;

  const _PerformanceCards({required this.fund});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performans',
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PerformanceCard(
                title: '1 Yıl',
                value: fund.returns1y,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                title: '3 Yıl',
                value: fund.returns3y,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerformanceCard(
                title: '5 Yıl',
                value: fund.returns5y,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final String title;
  final double value;

  const _PerformanceCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '%${value.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  final PensionFund fund;

  const _PerformanceChart({required this.fund});

  @override
  Widget build(BuildContext context) {
    final maxValue = [fund.returns1y, fund.returns3y, fund.returns5y].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Getiri Grafiği',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _ChartBar(
                    label: '1Y',
                    value: fund.returns1y,
                    maxValue: maxValue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ChartBar(
                    label: '3Y',
                    value: fund.returns3y,
                    maxValue: maxValue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ChartBar(
                    label: '5Y',
                    value: fund.returns5y,
                    maxValue: maxValue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;

  const _ChartBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final heightPercentage = (value / maxValue) * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '%${value.toStringAsFixed(1)}',
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: (heightPercentage / 100) * 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.success.withValues(alpha: 0.5),
                    AppColors.success,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RiskAnalysis extends StatelessWidget {
  final PensionFund fund;

  const _RiskAnalysis({required this.fund});

  Color _getRiskColor() {
    if (fund.riskLevel <= 2) return AppColors.success;
    if (fund.riskLevel <= 3) return const Color(0xFFFFA500);
    return AppColors.error;
  }

  String _getRiskText() {
    switch (fund.riskLevel) {
      case 1:
        return 'Çok Düşük Risk';
      case 2:
        return 'Düşük Risk';
      case 3:
        return 'Orta Risk';
      case 4:
        return 'Yüksek Risk';
      case 5:
        return 'Çok Yüksek Risk';
      default:
        return 'Orta Risk';
    }
  }

  String _getRiskDescription() {
    if (fund.riskLevel <= 2) {
      return 'Bu fon düşük riskli bir yatırım aracıdır. Daha istikrarlı getiriler sunar ve değer kaybı riski düşüktür.';
    } else if (fund.riskLevel <= 3) {
      return 'Bu fon orta düzeyde risk taşır. Dengeli bir portföy oluşturmak için uygundur.';
    } else {
      return 'Bu fon yüksek riskli bir yatırım aracıdır. Daha yüksek getiri potansiyeli sunabilir ancak değer kaybı riski de yüksektir.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Analizi',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: riskColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRiskText(),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Risk Seviyesi: ${fund.riskLevel}/5',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Risk level indicator
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: index < fund.riskLevel
                        ? riskColor
                        : AppColors.border(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            _getRiskDescription(),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundInfo extends StatelessWidget {
  final PensionFund fund;

  const _FundInfo({required this.fund});

  String _formatAssets(double assets) {
    if (assets >= 1000000000) {
      return '${(assets / 1000000000).toStringAsFixed(2)} Milyar ₺';
    } else if (assets >= 1000000) {
      return '${(assets / 1000000).toStringAsFixed(0)} Milyon ₺';
    }
    return '${assets.toStringAsFixed(0)} ₺';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fon Bilgileri',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.account_balance_wallet,
            label: 'Toplam Varlık',
            value: _formatAssets(fund.totalAssets),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.category,
            label: 'Fon Tipi',
            value: fund.type == 'interest' ? 'Faizli Fon' : 'Katılım Fonu',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.business,
            label: 'Kurum',
            value: fund.institution,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
