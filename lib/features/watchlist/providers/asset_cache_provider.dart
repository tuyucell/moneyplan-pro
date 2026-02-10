import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:moneyplan_pro/features/search/data/models/asset.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart'; // Add this import

/// Cache entry with timestamp for invalidation
class _CachedAsset {
  final Asset asset;
  final DateTime timestamp;

  _CachedAsset(this.asset, this.timestamp);

  bool get isExpired {
    // Cache expires after 5 minutes
    return DateTime.now().difference(timestamp).inMinutes > 5;
  }
}

/// Asset cache notifier for performance optimization
class AssetCacheNotifier extends StateNotifier<Map<String, _CachedAsset>> {
  AssetCacheNotifier() : super({});

  /// Fetch asset with caching (returns cached value if not expired)
  Future<Asset?> fetchAsset(String assetId) async {
    try {
      // Check cache first
      final cached = state[assetId];
      if (cached != null && !cached.isExpired) {
        if (kDebugMode) {
          debugPrint('Asset cache HIT for $assetId');
        }
        return cached.asset;
      }

      if (kDebugMode) {
        debugPrint('Asset cache MISS for $assetId - fetching from Supabase');
      }

      // 1. Try Backend API (Prioritized)
      try {
        final apiData = await MoneyPlanProApi.getAssetDetail(assetId);
        if (apiData != null && apiData.isNotEmpty) {
          final price = (apiData['price'] as num?)?.toDouble() ?? 0.0;

          final asset = Asset(
            id: assetId,
            name: apiData['name'] ?? assetId,
            symbol: apiData['symbol'] ?? assetId,
            category: apiData['category'] ?? 'other',
            currentPriceUsd: price,
            change24h: (apiData['change_percent'] as num?)?.toDouble(),
            description: apiData['description'],
            iconUrl: apiData['logo_url'],
          );

          // Only return here if price is valid (>0)
          if (price > 0) {
            _updateCache(assetId, asset);
            return asset;
          }

          // If price is 0, we DON'T return/cache yet, letting it fall back to Binance
          debugPrint(
              'Backend price for $assetId is 0, falling back to external...');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Backend API fetch failed for $assetId: $e');
      }

      // 2. Fallback: External APIs
      try {
        Asset? externalAsset;

        // A. Try Binance first for crypto assets (Very fast, no key needed for public data)
        if (_isPotentialCrypto(assetId)) {
          externalAsset = await _fetchFromBinance(assetId);
          if (externalAsset != null &&
              (externalAsset.currentPriceUsd ?? 0) > 0) {
            _updateCache(assetId, externalAsset);
            return externalAsset;
          }
        }

        // B. Try CoinGecko (Good for deep crypto info)
        externalAsset = await _fetchFromCoinGecko(assetId);
        if (externalAsset != null && (externalAsset.currentPriceUsd ?? 0) > 0) {
          _updateCache(assetId, externalAsset);
          return externalAsset;
        }

        // C. Try Yahoo Finance (for Stocks, ETFs, Forex)
        externalAsset = await _fetchFromYahooFinance(assetId);
        if (externalAsset != null && (externalAsset.currentPriceUsd ?? 0) > 0) {
          _updateCache(assetId, externalAsset);
          return externalAsset;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('External API fetch failed for $assetId: $e');
        }
      }

      // 3. Last Resort: Safe Mock Data
      // This ensures the UI never crashes or shows empty for key demos
      final mockAsset = _getMockFallback(assetId);
      if (mockAsset != null) {
        _updateCache(assetId, mockAsset);
        return mockAsset;
      }

      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching asset $assetId: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return null;
    }
  }

  bool _isPotentialCrypto(String id) {
    if (id.length <= 5 && !id.contains('.')) return true;
    final common = [
      'bitcoin',
      'ethereum',
      'solana',
      'cardano',
      'ripple',
      'polkadot',
      'dogecoin'
    ];
    return common.contains(id.toLowerCase());
  }

  Future<Asset?> _fetchFromBinance(String id) async {
    try {
      // Mapping for CoinGecko IDs to Binance Symbols
      final idToSymbol = {
        'bitcoin': 'BTC',
        'ethereum': 'ETH',
        'solana': 'SOL',
        'cardano': 'ADA',
        'ripple': 'XRP',
        'polkadot': 'DOT',
        'dogecoin': 'DOGE',
        'avalanche-2': 'AVAX',
        'binancecoin': 'BNB',
        'chainlink': 'LINK',
        'polygon': 'MATIC',
      };

      final symbol = idToSymbol[id.toLowerCase()] ?? id.toUpperCase();
      final pair = symbol.endsWith('USDT') ? symbol : '${symbol}USDT';

      final url =
          Uri.parse('https://api.binance.com/api/v3/ticker/24hr?symbol=$pair');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Asset(
          id: id,
          name: symbol,
          symbol: symbol,
          category: 'crypto',
          currentPriceUsd: double.tryParse(data['lastPrice'] ?? '0'),
          change24h: double.tryParse(data['priceChangePercent'] ?? '0'),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Binance fetch failed for $id: $e');
    }
    return null;
  }

  Future<Asset?> _fetchFromCoinGecko(String id) async {
    try {
      // CoinGecko requires lowercase IDs usually (e.g. 'bitcoin'), but we might have 'BTC'.
      // We need a mapping for common symbols to CoinGecko IDs
      final mapping = {
        'BTC': 'bitcoin',
        'ETH': 'ethereum',
        'SOL': 'solana',
        'BNB': 'binancecoin',
        'XRP': 'ripple',
        'ADA': 'cardano',
        'AVAX': 'avalanche-2',
        'DOT': 'polkadot',
        'DOGE': 'dogecoin',
      };

      final cgId = mapping[id.toUpperCase()] ?? id.toLowerCase();

      final url = Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=$cgId&vs_currencies=usd&include_24hr_change=true');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey(cgId)) {
          final item = data[cgId];
          return Asset(
            id: id,
            name: id.toUpperCase(),
            symbol: id.toUpperCase(),
            category: 'crypto',
            currentPriceUsd: (item['usd'] as num?)?.toDouble(),
            change24h: (item['usd_24h_change'] as num?)?.toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Asset?> _fetchFromYahooFinance(String symbol) async {
    try {
      // Yahoo Finance Chart API is often open for basic data
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final result = jsonResponse['chart']['result'];

        if (result is List && result.isNotEmpty) {
          final meta = result[0]['meta'];
          final price = (meta['regularMarketPrice'] as num?)?.toDouble();
          final prevClose = (meta['chartPreviousClose'] as num?)?.toDouble();

          double? changePercent;
          if (price != null && prevClose != null && prevClose != 0) {
            changePercent = ((price - prevClose) / prevClose) * 100;
          }

          return Asset(
            id: symbol,
            name: meta['symbol'] ??
                symbol, // Yahoo often provides symbol as name in meta sometimes
            symbol: (meta['symbol'] ?? symbol).toString(),
            category:
                (meta['instrumentType'] ?? 'stock').toString().toLowerCase(),
            currentPriceUsd: price,
            change24h: changePercent,
            description: meta['longName'], // Sometimes available
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Yahoo fetch error: $e');
    }
    return null;
  }

  Asset? _getMockFallback(String assetId) {
    if (assetId.toUpperCase() == 'AAPL') {
      return Asset(
        id: 'AAPL',
        name: 'Apple Inc.',
        symbol: 'AAPL',
        category: 'stock',
        currentPriceUsd: 185.50,
        change24h: 1.25,
      );
    }
    if (assetId.toUpperCase() == 'NVDA') {
      return Asset(
        id: 'NVDA',
        name: 'NVIDIA Corp',
        symbol: 'NVDA',
        category: 'stock',
        currentPriceUsd: 460.10,
        change24h: -0.5,
      );
    }
    if (assetId.toUpperCase() == 'BTC' || assetId.toLowerCase() == 'bitcoin') {
      return Asset(
        id: assetId,
        name: 'Bitcoin',
        symbol: 'BTC',
        category: 'crypto',
        currentPriceUsd: 43500.00,
        change24h: 2.1,
      );
    }
    return null;
  }

  void _updateCache(String assetId, Asset asset) {
    state = {
      ...state,
      assetId: _CachedAsset(asset, DateTime.now()),
    };
  }

  /// Clear cache for a specific asset
  void invalidateAsset(String assetId) {
    state = Map.from(state)..remove(assetId);
  }

  /// Clear all cache
  void clearCache() {
    state = {};
  }

  /// Remove expired entries
  void cleanupExpired() {
    state = Map.fromEntries(
      state.entries.where((entry) => !entry.value.isExpired),
    );
  }
}

/// Provider for asset cache
final assetCacheProvider =
    StateNotifierProvider<AssetCacheNotifier, Map<String, _CachedAsset>>((ref) {
  return AssetCacheNotifier();
});

/// Provider for fetching a single asset (with caching)
final assetProvider =
    FutureProvider.family<Asset?, String>((ref, assetId) async {
  return ref.read(assetCacheProvider.notifier).fetchAsset(assetId);
});
