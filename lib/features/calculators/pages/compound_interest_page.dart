import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/utils/currency_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class CompoundInterestPage extends ConsumerStatefulWidget {
  const CompoundInterestPage({super.key});

  @override
  ConsumerState<CompoundInterestPage> createState() =>
      _CompoundInterestPageState();
}

class _CompoundInterestPageState extends ConsumerState<CompoundInterestPage> {
  final _initialAmountController = TextEditingController(text: '10000');
  final _monthlyContributionController = TextEditingController(text: '1000');
  final _interestRateController = TextEditingController(text: '10');
  final _yearsController = TextEditingController(text: '10');
  final _inflationController = TextEditingController(text: '0');
  final _contributionIncreaseController = TextEditingController(text: '0');

  double _totalValue = 0;
  double _totalContribution = 0;
  double _totalInterest = 0;
  List<FlSpot> _chartSpots = [];
  bool _calculated = false;
  bool _showAdvanced = false;
  double _realTotalValue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculate());
  }

  @override
  void dispose() {
    _initialAmountController.dispose();
    _monthlyContributionController.dispose();
    _interestRateController.dispose();
    _yearsController.dispose();
    _inflationController.dispose();
    _contributionIncreaseController.dispose();
    super.dispose();
  }

  void _calculate() {
    double parseRate(String text) =>
        double.tryParse(text.replaceAll(',', '.')) ?? 0;

    final principal = double.tryParse(_initialAmountController.text
            .replaceAll('.', '')
            .replaceAll(',', '')) ??
        0;
    var monthly = double.tryParse(_monthlyContributionController.text
            .replaceAll('.', '')
            .replaceAll(',', '')) ??
        0;
    final rate =
        double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 0;

    final inflation = parseRate(_inflationController.text);
    final contributionIncrease =
        parseRate(_contributionIncreaseController.text);

    if (years <= 0) return;

    var currentVal = principal;
    var totalContributed = principal;
    var spots = <FlSpot>[FlSpot(0, principal)];

    for (var i = 1; i <= years; i++) {
      for (var m = 0; m < 12; m++) {
        currentVal += monthly;
        totalContributed += monthly;
        currentVal *= (1 + (rate / 100) / 12);
      }
      spots.add(FlSpot(i.toDouble(), currentVal));

      if (contributionIncrease > 0) {
        monthly = monthly * (1 + contributionIncrease / 100);
      }
    }

    var realVal = currentVal / pow(1 + inflation / 100, years);

    setState(() {
      _totalValue = currentVal;
      _realTotalValue = realVal;
      _totalContribution = totalContributed;
      _totalInterest = currentVal - totalContributed;
      _chartSpots = spots;
      _calculated = true;
    });
  }

  String _currency = 'TL';

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    final currencySymbol =
        _currency == 'TL' ? '₺' : (_currency == 'USD' ? '\$' : '€');
    final currencyFormat = NumberFormat.currency(
        locale: 'tr_TR', symbol: currencySymbol, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.tr(AppStrings.investmentReturnsSim, lc),
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.textPrimary(context)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border(context), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: ['TL', 'USD', 'EUR'].map((curr) {
                  final isSelected = _currency == curr;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currency = curr;
                        });
                        _calculate();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            curr,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
                boxShadow: AppColors.shadowSm(context),
              ),
              child: Column(
                children: [
                  _buildInputField(context,
                      controller: _initialAmountController,
                      label: AppStrings.tr(AppStrings.initialInvestment, lc),
                      icon: Icons.account_balance_wallet,
                      isCurrency: true,
                      suffix: currencySymbol),
                  const SizedBox(height: 16),
                  _buildInputField(context,
                      controller: _monthlyContributionController,
                      label: AppStrings.tr(AppStrings.monthlyContribution, lc),
                      icon: Icons.savings,
                      isCurrency: true,
                      suffix: currencySymbol),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(context,
                            controller: _interestRateController,
                            label: AppStrings.tr(AppStrings.annualReturns, lc),
                            icon: Icons.trending_up,
                            isDecimal: true,
                            suffix: '%'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(context,
                            controller: _yearsController,
                            label: AppStrings.tr(AppStrings.durationYears, lc),
                            icon: Icons.timelapse,
                            suffix: AppStrings.tr(AppStrings.years, lc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _showAdvanced,
                        onExpansionChanged: (expanded) {
                          setState(() => _showAdvanced = expanded);
                        },
                        leading: const Icon(Icons.settings_outlined,
                            color: AppColors.primary, size: 22),
                        title: Text(
                          AppStrings.tr(AppStrings.advancedSettings, lc),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5),
                        ),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildInputField(context,
                              controller: _contributionIncreaseController,
                              label:
                                  AppStrings.tr(AppStrings.annualIncrease, lc),
                              icon: Icons.upgrade,
                              isDecimal: true,
                              suffix: '%',
                              infoText: AppStrings.tr(
                                  AppStrings.annualIncreaseInfo, lc)),
                          const SizedBox(height: 16),
                          _buildInputField(context,
                              controller: _inflationController,
                              label: AppStrings.tr(
                                  AppStrings.inflationExpectation, lc),
                              icon: Icons.money_off,
                              isDecimal: true,
                              suffix: '%',
                              infoText: AppStrings.tr(
                                  AppStrings.inflationExpectationInfo, lc)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(AppStrings.tr(AppStrings.calculate, lc),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            if (_calculated) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(context,
                        title: AppStrings.tr(AppStrings.totalPrincipal, lc),
                        value: currencyFormat.format(_totalContribution),
                        color: AppColors.textSecondary(context),
                        icon: Icons.input),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(context,
                        title: AppStrings.tr(AppStrings.interestReturns, lc),
                        value: currencyFormat.format(_totalInterest),
                        color: AppColors.success,
                        icon: Icons.show_chart),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]),
                child: Column(
                  children: [
                    Text(AppStrings.tr(AppStrings.totalNominalValue, lc),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(_totalValue),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    if (_showAdvanced &&
                        _realTotalValue > 0 &&
                        _realTotalValue != _totalValue) ...[
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  AppStrings.tr(
                                      AppStrings.realPurchasingPower, lc),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Text(currencyFormat.format(_realTotalValue),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                AppStrings.tr(AppStrings.inflationAdjusted, lc),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          )
                        ],
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(AppStrings.tr(AppStrings.growthChart, lc),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context))),
              const SizedBox(height: 16),
              Container(
                height: 300,
                padding: const EdgeInsets.only(
                    right: 16, top: 24, bottom: 0, left: 0),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: _chartSpots.length > 5
                          ? (_chartSpots.length / 5).floorToDouble()
                          : 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                          color:
                              AppColors.border(context).withValues(alpha: 0.5),
                          strokeWidth: 1),
                      getDrawingVerticalLine: (value) => FlLine(
                          color:
                              AppColors.border(context).withValues(alpha: 0.5),
                          strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          String text;
                          if (value >= 1000000) {
                            text = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            text = '${(value / 1000).toStringAsFixed(0)}K';
                          } else {
                            text = value.toInt().toString();
                          }
                          return Text(text,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.right);
                        },
                      )),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _chartSpots.length > 5
                              ? (_chartSpots.length / 5).floorToDouble()
                              : 1,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                  '${value.toInt()}. ${AppStrings.tr(AppStrings.years, lc)}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartSpots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primary.withValues(alpha: 0.0)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isCurrency = false,
    bool isDecimal = false,
    String? suffix,
    String? infoText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context)),
                  overflow: TextOverflow.ellipsis),
            ),
            if (infoText != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: infoText,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary(context)),
              ),
            ]
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    if (isCurrency) CurrencyInputFormatter(),
                    if (isDecimal)
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    if (!isCurrency && !isDecimal)
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixText: suffix,
                    suffixStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context,
      {required String title,
      required String value,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary(context))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
