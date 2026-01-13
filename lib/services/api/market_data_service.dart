import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'commodity_service.dart';
import 'forex_service.dart';
import 'etf_service.dart';
import 'bond_service.dart';

/// Market Data Service - Fetches real-time prices for commodities, crypto, forex, stocks, ETFs, bonds
/// Using Finnhub.io for crypto and stocks - Free tier: 60 API calls/minute
/// Using demo data for commodities, forex, ETFs, and bonds (free tier doesn't support these)
/// Sign up: https://finnhub.io/register
class MarketDataService {
  // API Configuration
  static const String _apiKey =
      'd539trhr01qkplgtqgkgd539trhr01qkplgtqgl0'; // Finnhub API Key
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  /// Fetch commodity prices
  /// Note: Finnhub free tier doesn't support commodities, using demo data
  static Future<Map<String, double>> getCommodityPrices() async {
    try {
      final commodities = await CommodityService.getCommodityPrices();
      return commodities.map((key, value) => MapEntry(key, value.price));
    } catch (e) {
      debugPrint('Commodity Data Error: $e');
      return {};
    }
  }

  /// Fetch crypto prices
  /// Symbols: BINANCE:BTCUSDT, BINANCE:ETHUSDT, etc.
  static Future<Map<String, double>> getCryptoPrices() async {
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
  /// Note: Finnhub free tier doesn't support forex, using demo data
  static Future<Map<String, double>> getForexPrices() async {
    try {
      final forex = await ForexService.getForexPrices();
      return forex.map((key, value) => MapEntry(key, value.price));
    } catch (e) {
      debugPrint('Forex Data Error: $e');
      return {};
    }
  }

  /// Fetch stock prices (US stocks)
  static Future<Map<String, double>> getStockPrices() async {
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
  /// Note: Using demo data for ETFs
  static Future<Map<String, double>> getETFPrices() async {
    try {
      final etfs = await ETFService.getETFPrices();
      return etfs.map((key, value) => MapEntry(key, value.price));
    } catch (e) {
      debugPrint('ETF Data Error: $e');
      return {};
    }
  }

  /// Fetch bond yields
  /// Note: Using demo data for bonds
  static Future<Map<String, double>> getBondPrices() async {
    try {
      final bonds = await BondService.getBondPrices();
      return bonds.map((key, value) => MapEntry(key, value.price));
    } catch (e) {
      debugPrint('Bond Data Error: $e');
      return {};
    }
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
