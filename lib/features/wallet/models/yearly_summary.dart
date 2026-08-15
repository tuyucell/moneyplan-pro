import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';

class YearlySummary {
  final int year;
  final List<MonthlySummary> monthlySummaries;

  YearlySummary({
    required this.year,
    required this.monthlySummaries,
  });

  double get totalIncome =>
      monthlySummaries.fold(0, (sum, m) => sum + m.totalIncome);
  double get totalExpense =>
      monthlySummaries.fold(0, (sum, m) => sum + m.totalExpense);
  double get totalPendingExpense =>
      monthlySummaries.fold(0, (sum, m) => sum + m.totalPendingExpense);
  // totalExpense already contains both paid and pending expenses.
  double get totalOutflow => totalExpense;

  /// Net cash flow produced during the selected year. Opening balances and
  /// credit limits are account positions, not yearly income or expense.
  double get remainingBalance => totalIncome - totalExpense;
  double get totalBES => monthlySummaries.fold(0, (sum, m) => sum + m.totalBES);
  double get totalSavings =>
      monthlySummaries.fold(0, (sum, m) => sum + m.totalSavings);
  double get savingsRate =>
      totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;

  Map<String, double> get incomeByCurrency {
    final result = <String, double>{};
    for (final m in monthlySummaries) {
      m.incomeByCurrency.forEach((k, v) => result[k] = (result[k] ?? 0) + v);
    }
    return result;
  }

  Map<String, double> get expenseByCurrency {
    final result = <String, double>{};
    for (final m in monthlySummaries) {
      m.expenseByCurrency.forEach((k, v) => result[k] = (result[k] ?? 0) + v);
    }
    return result;
  }

  bool get isPositive => remainingBalance >= 0;

  // Monthly breakdown for charts
  List<Map<String, dynamic>> get monthlyBreakdown => monthlySummaries
      .map((m) => {
            'month': m.month,
            'monthName': m.monthName,
            'income': m.totalIncome,
            'expense': m.totalOutflow,
            'balance': m.remainingBalance,
          })
      .toList();
}
