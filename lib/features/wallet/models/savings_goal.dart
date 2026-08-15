import 'dart:math' as math;

import 'package:uuid/uuid.dart';

enum SavingsPlanType { savings, bes, lifeInsurance }

enum ContributionPeriod { monthly, quarterly, semiAnnual, yearly }

enum SavingsFundingMethod { cash, creditCard }

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int colorValue;
  final String iconCode;
  final double? interestRate;
  final DateTime? maturityDate;
  final String currencyCode;
  final SavingsPlanType planType;
  final double periodicContribution;
  final ContributionPeriod contributionPeriod;
  final SavingsFundingMethod fundingMethod;
  final String? paymentAccountId;
  final bool automaticPayment;
  final bool createWalletExpense;
  final DateTime? contractStartDate;
  final int? contractYears;
  final int paymentDay;
  final double governmentContributionRate;
  final double estimatedAnnualReturnRate;
  final double annualProfitShareRate;
  final double governmentContributionBalance;
  final double profitShareBalance;
  final DateTime? lastAccrualDate;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.colorValue,
    this.iconCode = 'savings',
    this.interestRate,
    this.maturityDate,
    this.currencyCode = 'TRY',
    this.planType = SavingsPlanType.savings,
    this.periodicContribution = 0,
    this.contributionPeriod = ContributionPeriod.monthly,
    this.fundingMethod = SavingsFundingMethod.cash,
    this.paymentAccountId,
    this.automaticPayment = false,
    this.createWalletExpense = false,
    this.contractStartDate,
    this.contractYears,
    this.paymentDay = 1,
    this.governmentContributionRate = 20,
    this.estimatedAnnualReturnRate = 0,
    this.annualProfitShareRate = 0,
    this.governmentContributionBalance = 0,
    this.profitShareBalance = 0,
    this.lastAccrualDate,
  });

  factory SavingsGoal.create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    required int colorValue,
    double? interestRate,
    DateTime? maturityDate,
    String currencyCode = 'TRY',
    SavingsPlanType planType = SavingsPlanType.savings,
    double periodicContribution = 0,
    ContributionPeriod contributionPeriod = ContributionPeriod.monthly,
    SavingsFundingMethod fundingMethod = SavingsFundingMethod.cash,
    String? paymentAccountId,
    bool automaticPayment = false,
    bool createWalletExpense = false,
    DateTime? contractStartDate,
    int? contractYears,
    int paymentDay = 1,
    double governmentContributionRate = 20,
    double estimatedAnnualReturnRate = 0,
    double annualProfitShareRate = 0,
  }) {
    final start = contractStartDate ?? DateTime.now();
    final calculatedMaturity = maturityDate ??
        (contractYears != null
            ? DateTime(start.year + contractYears, start.month, start.day)
            : null);
    return SavingsGoal(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      colorValue: colorValue,
      iconCode: _iconFor(planType),
      interestRate: interestRate,
      maturityDate: calculatedMaturity,
      currencyCode: currencyCode,
      planType: planType,
      periodicContribution: periodicContribution,
      contributionPeriod: contributionPeriod,
      fundingMethod: fundingMethod,
      paymentAccountId: paymentAccountId,
      automaticPayment: automaticPayment,
      createWalletExpense: createWalletExpense,
      contractStartDate: start,
      contractYears: contractYears,
      paymentDay: paymentDay.clamp(1, 28),
      governmentContributionRate: governmentContributionRate,
      estimatedAnnualReturnRate: estimatedAnnualReturnRate,
      annualProfitShareRate: annualProfitShareRate,
      // currentAmount is entered as today's value. Starting accrual at the
      // current month prevents an older contract start from being backfilled
      // on top of that already-current balance.
      lastAccrualDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
  }

  static String _iconFor(SavingsPlanType type) {
    switch (type) {
      case SavingsPlanType.bes:
        return 'bes';
      case SavingsPlanType.lifeInsurance:
        return 'life_insurance';
      case SavingsPlanType.savings:
        return 'savings';
    }
  }

  int get contributionIntervalMonths {
    switch (contributionPeriod) {
      case ContributionPeriod.monthly:
        return 1;
      case ContributionPeriod.quarterly:
        return 3;
      case ContributionPeriod.semiAnnual:
        return 6;
      case ContributionPeriod.yearly:
        return 12;
    }
  }

  bool get isContractPlan => planType != SavingsPlanType.savings;

  String get ledgerSourceId => 'savings_plan_$id';

  DateTime? get contractEndDate {
    if (maturityDate != null) return maturityDate;
    final start = contractStartDate;
    if (start == null || contractYears == null) return null;
    return DateTime(start.year + contractYears!, start.month, start.day);
  }

  /// Advances an automatic plan exactly once per completed calendar period.
  SavingsGoal accrueUntil(DateTime asOf) {
    if (!automaticPayment || periodicContribution <= 0) return this;
    final start = contractStartDate ?? lastAccrualDate ?? asOf;
    var cursor = DateTime(
      (lastAccrualDate ?? start).year,
      (lastAccrualDate ?? start).month,
      1,
    );
    final targetMonth = DateTime(asOf.year, asOf.month, 1);
    if (!cursor.isBefore(targetMonth)) return this;

    var balance = currentAmount;
    var government = governmentContributionBalance;
    var profitShare = profitShareBalance;
    final startMonth = DateTime(start.year, start.month, 1);
    final end = contractEndDate;

    while (cursor.isBefore(targetMonth)) {
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
      if (cursor.isBefore(startMonth)) continue;
      if (end != null && cursor.isAfter(DateTime(end.year, end.month, 1))) {
        break;
      }

      final elapsedMonths = (cursor.year - startMonth.year) * 12 +
          cursor.month -
          startMonth.month;
      if (elapsedMonths > 0 &&
          elapsedMonths % contributionIntervalMonths == 0) {
        balance += periodicContribution;
        if (planType == SavingsPlanType.bes && governmentContributionRate > 0) {
          final contribution =
              periodicContribution * governmentContributionRate / 100;
          government += contribution;
          balance += contribution;
        }
      }

      final monthlyReturn = estimatedAnnualReturnRate / 100 / 12;
      if (monthlyReturn > 0 && balance > 0) {
        balance += balance * monthlyReturn;
      }

      if (planType == SavingsPlanType.lifeInsurance &&
          cursor.month == 12 &&
          estimatedAnnualReturnRate > 0 &&
          annualProfitShareRate > 0) {
        final annualShare = balance *
            estimatedAnnualReturnRate /
            100 *
            annualProfitShareRate /
            100;
        profitShare += annualShare;
        balance += annualShare;
      }
    }

    return copyWith(
      currentAmount: balance,
      governmentContributionBalance: government,
      profitShareBalance: profitShare,
      lastAccrualDate: cursor,
    );
  }

  double projectedValueAtMaturity({DateTime? from}) {
    final end = contractEndDate;
    if (end == null) return currentAmount;
    var balance = currentAmount;
    var cursor = DateTime(
      (from ?? DateTime.now()).year,
      (from ?? DateTime.now()).month,
      1,
    );
    final endMonth = DateTime(end.year, end.month, 1);
    var months = 0;
    while (cursor.isBefore(endMonth) && months < 1200) {
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
      months++;
      if (periodicContribution > 0 &&
          months % contributionIntervalMonths == 0) {
        balance += periodicContribution;
        if (planType == SavingsPlanType.bes) {
          balance += periodicContribution * governmentContributionRate / 100;
        }
      }
      if (estimatedAnnualReturnRate > 0) {
        balance *= 1 + estimatedAnnualReturnRate / 100 / 12;
      }
      if (planType == SavingsPlanType.lifeInsurance &&
          cursor.month == 12 &&
          annualProfitShareRate > 0 &&
          estimatedAnnualReturnRate > 0) {
        balance += balance *
            estimatedAnnualReturnRate /
            100 *
            annualProfitShareRate /
            100;
      }
    }
    return math.max(0, balance);
  }

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? colorValue,
    double? interestRate,
    DateTime? maturityDate,
    String? currencyCode,
    SavingsPlanType? planType,
    double? periodicContribution,
    ContributionPeriod? contributionPeriod,
    SavingsFundingMethod? fundingMethod,
    String? paymentAccountId,
    bool clearPaymentAccountId = false,
    bool? automaticPayment,
    bool? createWalletExpense,
    DateTime? contractStartDate,
    int? contractYears,
    int? paymentDay,
    double? governmentContributionRate,
    double? estimatedAnnualReturnRate,
    double? annualProfitShareRate,
    double? governmentContributionBalance,
    double? profitShareBalance,
    DateTime? lastAccrualDate,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      colorValue: colorValue ?? this.colorValue,
      iconCode: _iconFor(planType ?? this.planType),
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      currencyCode: currencyCode ?? this.currencyCode,
      planType: planType ?? this.planType,
      periodicContribution: periodicContribution ?? this.periodicContribution,
      contributionPeriod: contributionPeriod ?? this.contributionPeriod,
      fundingMethod: fundingMethod ?? this.fundingMethod,
      paymentAccountId: clearPaymentAccountId
          ? null
          : (paymentAccountId ?? this.paymentAccountId),
      automaticPayment: automaticPayment ?? this.automaticPayment,
      createWalletExpense: createWalletExpense ?? this.createWalletExpense,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractYears: contractYears ?? this.contractYears,
      paymentDay: (paymentDay ?? this.paymentDay).clamp(1, 28),
      governmentContributionRate:
          governmentContributionRate ?? this.governmentContributionRate,
      estimatedAnnualReturnRate:
          estimatedAnnualReturnRate ?? this.estimatedAnnualReturnRate,
      annualProfitShareRate:
          annualProfitShareRate ?? this.annualProfitShareRate,
      governmentContributionBalance:
          governmentContributionBalance ?? this.governmentContributionBalance,
      profitShareBalance: profitShareBalance ?? this.profitShareBalance,
      lastAccrualDate: lastAccrualDate ?? this.lastAccrualDate,
    );
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => targetAmount > 0 && currentAmount >= targetAmount;

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
      'planType': planType.name,
      'periodicContribution': periodicContribution,
      'contributionPeriod': contributionPeriod.name,
      'fundingMethod': fundingMethod.name,
      'paymentAccountId': paymentAccountId,
      'automaticPayment': automaticPayment,
      'createWalletExpense': createWalletExpense,
      'contractStartDate': contractStartDate?.toIso8601String(),
      'contractYears': contractYears,
      'paymentDay': paymentDay,
      'governmentContributionRate': governmentContributionRate,
      'estimatedAnnualReturnRate': estimatedAnnualReturnRate,
      'annualProfitShareRate': annualProfitShareRate,
      'governmentContributionBalance': governmentContributionBalance,
      'profitShareBalance': profitShareBalance,
      'lastAccrualDate': lastAccrualDate?.toIso8601String(),
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
      return values.firstWhere(
        (value) => value.name == raw,
        orElse: () => fallback,
      );
    }

    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      colorValue: json['colorValue'] as int? ?? 0xFFFFA726,
      iconCode: json['iconCode'] as String? ?? 'savings',
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      maturityDate: DateTime.tryParse(json['maturityDate'] as String? ?? ''),
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
      planType: enumValue(
        SavingsPlanType.values,
        json['planType'],
        SavingsPlanType.savings,
      ),
      periodicContribution:
          (json['periodicContribution'] as num?)?.toDouble() ?? 0,
      contributionPeriod: enumValue(
        ContributionPeriod.values,
        json['contributionPeriod'],
        ContributionPeriod.monthly,
      ),
      fundingMethod: enumValue(
        SavingsFundingMethod.values,
        json['fundingMethod'],
        SavingsFundingMethod.cash,
      ),
      paymentAccountId: json['paymentAccountId'] as String?,
      automaticPayment: json['automaticPayment'] as bool? ?? false,
      createWalletExpense: json['createWalletExpense'] as bool? ?? false,
      contractStartDate:
          DateTime.tryParse(json['contractStartDate'] as String? ?? ''),
      contractYears: (json['contractYears'] as num?)?.toInt(),
      paymentDay: (json['paymentDay'] as num?)?.toInt() ?? 1,
      governmentContributionRate:
          (json['governmentContributionRate'] as num?)?.toDouble() ?? 20,
      estimatedAnnualReturnRate:
          (json['estimatedAnnualReturnRate'] as num?)?.toDouble() ?? 0,
      annualProfitShareRate:
          (json['annualProfitShareRate'] as num?)?.toDouble() ?? 0,
      governmentContributionBalance:
          (json['governmentContributionBalance'] as num?)?.toDouble() ?? 0,
      profitShareBalance: (json['profitShareBalance'] as num?)?.toDouble() ?? 0,
      lastAccrualDate:
          DateTime.tryParse(json['lastAccrualDate'] as String? ?? ''),
    );
  }
}
