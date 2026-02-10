import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

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
      // Auto-heal: Ensure DB knows we are Pro (Fix for mismatch)
      await _syncProStatusToDb(true);
    } else {
      state = SubscriptionTier.free;
    }
  }

  Future<void> upgradeToPro() async {
    state = SubscriptionTier.pro;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SubscriptionTier.pro.name);
    await _syncProStatusToDb(true);
  }

  Future<void> downgradeToFree() async {
    state = SubscriptionTier.free;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, SubscriptionTier.free.name);
    await _syncProStatusToDb(false);
  }

  /// Syncs the subscription status to the Supabase users table
  Future<void> _syncProStatusToDb(bool isPro) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'is_premium': isPro}).eq('id', user.id);
      }
    } catch (e) {
      // Fail silently if offline or not logged in, it will retry on next app launch
      debugPrint('Error syncing subscription to DB: $e');
    }
  }

  bool get isPro => state == SubscriptionTier.pro;
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionTier>((ref) {
  return SubscriptionNotifier();
});

// Helper provider for easy checking
final isProUserProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionProvider);
  return tier == SubscriptionTier.pro;
});
