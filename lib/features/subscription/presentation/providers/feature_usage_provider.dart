import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/core/services/remote_config_service.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';

final featureUsageProvider = Provider((ref) => FeatureUsageService());

class FeatureUsageService {
  static const _usageKeyPrefix = 'feature_usage_';

  // Just gets the current count, logic moved to provider
  Future<int> getUsageCount(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_usageKeyPrefix${featureKey}_$today';

    return prefs.getInt(key) ?? 0;
  }

  Future<void> trackUsage(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_usageKeyPrefix${featureKey}_$today';

    final usageCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, usageCount + 1);
  }
}

final featureLockedProvider =
    FutureProvider.family<bool, String>((ref, featureKey) async {
  final usageService = ref.watch(featureUsageProvider);
  final usageCount = await usageService.getUsageCount(featureKey);

  // 1. Get Feature Config
  final remoteService = ref.watch(remoteConfigServiceProvider);
  final flag = await remoteService.getFlag(featureKey);

  // If flag doesn't exist, assume no limit (or locked? defaulting to allowed/unlocked for safety)
  if (flag == null) return false;

  // 2. Get User Status
  final isPro = ref.watch(isProUserProvider);

  // 3. Determine Limit
  int? limit;
  if (isPro) {
    // Check metadata for Pro Limit
    if (flag.metadata != null &&
        flag.metadata!.containsKey('daily_pro_limit')) {
      final proLimit = flag.metadata!['daily_pro_limit'];
      if (proLimit is int) limit = proLimit;
    }
    // If no specific pro limit, assume unlimited for Pro unless stated otherwise
    if (limit == null) return false;
  } else {
    // Free user
    limit = flag.dailyFreeLimit;
  }

  // If no limit is set (null), it means unlimited
  if (limit == null) return false;

  // 4. Check Usage
  return usageCount >= limit;
});
