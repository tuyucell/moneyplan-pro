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

  static const _verifiedUntilKey = 'subscription_verified_until';

  Future<void> _loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final rawExpiry = prefs.getString(_verifiedUntilKey);
    final expiry = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    state = expiry != null && expiry.isAfter(DateTime.now().toUtc())
        ? SubscriptionTier.pro
        : SubscriptionTier.free;
  }

  /// Applies an entitlement returned by the trusted backend.
  ///
  /// The client intentionally has no public "upgrade" method. A StoreKit result
  /// must be verified by the backend before this method is called.
  Future<void> applyVerifiedStatus({
    required bool isActive,
    DateTime? expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (isActive && expiresAt != null) {
      final utcExpiry = expiresAt.toUtc();
      await prefs.setString(_verifiedUntilKey, utcExpiry.toIso8601String());
      state = utcExpiry.isAfter(DateTime.now().toUtc())
          ? SubscriptionTier.pro
          : SubscriptionTier.free;
      return;
    }

    await prefs.remove(_verifiedUntilKey);
    state = SubscriptionTier.free;
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
