import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'dart:math' as math;

class SparklineWidget extends StatelessWidget {
  final List<double>? data;
  final bool isPositive;
  final double width;
  final double height;

  const SparklineWidget({
    super.key,
    this.data,
    required this.isPositive,
    this.width = 80,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = data ?? const <double>[];

    if (chartData.length < 2) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: chartData.reduce(math.min) - 0.1,
          maxY: chartData.reduce(math.max) + 0.1,
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: isPositive ? AppColors.success : AppColors.error,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (isPositive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
