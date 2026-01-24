import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:invest_guide/core/config/providers/app_config_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

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
    // Pro users never see ads
    final isPro = ref.read(isProUserProvider);
    if (isPro) return;

    // If force is true (like PDF/CSV export), always show
    // Otherwise use frequency logic
    if (!force && !shouldShowAd()) return;

    // Show Mock Ad Dialog
    await showDialog(
      context: context,
      barrierDismissible: false, // User must wait/interact
      builder: (context) => const _MockAdDialog(),
    );
  }
}

class _MockAdDialog extends ConsumerStatefulWidget {
  const _MockAdDialog();

  @override
  ConsumerState<_MockAdDialog> createState() => _MockAdDialogState();
}

class _MockAdDialogState extends ConsumerState<_MockAdDialog> {
  late int _countdown;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider);
    _countdown = config.interstitialDuration;
    _startTimer();
  }

  void _startTimer() async {
    while (_countdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ad Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(AppStrings.tr(AppStrings.adLabel, lc),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  if (_countdown > 0)
                    Text(
                      '${AppStrings.tr(AppStrings.closeIn, lc)} $_countdown',
                      style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Ad Content - Modern Gradient Design
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      Colors.purple.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative background icons
                    Positioned(
                      top: 0,
                      right: -50,
                      child: Icon(
                        Icons.trending_up,
                        size: 200,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Icon(
                        Icons.account_balance,
                        size: 150,
                        color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    // Main ad content
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon badge
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.savings,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sponsored label
                            Text(
                              AppStrings.tr(AppStrings.sponsoredContent, lc),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Main headline
                            const Text(
                              'Yüksek Faizli Mevduat',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.grey900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Offer text
                            Text(
                              '%45 Yıllık Faiz Fırsatı!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text(
                              AppStrings.tr(AppStrings.removeAdsDesc, lc),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // CTA Button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.touch_app),
                              label: Text(
                                AppStrings.tr(AppStrings.learnMore, lc),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final adServiceProvider = StateNotifierProvider<AdService, int>((ref) {
  return AdService(ref);
});
