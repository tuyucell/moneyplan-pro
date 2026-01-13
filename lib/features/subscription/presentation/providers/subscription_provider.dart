import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionTier {
  free,
  pro,
}

class SubscriptionNotifier extends StateNotifier<SubscriptionTier> {
  SubscriptionNotifier() : super(SubscriptionTier.free) {
    _loadSubscription();
  }

  static const _storageKey = 'subscription_tier';

  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final tierStr = prefs.getString(_storageKey);
    if (tierStr == SubscriptionTier.pro.name) {
      state = SubscriptionTier.pro;
    } else {
      state = SubscriptionTier.free;
    }
  }

  Future<void> upgradeToPro() async {
    state = SubscriptionTier.pro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SubscriptionTier.pro.name);
  }

  Future<void> downgradeToFree() async {
    state = SubscriptionTier.free;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SubscriptionTier.free.name);
  }

  bool get isPro => state == SubscriptionTier.pro;
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionTier>((ref) {
  return SubscriptionNotifier();
});

// Helper provider for easy checking
final isProUserProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionProvider);
  return tier == SubscriptionTier.pro;
});
