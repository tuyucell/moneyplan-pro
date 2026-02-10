class WatchlistItem {
  final String symbol;
  final String name;
  final String? assetId;
  final String? category; // e.g. 'crypto', 'stock'

  WatchlistItem({
    required this.symbol,
    required this.name,
    this.assetId,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'asset_id': assetId, // Map to snake_case for DB consistency
      'category': category,
    };
  }

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'] as String,
      name: (json['name'] ?? json['asset_name'] ?? '') as String,
      assetId: (json['asset_id'] ?? json['assetId']) as String?,
      category: (json['category'] ?? json['asset_type']) as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatchlistItem && other.symbol == symbol;
  }

  @override
  int get hashCode => symbol.hashCode;
}
