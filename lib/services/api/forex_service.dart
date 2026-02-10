
class ForexService {
  // Using demo mode since Finnhub free tier doesn't support forex
  static const bool _useDemoMode = true;

  static Future<Map<String, ForexData>> getForexPrices() async {
    if (_useDemoMode) {
      return _getDemoData();
    }

    // Future: implement real forex API here
    return _getDemoData();
  }

  static Future<Map<String, ForexData>> _getDemoData() async {
    // No delay - load immediately
    // await Future.delayed(const Duration(milliseconds: 300));

    // Real-ish forex prices (as of Dec 2025)
    return {
      'USDTRY': ForexData(
        symbol: 'USDTRY',
        name: 'Dolar/TL',
        nameEn: 'US Dollar/Turkish Lira',
        price: 32.45,
        change24h: 0.28,
        bid: 32.43,
        ask: 32.47,
      ),
      'EURTRY': ForexData(
        symbol: 'EURTRY',
        name: 'Euro/TL',
        nameEn: 'Euro/Turkish Lira',
        price: 35.12,
        change24h: 0.45,
        bid: 35.10,
        ask: 35.14,
      ),
      'EURUSD': ForexData(
        symbol: 'EURUSD',
        name: 'Euro/Dolar',
        nameEn: 'Euro/US Dollar',
        price: 1.082,
        change24h: 0.15,
        bid: 1.0819,
        ask: 1.0821,
      ),
      'GBPTRY': ForexData(
        symbol: 'GBPTRY',
        name: 'Sterlin/TL',
        nameEn: 'British Pound/Turkish Lira',
        price: 41.23,
        change24h: 0.32,
        bid: 41.21,
        ask: 41.25,
      ),
      'JPYTRY': ForexData(
        symbol: 'JPYTRY',
        name: 'Yen/TL',
        nameEn: 'Japanese Yen/Turkish Lira',
        price: 0.22,
        change24h: -0.18,
        bid: 0.2198,
        ask: 0.2202,
      ),
      'GBPUSD': ForexData(
        symbol: 'GBPUSD',
        name: 'Sterlin/Dolar',
        nameEn: 'British Pound/US Dollar',
        price: 1.27,
        change24h: 0.08,
        bid: 1.2698,
        ask: 1.2702,
      ),
      'USDJPY': ForexData(
        symbol: 'USDJPY',
        name: 'Dolar/Yen',
        nameEn: 'US Dollar/Japanese Yen',
        price: 149.85,
        change24h: -0.22,
        bid: 149.83,
        ask: 149.87,
      ),
    };
  }
}

class ForexData {
  final String symbol;
  final String name;
  final String nameEn;
  final double price;
  final double change24h;
  final double bid;
  final double ask;

  ForexData({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.change24h,
    required this.bid,
    required this.ask,
  });

  factory ForexData.fromJson(Map<String, dynamic> json) {
    return ForexData(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      price: (json['price'] as num).toDouble(),
      change24h: (json['change_24h'] as num).toDouble(),
      bid: (json['bid'] as num).toDouble(),
      ask: (json['ask'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'name_en': nameEn,
      'price': price,
      'change_24h': change24h,
      'bid': bid,
      'ask': ask,
    };
  }
}
