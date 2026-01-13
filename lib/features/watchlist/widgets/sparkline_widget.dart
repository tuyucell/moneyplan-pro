import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:invest_guide/core/constants/colors.dart';
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
    // If no data, generate a mock sparkline based on isPositive
    final chartData = data ?? _generateMockData(isPositive);

    if (chartData.isEmpty) return SizedBox(width: width, height: height);

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
                color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _generateMockData(bool positive) {
    final random = math.Random();
    var mock = <double>[1.0];
    for (var i = 0; i < 10; i++) {
       var change = (random.nextDouble() - (positive ? 0.4 : 0.6)) * 0.1;
       mock.add(mock.last + change);
    }
    return mock;
  }
}
