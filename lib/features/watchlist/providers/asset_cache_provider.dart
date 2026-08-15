import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/search/data/models/asset.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart';

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

          if (kDebugMode) {
            debugPrint('Backend price for $assetId is unavailable.');
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Backend API fetch failed for $assetId: $e');
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
