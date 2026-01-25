class PurchaseAdvice {
  final String recommendation; // 'CASH' or 'INSTALLMENT'
  final double marketRate;
  final double cashPrice;
  final double totalInstallmentPrice;
  final double npvCost;
  final double opportunityGain;
  final String message;

  PurchaseAdvice({
    required this.recommendation,
    required this.marketRate,
    required this.cashPrice,
    required this.totalInstallmentPrice,
    required this.npvCost,
    required this.opportunityGain,
    required this.message,
  });

  factory PurchaseAdvice.fromJson(Map<String, dynamic> json) {
    return PurchaseAdvice(
      recommendation: json['recommendation'] as String,
      marketRate: (json['market_rate'] as num).toDouble(),
      cashPrice: (json['cash_price'] as num).toDouble(),
      totalInstallmentPrice:
          (json['total_installment_price'] as num).toDouble(),
      npvCost: (json['npv_cost'] as num).toDouble(),
      opportunityGain: (json['opportunity_gain'] as num).toDouble(),
      message: json['message'] as String,
    );
  }
}
