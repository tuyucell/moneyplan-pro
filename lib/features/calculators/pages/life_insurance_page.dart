import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/search/presentation/pages/insurance_product_detail_page.dart';
import 'package:invest_guide/features/search/providers/insurance_provider.dart';
import 'package:invest_guide/features/search/data/models/insurance_product.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class LifeInsurancePage extends ConsumerStatefulWidget {
  const LifeInsurancePage({super.key});

  @override
  ConsumerState<LifeInsurancePage> createState() => _LifeInsurancePageState();
}

class _LifeInsurancePageState extends ConsumerState<LifeInsurancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _age = 30;
  double _coverage = 500000;
  int _term = 20;
  bool _isSmoker = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          AppStrings.tr(AppStrings.lifeInsuranceTitle, lc),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: AppStrings.tr(AppStrings.savingsInsuranceTitleShort, lc)),
            Tab(text: AppStrings.tr(AppStrings.termInsuranceTitleShort, lc)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _SavingsInsuranceTab(),
          _TermInsuranceTab(
            age: _age,
            coverage: _coverage,
            term: _term,
            isSmoker: _isSmoker,
            onAgeChanged: (value) => setState(() => _age = value.toInt()),
            onCoverageChanged: (value) => setState(() => _coverage = value),
            onTermChanged: (value) => setState(() => _term = value.toInt()),
            onSmokerChanged: (value) => setState(() => _isSmoker = value),
          ),
        ],
      ),
    );
  }
}

