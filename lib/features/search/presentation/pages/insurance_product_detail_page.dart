import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/favorites/providers/favorites_provider.dart';
import 'package:moneyplan_pro/features/search/data/models/insurance_product.dart';
import 'package:moneyplan_pro/services/api/life_insurance_service.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class InsuranceProductDetailPage extends ConsumerStatefulWidget {
  final InsuranceProduct product;

  const InsuranceProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<InsuranceProductDetailPage> createState() =>
      _InsuranceProductDetailPageState();
}

class _InsuranceProductDetailPageState
    extends ConsumerState<InsuranceProductDetailPage> {
  int _age = 30;
  double _coverage = 500000;
  int _term = 20;
  bool _isSmoker = false;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    
    final productId = widget.product.name.hashCode.toString();
    final isFavorite = ref.watch(isInsuranceProductFavoriteProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          AppStrings.tr(AppStrings.productDetail, lc),
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
              color:
                  isFavorite ? AppColors.error : AppColors.textSecondary(context),
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleInsuranceProduct(productId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(product: widget.product),
            const SizedBox(height: 24),
            if (widget.product.type == 'savings') ...[
              _ExpectedReturnCard(product: widget.product),
              const SizedBox(height: 24),
            ],
            _FeaturesSection(product: widget.product),
            const SizedBox(height: 24),
            _AgeTermInfo(product: widget.product),
            const SizedBox(height: 24),
            if (widget.product.type == 'term') ...[
              _PremiumCalculator(
                age: _age,
                coverage: _coverage,
                term: _term,
                isSmoker: _isSmoker,
                onAgeChanged: (value) => setState(() => _age = value.round()),
                onCoverageChanged: (value) =>
                    setState(() => _coverage = value),
                onTermChanged: (value) => setState(() => _term = value.round()),
                onSmokerChanged: (value) =>
                    setState(() => _isSmoker = value ?? false),
              ),
              const SizedBox(height: 24),
            ],
            _CompanyInfo(product: widget.product),
            const SizedBox(height: 24),
            _ApplyButton(product: widget.product),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends ConsumerWidget {
  final InsuranceProduct product;

  const _ProductHeader({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

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
                  color: product.type == 'savings'
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.type == 'savings' ? AppStrings.tr(AppStrings.savings, lc) : AppStrings.tr(AppStrings.risk, lc),
                  style: TextStyle(
                    color: product.type == 'savings'
                        ? AppColors.success
                        : AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.name,
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
                product.company,
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

class _ExpectedReturnCard extends ConsumerWidget {
  final InsuranceProduct product;

  const _ExpectedReturnCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr(AppStrings.expectedReturn, lc),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '%${product.expectedReturn?.toStringAsFixed(1) ?? '0.0'}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tr(AppStrings.yearlyAverage, lc),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
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

class _FeaturesSection extends ConsumerWidget {
  final InsuranceProduct product;

  const _FeaturesSection({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

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
            AppStrings.tr(AppStrings.features, lc),
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...product.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AgeTermInfo extends ConsumerWidget {
  final InsuranceProduct product;

  const _AgeTermInfo({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

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
            AppStrings.tr(AppStrings.conditions, lc),
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today,
                  label: AppStrings.tr(AppStrings.ageRange, lc),
                  value: '${product.minAge} - ${product.maxAge}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer,
                  label: AppStrings.tr(AppStrings.term, lc),
                  value: '${product.minTerm} - ${product.maxTerm} ${AppStrings.tr(AppStrings.years, lc)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PremiumCalculator extends ConsumerWidget {
  final int age;
  final double coverage;
  final int term;
  final bool isSmoker;
  final Function(double) onAgeChanged;
  final Function(double) onCoverageChanged;
  final Function(double) onTermChanged;
  final Function(bool?) onSmokerChanged;

  const _PremiumCalculator({
    required this.age,
    required this.coverage,
    required this.term,
    required this.isSmoker,
    required this.onAgeChanged,
    required this.onCoverageChanged,
    required this.onTermChanged,
    required this.onSmokerChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    final monthlyPremium = LifeInsuranceService.calculatePremium(
      age: age,
      coverage: coverage,
      term: term,
      isSmoker: isSmoker,
    );

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
            AppStrings.tr(AppStrings.premiumCalculation, lc),
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _SliderItem(
            label: AppStrings.tr(AppStrings.age, lc),
            value: age.toDouble(),
            min: 18,
            max: 70,
            divisions: 52,
            valueLabel: '$age',
            onChanged: onAgeChanged,
          ),
          const SizedBox(height: 16),
          _SliderItem(
            label: AppStrings.tr(AppStrings.coverageAmount, lc),
            value: coverage,
            min: 100000,
            max: 2000000,
            divisions: 19,
            valueLabel: '${(coverage / 1000).toStringAsFixed(0)}K ₺',
            onChanged: onCoverageChanged,
          ),
          const SizedBox(height: 16),
          _SliderItem(
            label: AppStrings.tr(AppStrings.term, lc),
            value: term.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            valueLabel: '$term ${AppStrings.tr(AppStrings.years, lc)}',
            onChanged: onTermChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                AppStrings.tr(AppStrings.smokerStatus, lc),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Checkbox(
                value: isSmoker,
                onChanged: onSmokerChanged,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr(AppStrings.estimatedMonthlyPremium, lc),
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${monthlyPremium.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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

class _SliderItem extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final Function(double) onChanged;

  const _SliderItem({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border(context),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CompanyInfo extends ConsumerWidget {
  final InsuranceProduct product;

  const _CompanyInfo({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business,
              color: AppColors.info,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr(AppStrings.insuranceCompany, lc),
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.company,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

class _ApplyButton extends ConsumerWidget {
  final InsuranceProduct product;

  const _ApplyButton({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final language = ref.watch(languageProvider);
    final lc = language.code;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} ${AppStrings.tr(AppStrings.applySoon, lc)}'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          AppStrings.tr(AppStrings.apply, lc),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
