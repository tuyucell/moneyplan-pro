import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'dart:math';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class ScenarioPlannerPage extends ConsumerStatefulWidget {
  const ScenarioPlannerPage({super.key});

  @override
  ConsumerState<ScenarioPlannerPage> createState() =>
      _ScenarioPlannerPageState();
}

class _ScenarioPlannerPageState extends ConsumerState<ScenarioPlannerPage> {
  // Scenario Parameters
  double _monthlyContribution = 5000;
  double _annualReturn = 10.0; // Nominal return
  double _inflation = 20.0; // High inflation context (TR)
  int _years = 10;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    final transactions = ref.watch(walletProvider);

    // Calculate total accumulated savings (Expenses marked as isSaving)
    final currentBalance = transactions
        .where((t) => t.category?.isSaving == true)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.scenarioPlannerTitle, lc),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Intro
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_graph,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr(AppStrings.financialTwin, lc),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.tr(AppStrings.financialTwinDesc, lc),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chart Section
            Container(
              height: 300,
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: _buildChart(currentBalance, lc),
            ),

            const SizedBox(height: 24),

            // Controls
            Text(
              AppStrings.tr(AppStrings.scenarioParameters, lc),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),

            _buildSlider(
              context,
              label: AppStrings.tr(AppStrings.monthlyExtraInvestment, lc),
              value: _monthlyContribution,
              min: 0,
              max: 50000,
              divisions: 100,
              valueLabel: '${_monthlyContribution.toStringAsFixed(0)} ₺',
              onChanged: (v) => setState(() => _monthlyContribution = v),
            ),
            _buildSlider(
              context,
              label: AppStrings.tr(AppStrings.annualReturnExpectation, lc),
              value: _annualReturn,
              min: 0,
              max: 100,
              divisions: 100,
              valueLabel: '%${_annualReturn.toStringAsFixed(1)}',
              onChanged: (v) => setState(() => _annualReturn = v),
            ),
            _buildSlider(
              context,
              label: AppStrings.tr(AppStrings.expectedInflation, lc),
              value: _inflation,
              min: 0,
              max: 100,
              divisions: 100,
              valueLabel: '%${_inflation.toStringAsFixed(1)}',
              onChanged: (v) => setState(() => _inflation = v),
            ),
            _buildSlider(
              context,
              label: AppStrings.tr(AppStrings.durationYears, lc),
              value: _years.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              valueLabel: '$_years ${AppStrings.tr(AppStrings.years, lc)}',
              onChanged: (v) => setState(() => _years = v.toInt()),
            ),

            const SizedBox(height: 24),
            _buildResultSummary(currentBalance, lc),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(valueLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChart(double startingBalance, String lc) {
    if (_years <= 0) return const SizedBox.shrink();

    // Calculate projection points
    final spotsNominal = <FlSpot>[];
    final spotsReal = <FlSpot>[];

    var currentNominal = startingBalance;

    for (var i = 0; i <= _years; i++) {
      // Current real value calculation relative to year 0
      final currentReal = currentNominal / pow(1 + _inflation / 100, i);

      spotsNominal.add(FlSpot(i.toDouble(), currentNominal));
      spotsReal.add(FlSpot(i.toDouble(), currentReal));

      // Annual calculation for NEXT year
      for (var m = 0; m < 12; m++) {
        currentNominal += _monthlyContribution;
        currentNominal *= (1 + (_annualReturn / 100 / 12));
      }
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 2 != 0 && _years > 10) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      '${value.toInt()}. ${AppStrings.tr(AppStrings.years, lc)}',
                      style: const TextStyle(fontSize: 10)),
                );
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(_formatCompact(value, lc),
                    style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
              reservedSize: 40,
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Nominal (Blue)
          LineChartBarData(
            spots: spotsNominal,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          // Real (Green/Orange - Purchasing Power)
          LineChartBarData(
            spots: spotsReal,
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: AppColors.success.withValues(alpha: 0.1)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isNominal = spot.barIndex == 0;
                return LineTooltipItem(
                  '${spot.x.toInt()}. ${AppStrings.tr(AppStrings.years, lc)}\n${isNominal ? AppStrings.tr(AppStrings.nominal, lc) : AppStrings.tr(AppStrings.real, lc)}: ${_formatCompact(spot.y, lc)} ₺',
                  TextStyle(
                      color: isNominal ? Colors.white : Colors.greenAccent,
                      fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(double startBalance, String lc) {
    // Recalculate final values
    var currentNominal = startBalance;
    for (var i = 0; i < _years; i++) {
      for (var m = 0; m < 12; m++) {
        currentNominal += _monthlyContribution;
        currentNominal *= (1 + (_annualReturn / 100 / 12));
      }
    }
    final realValue = currentNominal / pow(1 + _inflation / 100, _years);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(
            '$_years ${AppStrings.tr(AppStrings.estimatedWealthAfter, lc)}',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(currentNominal, lc),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  '${AppStrings.tr(AppStrings.purchasingPowerToday, lc)}: ${_formatCurrency(realValue, lc)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value, String lc) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} ${AppStrings.tr(AppStrings.million, lc)} ₺';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} ${AppStrings.tr(AppStrings.thousand, lc)} ₺';
    }
    return '${value.toStringAsFixed(0)} ₺';
  }

  String _formatCompact(double value, String lc) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)} ${AppStrings.tr(AppStrings.millionShort, lc)}';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} ${AppStrings.tr(AppStrings.thousandShort, lc)}';
    }
    return value.toStringAsFixed(0);
  }
}
