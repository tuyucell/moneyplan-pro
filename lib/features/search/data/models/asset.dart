class Asset {
  final String id;
  final String name;
  final String symbol;
  final String category;
  final String? description;
  final String? iconUrl;
  final double? currentPriceUsd;
  final double? change24h;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
    this.description,
    this.iconUrl,
    this.currentPriceUsd,
    this.change24h,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      currentPriceUsd: json['current_price_usd'] != null
          ? (json['current_price_usd'] as num).toDouble()
          : null,
      change24h: json['change_24h'] != null
          ? (json['change_24h'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'category': category,
      'description': description,
      'icon_url': iconUrl,
      'current_price_usd': currentPriceUsd,
      'change_24h': change24h,
    };
  }
}
