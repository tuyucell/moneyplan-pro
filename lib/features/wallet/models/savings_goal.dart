import 'package:uuid/uuid.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int colorValue; // Storing Color as int for serialization
  final String iconCode;
  final double? interestRate;
  final DateTime? maturityDate;
  final String currencyCode;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.colorValue,
    this.iconCode = 'savings',
    this.interestRate,
    this.maturityDate,
    this.currencyCode = 'TRY',
  });

  factory SavingsGoal.create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    required int colorValue,
    double? interestRate,
    DateTime? maturityDate,
    String currencyCode = 'TRY',
  }) {
    return SavingsGoal(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      colorValue: colorValue,
      interestRate: interestRate,
      maturityDate: maturityDate,
      currencyCode: currencyCode,
    );
  }

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? colorValue,
    double? interestRate,
    DateTime? maturityDate,
    String? currencyCode,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      colorValue: colorValue ?? this.colorValue,
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  // Safety getters
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final percent = currentAmount / targetAmount;
    return percent > 1.0 ? 1.0 : percent;
  }

  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'interestRate': interestRate,
      'maturityDate': maturityDate?.toIso8601String(),
      'currencyCode': currencyCode,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      iconCode: json['iconCode'] as String? ?? 'savings',
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      maturityDate: json['maturityDate'] != null
          ? DateTime.parse(json['maturityDate'])
          : null,
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
    );
  }
}
