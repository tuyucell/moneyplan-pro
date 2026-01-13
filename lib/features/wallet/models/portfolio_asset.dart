class PortfolioAsset {
  final String id;
  final String symbol;
  final String name;
  final double units;
  final double averageCost;
  final String? category;

  final String currencyCode; // Para birimi (TRY, USD, EUR vb.)

  PortfolioAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.units,
    required this.averageCost,
    this.category,
    this.currencyCode = 'TRY',
  });

  double get totalCost => units * averageCost;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'units': units,
      'averageCost': averageCost,
      'category': category,
      'currencyCode': currencyCode,
    };
  }

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      units: (json['units'] as num).toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      category: json['category'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
    );
  }

  PortfolioAsset copyWith({
    String? id,
    String? symbol,
    String? name,
    double? units,
    double? averageCost,
    String? category,
    String? currencyCode,
  }) {
    return PortfolioAsset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      units: units ?? this.units,
      averageCost: averageCost ?? this.averageCost,
      category: category ?? this.category,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
