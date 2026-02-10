import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/watchlist/providers/asset_cache_provider.dart';

/// Provider that triggers a refresh for all assets in the watchlist periodically
final watchlistRefreshProvider = StreamProvider<void>((ref) {
  // Trigger refresh every 30 seconds
  final controller = StreamController<void>();
  
  final timer = Timer.periodic(const Duration(seconds: 30), (timer) {
    if (!controller.isClosed) {
      // Invalidate the asset cache to force fresh data on next rebuild
      ref.read(assetCacheProvider.notifier).clearCache();
      controller.add(null);
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