class _SavingsInsuranceTab extends ConsumerWidget {
  const _SavingsInsuranceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(savingsProductsProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return productsAsync.when(
      data: (response) {
        final products = response.data ?? [];
        final showBanner = response.status.toString().contains('fallback');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (showBanner) ...[
              _MockDataBanner(lc: lc),
              const SizedBox(height: 16),
            ],
            _InfoBanner(
              title: AppStrings.tr(AppStrings.savingsInsuranceTitle, lc),
              description: AppStrings.tr(AppStrings.savingsInsuranceDesc, lc),
              icon: Icons.savings,
              color: AppColors.success,
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: AppStrings.tr(AppStrings.advantages, lc)),
            const SizedBox(height: 12),
            _BenefitCard(
              icon: Icons.trending_up,
              title: AppStrings.tr(AppStrings.investmentReturn, lc),
              description: AppStrings.tr(AppStrings.investmentReturnDesc, lc),
            ),
            const SizedBox(height: 12),
            _BenefitCard(
              icon: Icons.security,
              title: AppStrings.tr(AppStrings.lifeSecurity, lc),
              description: AppStrings.tr(AppStrings.lifeSecurityDesc, lc),
            ),
            const SizedBox(height: 12),
            _BenefitCard(
              icon: Icons.account_balance_wallet,
              title: AppStrings.tr(AppStrings.accumulation, lc),
              description: AppStrings.tr(AppStrings.accumulationDesc, lc),
            ),
            const SizedBox(height: 12),
            _BenefitCard(
              icon: Icons.receipt_long,
              title: AppStrings.tr(AppStrings.taxAdvantageLabel, lc),
              description: AppStrings.tr(AppStrings.taxAdvantageDesc, lc),
            ),
            const SizedBox(height: 24),
            _TaxCalculatorCard(),
            const SizedBox(height: 24),
            _SectionTitle(title: AppStrings.tr(AppStrings.products, lc)),
            const SizedBox(height: 12),
            ...products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsuranceProductCard(product: product),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(AppStrings.tr(AppStrings.dataLoadError, lc),
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(savingsProductsProvider),
              child: Text(AppStrings.tr(AppStrings.retry, lc)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermInsuranceTab extends ConsumerWidget {
  final int age;
  final double coverage;
  final int term;
  final bool isSmoker;
  final Function(double) onAgeChanged;
  final Function(double) onCoverageChanged;
  final Function(double) onTermChanged;
  final Function(bool) onSmokerChanged;

  const _TermInsuranceTab({
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
    final monthlyPremium = _calculatePremium();
    final productsAsync = ref.watch(termProductsProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return productsAsync.when(
      data: (response) {
        final products = response.data ?? [];
        final showBanner = response.status.toString().contains('fallback');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (showBanner) ...[
              _MockDataBanner(lc: lc),
              const SizedBox(height: 16),
            ],
            _InfoBanner(
              title: AppStrings.tr(AppStrings.termInsuranceTitle, lc),
              description: AppStrings.tr(AppStrings.termInsuranceDesc, lc),
              icon: Icons.shield,
              color: AppColors.info,
            ),
            const SizedBox(height: 20),
            Container(
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calculate,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.tr(AppStrings.premiumCalculator, lc),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SliderInput(
                    label: AppStrings.tr(AppStrings.yourAge, lc),
                    value: age.toDouble(),
                    min: 18,
                    max: 70,
                    divisions: 52,
                    onChanged: onAgeChanged,
                    displayValue:
                        '$age ${AppStrings.tr(AppStrings.ageSuffix, lc)}',
                  ),
                  const SizedBox(height: 20),
                  _SliderInput(
                    label: AppStrings.tr(AppStrings.coverageAmount, lc),
                    value: coverage,
                    min: 100000,
                    max: 5000000,
                    divisions: 49,
                    onChanged: onCoverageChanged,
                    displayValue:
                        '${_formatCurrency(coverage, lc)} ${lc == 'tr' ? '₺' : '\$'}',
                  ),
                  const SizedBox(height: 20),
                  _SliderInput(
                    label: AppStrings.tr(AppStrings.analysisDuration, lc),
                    value: term.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 25,
                    onChanged: onTermChanged,
                    displayValue:
                        '$term ${AppStrings.tr(AppStrings.years, lc).toLowerCase()}',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.tr(AppStrings.smokerQuestion, lc),
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: isSmoker,
                        onChanged: onSmokerChanged,
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.tr(AppStrings.monthlyPremiumEstimator, lc),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(monthlyPremium, lc)} ${lc == 'tr' ? '₺' : '\$'}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.tr(AppStrings.annualTotal, lc)}: ${_formatCurrency(monthlyPremium * 12, lc)} ${lc == 'tr' ? '₺' : '\$'}',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: AppStrings.tr(AppStrings.products, lc)),
            const SizedBox(height: 12),
            ...products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsuranceProductCard(product: product),
                )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(AppStrings.tr(AppStrings.dataLoadError, lc),
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(termProductsProvider),
              child: Text(AppStrings.tr(AppStrings.retry, lc)),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePremium() {
    var basePremium = (coverage / 1000) * 0.8;

    var ageFactor = 1.0;
    if (age < 30) {
      ageFactor = 0.7;
    } else if (age < 40) {
      ageFactor = 1.0;
    } else if (age < 50) {
      ageFactor = 1.5;
    } else if (age < 60) {
      ageFactor = 2.2;
    } else {
      ageFactor = 3.5;
    }

    var termFactor = 1.0 + (term / 100);
    var smokerFactor = isSmoker ? 1.8 : 1.0;

    return basePremium * ageFactor * termFactor * smokerFactor;
  }

  String _formatCurrency(double amount, String lc) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _MockDataBanner extends StatelessWidget {
  final String lc;
  const _MockDataBanner({required this.lc});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA500).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFFA500).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFFFFA500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.tr(AppStrings.demoDataShowing, lc),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _InfoBanner({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
    );
  }
}

class _SliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onChanged;
  final String displayValue;

  const _SliderInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.displayValue,
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
              displayValue,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _InsuranceProductCard extends StatelessWidget {
  final InsuranceProduct product;

  const _InsuranceProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    InsuranceProductDetailPage(product: product),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.company,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.expectedReturn != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '~%${product.expectedReturn!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...product.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaxCalculatorCard extends StatefulWidget {
  @override
  State<_TaxCalculatorCard> createState() => _TaxCalculatorCardState();
}

class _TaxCalculatorCardState extends State<_TaxCalculatorCard> {
  double _monthlyPremium = 2000;

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final lc = ref.watch(languageProvider).code;
      final taxSaving = _monthlyPremium * 0.15;

      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            collapsedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            leading: const Icon(Icons.calculate_outlined,
                color: AppColors.primary, size: 22),
            title: Text(
              lc == 'tr' ? 'Vergi Avantajı Hesapla' : 'Calculate Tax Advantage',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 0.5),
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              const Divider(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  lc == 'tr' ? 'Aylık Ödemeniz' : 'Your Monthly Payment',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                  thumbColor: AppColors.primary,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _monthlyPremium,
                  min: 500,
                  max: 10000,
                  divisions: 19,
                  onChanged: (value) => setState(() => _monthlyPremium = value),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('500 ${lc == 'tr' ? '₺' : '\$'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context))),
                  Text(
                    '${_monthlyPremium.toInt()} ${lc == 'tr' ? '₺' : '\$'}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  Text('10.000 ${lc == 'tr' ? '₺' : '\$'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lc == 'tr'
                          ? 'Aylık Vergi İadesi:'
                          : 'Monthly Tax Refund:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${taxSaving.toInt()} ${lc == 'tr' ? '₺' : '\$'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lc == 'tr'
                    ? '*Ödediğiniz primin %15\'ini gelir vergisi matrahınızdan düşebilirsiniz.'
                    : '*You can deduct 15% of your premium from your income tax base.',
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }
}
