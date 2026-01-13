import 'package:dio/dio.dart';

/// Ücretsiz Kripto API Servisi
/// CoinGecko'nun ücretsiz demo API'sini kullanır
class CryptoApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.coingecko.com/api/v3',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Coin fiyatlarını getir (ÜCRETSIZ)
  /// https://api.coingecko.com/api/v3/simple/price
  static Future<Map<String, dynamic>> getCoinPrices(List<String> coinIds) async {
    try {
      final response = await _dio.get('/simple/price', queryParameters: {
        'ids': coinIds.join(','),
        'vs_currencies': 'usd',
        'include_24hr_change': 'true',
        'include_market_cap': 'true',
        'include_24hr_vol': 'true',
      });

      return response.data;
    } catch (e) {
      throw Exception('Fiyat bilgisi alınamadı: $e');
    }
  }

  /// Popüler coinleri getir (ÜCRETSIZ)
  static Future<List<Map<String, dynamic>>> getTrendingCoins() async {
    try {
      final response = await _dio.get('/search/trending');
      final coins = response.data['coins'] as List;
      return coins.map((c) => c['item'] as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Trending coinler alınamadı: $e');
    }
  }

  /// Market verileri (ÜCRETSIZ - limit var)
  /// vs_currency: usd, eur, try, vb.
  /// order: market_cap_desc, volume_desc
  static Future<List<Map<String, dynamic>>> getMarkets({
    String vsCurrency = 'usd',
    String order = 'market_cap_desc',
    int perPage = 20,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/coins/markets', queryParameters: {
        'vs_currency': vsCurrency,
        'order': order,
        'per_page': perPage,
        'page': page,
        'sparkline': false,
      });

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Market verileri alınamadı: $e');
    }
  }

  /// Coin detaylarını getir (ÜCRETSIZ)
  static Future<Map<String, dynamic>> getCoinDetails(String coinId) async {
    try {
      final response = await _dio.get('/coins/$coinId', queryParameters: {
        'localization': 'false',
        'tickers': 'false',
        'market_data': 'true',
        'community_data': 'false',
        'developer_data': 'false',
        'sparkline': 'false',
      });

      return response.data;
    } catch (e) {
      throw Exception('Coin detayları alınamadı: $e');
    }
  }

  /// Market chart verilerini getir (ÜCRETSIZ)
  static Future<Map<String, dynamic>> getCoinMarketChart(
    String coinId,
    String days,
  ) async {
    try {
      final response = await _dio.get('/coins/$coinId/market_chart', queryParameters: {
        'vs_currency': 'usd',
        'days': days,
      });

      return response.data;
    } catch (e) {
      throw Exception('Chart verileri alınamadı: $e');
    }
  }
}

/// Binance Public API (Tamamen ÜCRETSIZ, limit yok)
class BinanceApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.binance.com/api/v3',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 24 saat fiyat değişimi (ÜCRETSIZ, limit yok)
  static Future<Map<String, dynamic>> get24HrTicker(String symbol) async {
    try {
      final response = await _dio.get('/ticker/24hr', queryParameters: {
        'symbol': symbol, // örn: BTCUSDT
      });
      return response.data;
    } catch (e) {
      throw Exception('Binance ticker alınamadı: $e');
    }
  }

  /// Tüm ticker'lar (ÜCRETSIZ)
  static Future<List<Map<String, dynamic>>> getAllTickers() async {
    try {
      final response = await _dio.get('/ticker/24hr');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Binance tickers alınamadı: $e');
    }
  }

  /// Güncel fiyat (ÜCRETSIZ, çok hızlı)
  static Future<double> getCurrentPrice(String symbol) async {
    try {
      final response = await _dio.get('/ticker/price', queryParameters: {
        'symbol': symbol,
      });
      return double.parse(response.data['price']);
    } catch (e) {
      throw Exception('Fiyat alınamadı: $e');
    }
  }
}

/// CoinCap API (Tamamen ÜCRETSIZ)
class CoinCapApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.coincap.io/v2',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Varlık listesi (ÜCRETSIZ)
  static Future<List<Map<String, dynamic>>> getAssets({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get('/assets', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      return List<Map<String, dynamic>>.from(response.data['data']);
    } catch (e) {
      throw Exception('CoinCap assets alınamadı: $e');
    }
  }

  /// Tek bir varlık (ÜCRETSIZ)
  static Future<Map<String, dynamic>> getAsset(String id) async {
    try {
      final response = await _dio.get('/assets/$id');
      return response.data['data'];
    } catch (e) {
      throw Exception('Asset bilgisi alınamadı: $e');
    }
  }
}
