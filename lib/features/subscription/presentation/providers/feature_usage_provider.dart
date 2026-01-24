import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final featureUsageProvider = Provider((ref) => FeatureUsageService());

class FeatureUsageService {
  static const _usageKeyPrefix = 'feature_usage_';

  Future<bool> hasFreeUsageRemaining(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_usageKeyPrefix${featureKey}_$today';

    final usageCount = prefs.getInt(key) ?? 0;
    return usageCount < 1; // Limit: 1 use per day
  }

  Future<void> trackUsage(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_usageKeyPrefix${featureKey}_$today';

    final usageCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, usageCount + 1);
  }

  Future<int> getUsageCount(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = '$_usageKeyPrefix${featureKey}_$today';

    return prefs.getInt(key) ?? 0;
  }
}

final featureLockedProvider =
    FutureProvider.family<bool, String>((ref, featureKey) async {
  final service = ref.watch(featureUsageProvider);
  final hasUsage = await service.hasFreeUsageRemaining(featureKey);
  return !hasUsage;
});
