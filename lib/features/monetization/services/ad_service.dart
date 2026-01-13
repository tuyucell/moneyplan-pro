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
    final frequency = config.adFrequency;

    // Increment counter
    state = state + 1;
    
    // Check if threshold reached
    if (state >= frequency) {
      state = 0; // Reset counter
      return true;
    }
    
    return false;
  }

  Future<void> showInterstitialAd(BuildContext context) async {
    if (!shouldShowAd()) return;

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
    _countdown = config.adDuration;
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
        height: 400,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(AppStrings.tr(AppStrings.adLabel, lc), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  if (_countdown > 0)
                    Text(
                      '${AppStrings.tr(AppStrings.closeIn, lc)} $_countdown',
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            
            // Ad Content
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1556742049-0cfed4f7a07d?q=80&w=2070&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.tr(AppStrings.sponsoredContent, lc),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.tr(AppStrings.secureInvestmentsTitle, lc),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.tr(AppStrings.removeAdsDesc, lc),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close ad
                              // Could navigate to subs page here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(AppStrings.tr(AppStrings.learnMore, lc)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
