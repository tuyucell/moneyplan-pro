import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:invest_guide/services/analytics/analytics_service.dart';
import 'dart:math';

/// Banner Ad Widget - Shows at top of screens for free users
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({super.key});

  static const _adMessages = [
    {'title': 'Yüksek Faiz Fırsatı', 'subtitle': '%45 yıllık getiri!'},
    {'title': 'Kripto Yatırımı', 'subtitle': 'Bitcoin 100K\'da'},
    {'title': 'Altın Hesabı', 'subtitle': 'Komisyonsuz al-sat'},
    {'title': 'Hisse Senedi Fırsatı', 'subtitle': '%25 indirimde'},
    {'title': 'Gayrimenkul Fonu', 'subtitle': 'Aylık kira geliri'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Never show to Pro users
    final isPro = ref.watch(isProUserProvider);
    if (isPro) return const SizedBox.shrink();

    // Random ad message
    final ad = _adMessages[Random().nextInt(_adMessages.length)];

    // Ad impression tracking (one-time per widget build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
            name: 'ad_impression',
            category: 'monetization',
            properties: {'ad_title': ad['title']},
            screenName: 'Global',
          );
    });

    return GestureDetector(
      onTap: () {
        ref.read(analyticsServiceProvider).logEvent(
              name: 'ad_click',
              category: 'monetization',
              properties: {'ad_title': ad['title']},
              screenName: 'Global',
            );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              Colors.amber.withValues(alpha: 0.1),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Ad indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade600, width: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'REKLAM',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Ad icon
            Icon(
              Icons.campaign_outlined,
              size: 16,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 6),

            // Ad content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ad['title']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ad['subtitle']!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'İncele',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
