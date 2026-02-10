class PriceAlert {
  final String id;
  final String assetId;
  final String symbol;
  final String name;
  final double targetPrice;
  final bool
      isAbove; // true: alert when price goes *above* target. false: when *below*.
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;

  PriceAlert({
    required this.id,
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.targetPrice,
    required this.isAbove,
    this.isActive = true,
    DateTime? createdAt,
    this.lastTriggeredAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PriceAlert copyWith({
    String? id,
    String? assetId,
    String? symbol,
    String? name,
    double? targetPrice,
    bool? isAbove,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTriggeredAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      targetPrice: targetPrice ?? this.targetPrice,
      isAbove: isAbove ?? this.isAbove,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'symbol': symbol,
      'name': name,
      'targetPrice': targetPrice,
      'isAbove': isAbove,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    };
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      assetId: json['assetId'],
      symbol: json['symbol'],
      name: json['name'],
      targetPrice: (json['targetPrice'] as num).toDouble(),
      isAbove: json['isAbove'] ?? true,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.parse(json['lastTriggeredAt'])
          : null,
    );
  }
}
