import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/financial_pilot_data.dart';

class PilotForecastChart extends StatelessWidget {
  final List<PilotChartPoint> data;
  final double currentBalance;

  const PilotForecastChart({
    super.key,
    required this.data,
    required this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('Veri yok'));
    if (data.isEmpty) {
      return const Center(child: Text('Veri yok'));
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balance);
    }).toList();

    // Determine min/max for Y axis
    var minY = data
        .map((e) => e.balance)
        .reduce((curr, next) => curr < next ? curr : next);
    var maxY = data
        .map((e) => e.balance)
        .reduce((curr, next) => curr > next ? curr : next);

    // Add buffer
    if (minY > 0) {
      minY = 0;
    } // Always anchor to 0 if possible
    final range = maxY - minY;
    minY -= range * 0.1;
    maxY += range * 0.1;

    // Find min spot
    final minSpot = spots.reduce((v, e) => v.y < e.y ? v : e);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 15,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = data[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('d MMM').format(date),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: minY,
              y2: 0,
              color: Colors.red.withValues(alpha: 0.05),
            ),
            HorizontalRangeAnnotation(
              y1: 0,
              y2: maxY,
              color: Colors.green.withValues(alpha: 0.03),
            ),
          ],
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (spot.x == minSpot.x) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(radius: 0);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueAccent.withValues(alpha: 0.2),
                  Colors.blueAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          if (minY < 0 && maxY > 0)
            LineChartBarData(
              spots: [
                const FlSpot(0, 0),
                FlSpot((data.length - 1).toDouble(), 0)
              ],
              isCurved: false,
              color: Colors.red.withValues(alpha: 0.3),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.shade900,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final point = data[index];
                return LineTooltipItem(
                  '${DateFormat('d MMMM').format(point.date)}\n',
                  const TextStyle(color: Colors.white70, fontSize: 10),
                  children: [
                    TextSpan(
                      text: '${point.balance.toStringAsFixed(0)} TL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
