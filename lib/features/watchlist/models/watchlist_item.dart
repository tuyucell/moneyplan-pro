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
      'assetId': assetId,
      'category': category,
    };
  }

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      assetId: json['assetId'] as String?,
      category: json['category'] as String?,
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
