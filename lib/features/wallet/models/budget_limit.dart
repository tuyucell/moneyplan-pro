class BudgetLimit {
  final String categoryId;
  final double limit;
  final int month; // Optinal: Specific for a month or general
  final int year;

  BudgetLimit({
    required this.categoryId,
    required this.limit,
    required this.month,
    required this.year,
  });

  factory BudgetLimit.fromJson(Map<String, dynamic> json) {
    return BudgetLimit(
      categoryId: json['categoryId'] as String,
      limit: (json['limit'] as num).toDouble(),
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'limit': limit,
      'month': month,
      'year': year,
    };
  }

  static String key(String categoryId, int year, int month) =>
      '${categoryId}_${year}_$month';
}
