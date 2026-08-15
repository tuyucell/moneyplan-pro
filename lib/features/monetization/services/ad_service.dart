import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/core/config/providers/app_config_provider.dart';

class AdService extends StateNotifier<int> {
  final Ref ref;

  AdService(this.ref) : super(0);

  bool shouldShowAd() {
    // Never show ads to Pro users
    final isPro = ref.read(isProUserProvider);
    if (isPro) return false;

    final config = ref.read(appConfigProvider);
    final frequency = config.interstitialAdFrequency;

    // Increment counter
    state = state + 1;

    // Check if threshold reached
    if (state >= frequency) {
      state = 0; // Reset counter
      return true;
    }

    return false;
  }

  Future<void> showInterstitialAd(BuildContext context,
      {bool force = false}) async {
    // Store builds must not display the old placeholder financial promotions.
    // Re-enable this only after a real provider, truthful creatives, consent and
    // the related App Store privacy disclosures are configured.
    return;
  }
}

final adServiceProvider = StateNotifierProvider<AdService, int>((ref) {
  return AdService(ref);
});
