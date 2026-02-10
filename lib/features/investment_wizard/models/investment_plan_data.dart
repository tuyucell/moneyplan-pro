class InvestmentPlanData {
  // Step 2: Income & Expenses
  double monthlyIncome;
  double monthlyExpenses;

  // Step 3: Debt
  bool hasDebt;
  double debtAmount;
  double monthlyDebtPayment;

  // Step 4: Investment
  double monthlyInvestmentAmount;

  // Status
  bool isCompleted;
  String currencyCode;
  String riskProfile;
  Map<String, dynamic>? aiRecommendation;

  String get currencyDisplay {
    switch (currencyCode) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return currencyCode;
    }
  }

  // Calculated fields
  double get monthlyAvailable => monthlyIncome - monthlyExpenses;
  double get monthlyAfterDebt {
    if (!hasDebt) return monthlyAvailable;
    return monthlyAvailable - monthlyDebtPayment;
  }

  double get potentialInvestmentAmount => monthlyAvailable;

  int get monthsToPayOffDebt {
    if (!hasDebt || debtAmount <= 0 || monthlyDebtPayment <= 0) return 0;
    return (debtAmount / monthlyDebtPayment).ceil();
  }

  double get yearsToPayOffDebt {
    if (monthsToPayOffDebt == 0) return 0;
    return monthsToPayOffDebt / 12;
  }

  InvestmentPlanData({
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
    this.hasDebt = false,
    this.debtAmount = 0,
    this.monthlyDebtPayment = 0,
    this.monthlyInvestmentAmount = 0,
    this.isCompleted = false,
    this.currencyCode = 'TRY',
    this.riskProfile = 'muhafazakar',
    this.aiRecommendation,
  });

  InvestmentPlanData copyWith({
    double? monthlyIncome,
    double? monthlyExpenses,
    bool? hasDebt,
    double? debtAmount,
    double? monthlyDebtPayment,
    double? monthlyInvestmentAmount,
    bool? isCompleted,
    String? currencyCode,
    String? riskProfile,
    Map<String, dynamic>? aiRecommendation,
  }) {
    return InvestmentPlanData(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      hasDebt: hasDebt ?? this.hasDebt,
      debtAmount: debtAmount ?? this.debtAmount,
      monthlyDebtPayment: monthlyDebtPayment ?? this.monthlyDebtPayment,
      monthlyInvestmentAmount:
          monthlyInvestmentAmount ?? this.monthlyInvestmentAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      currencyCode: currencyCode ?? this.currencyCode,
      riskProfile: riskProfile ?? this.riskProfile,
      aiRecommendation: aiRecommendation ?? this.aiRecommendation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'hasDebt': hasDebt,
      'debtAmount': debtAmount,
      'monthlyDebtPayment': monthlyDebtPayment,
      'monthlyInvestmentAmount': monthlyInvestmentAmount,
      'isCompleted': isCompleted,
      'currencyCode': currencyCode,
      'riskProfile': riskProfile,
      'aiRecommendation': aiRecommendation,
    };
  }

  factory InvestmentPlanData.fromJson(Map<String, dynamic> json) {
    return InvestmentPlanData(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0,
      monthlyExpenses: (json['monthlyExpenses'] as num?)?.toDouble() ?? 0,
      hasDebt: json['hasDebt'] as bool? ?? false,
      debtAmount: (json['debtAmount'] as num?)?.toDouble() ?? 0,
      monthlyDebtPayment: (json['monthlyDebtPayment'] as num?)?.toDouble() ?? 0,
      monthlyInvestmentAmount:
          (json['monthlyInvestmentAmount'] as num?)?.toDouble() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
      riskProfile: json['riskProfile'] as String? ?? 'muhafazakar',
      aiRecommendation: json['aiRecommendation'] != null
          ? Map<String, dynamic>.from(json['aiRecommendation'])
          : null,
    );
  }
}
