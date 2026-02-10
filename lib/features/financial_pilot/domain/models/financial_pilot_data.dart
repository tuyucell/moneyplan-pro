class FinancialPilotData {
  final List<PilotChartPoint> chartData;
  final List<PilotInsight> insights;
  final double currentBalance;
  final double minProjectedBalance;
  final String safetyStatus; // 'SAFE', 'WARNING', 'CRITICAL'
  final bool scenarioApplied;
  final int runwayDays; // New: Days until balance < 0

  FinancialPilotData({
    required this.chartData,
    required this.insights,
    required this.currentBalance,
    required this.minProjectedBalance,
    required this.safetyStatus,
    required this.scenarioApplied,
    required this.runwayDays,
  });

  factory FinancialPilotData.fromJson(Map<String, dynamic> json) {
    final chartData = (json['chart_data'] as List?)
            ?.map((e) => PilotChartPoint.fromJson(e))
            .toList() ??
        [];

    // Calculate runwayDays
    var calculatedRunway = 90; // Default to max if never hits 0
    for (var i = 0; i < chartData.length; i++) {
      if (chartData[i].balance < 0) {
        calculatedRunway = i;
        break;
      }
    }

    return FinancialPilotData(
      chartData: chartData,
      insights: (json['insights'] as List?)
              ?.map((e) => PilotInsight.fromJson(e))
              .toList() ??
          [],
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      minProjectedBalance:
          (json['min_projected_balance'] as num?)?.toDouble() ?? 0.0,
      safetyStatus: json['safety_status'] as String? ?? 'SAFE',
      scenarioApplied: json['scenario_applied'] as bool? ?? false,
      runwayDays: calculatedRunway,
    );
  }
}

class PilotInsight {
  final String type; // 'CRITICAL', 'WARNING', 'OPPORTUNITY', 'ALERT'
  final String title;
  final String message;
  final DateTime? date;
  final double? amount;

  PilotInsight({
    required this.type,
    required this.title,
    required this.message,
    this.date,
    this.amount,
  });

  factory PilotInsight.fromJson(Map<String, dynamic> json) {
    return PilotInsight(
      type: json['type'] as String? ?? 'INFO',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class PilotChartPoint {
  final DateTime date;
  final double balance;
  final double income;
  final double expense;

  PilotChartPoint({
    required this.date,
    required this.balance,
    required this.income,
    required this.expense,
  });

  factory PilotChartPoint.fromJson(Map<String, dynamic> json) {
    return PilotChartPoint(
      date: DateTime.parse(json['date']),
      balance: (json['balance'] as num).toDouble(),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}
