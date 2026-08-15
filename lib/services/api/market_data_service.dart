import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Market Data Service - Fetches real-time prices for commodities, crypto, forex, stocks, ETFs, bonds
/// Legacy client-side service. New screens should use MoneyPlanProApi so keys
/// remain on the backend and unavailable data is never replaced with samples.
class MarketDataService {
  static const String _apiKey = '';
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  /// Fetch commodity prices
  static Future<Map<String, double>> getCommodityPrices() async {
    return {};
  }

  /// Fetch crypto prices
  /// Symbols: BINANCE:BTCUSDT, BINANCE:ETHUSDT, etc.
  static Future<Map<String, double>> getCryptoPrices() async {
    if (_apiKey.isEmpty) return {};
    try {
      final cryptos = {
        'BINANCE:BTCUSDT': 'BTC',
        'BINANCE:ETHUSDT': 'ETH',
        'BINANCE:BNBUSDT': 'BNB',
        'BINANCE:SOLUSDT': 'SOL',
      };

      final prices = <String, double>{};

      for (final entry in cryptos.entries) {
        final symbol = entry.key;
        final shortSymbol = entry.value;

        final response = await http.get(
          Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final currentPrice = data['c'] as num?;

          if (currentPrice != null) {
            prices[shortSymbol] = currentPrice.toDouble();
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      return prices;
    } catch (e) {
      debugPrint('Crypto Data Error: $e');
      return {};
    }
  }

  /// Fetch forex prices
  static Future<Map<String, double>> getForexPrices() async {
    return {};
  }

  /// Fetch stock prices (US stocks)
  static Future<Map<String, double>> getStockPrices() async {
    if (_apiKey.isEmpty) return {};
    try {
      final stocks = {
        'AAPL': 'AAPL',
        'TSLA': 'TSLA',
        'MSFT': 'MSFT',
        'GOOGL': 'GOOGL',
        'AMZN': 'AMZN',
      };

      final prices = <String, double>{};

      for (final symbol in stocks.keys) {
        final response = await http.get(
          Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final currentPrice = data['c'] as num?;

          if (currentPrice != null) {
            prices[symbol] = currentPrice.toDouble();
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      return prices;
    } catch (e) {
      debugPrint('Stock Data Error: $e');
      return {};
    }
  }

  /// Fetch ETF prices
  static Future<Map<String, double>> getETFPrices() async {
    return {};
  }

  /// Fetch bond yields
  static Future<Map<String, double>> getBondPrices() async {
    return {};
  }

  /// Fetch all market data at once
  static Future<MarketData> getAllMarketData() async {
    try {
      // Fetch all in parallel
      final results = await Future.wait([
        getCommodityPrices(),
        getCryptoPrices(),
        getForexPrices(),
        getStockPrices(),
        getETFPrices(),
        getBondPrices(),
      ]);

      return MarketData(
        commodities: results[0],
        crypto: results[1],
        forex: results[2],
        stocks: results[3],
        etfs: results[4],
        bonds: results[5],
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Market Data Error: $e');
      return MarketData(
        commodities: {},
        crypto: {},
        forex: {},
        stocks: {},
        etfs: {},
        bonds: {},
        lastUpdate: DateTime.now(),
      );
    }
  }
}

class MarketData {
  final Map<String, double> commodities;
  final Map<String, double> crypto;
  final Map<String, double> forex;
  final Map<String, double> stocks;
  final Map<String, double> etfs;
  final Map<String, double> bonds;
  final DateTime lastUpdate;

  MarketData({
    required this.commodities,
    required this.crypto,
    required this.forex,
    required this.stocks,
    required this.etfs,
    required this.bonds,
    required this.lastUpdate,
  });

  Map<String, double> getAll() {
    return {
      ...commodities,
      ...crypto,
      ...forex,
      ...stocks,
      ...etfs,
      ...bonds,
    };
  }
}
