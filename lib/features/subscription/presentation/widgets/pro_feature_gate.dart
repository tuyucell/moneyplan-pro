import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/core/config/providers/app_config_provider.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/subscription/presentation/pages/subscription_page.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/feature_usage_provider.dart';
import 'package:moneyplan_pro/services/analytics/analytics_service.dart';

class ProFeatureGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedChild;
  final String featureName;
  final bool isFullPage;

  const ProFeatureGate({
    super.key,
    required this.child,
    this.lockedChild,
    required this.featureName,
    this.isFullPage = false,
  });

  static void showUpsell(BuildContext context, String featureName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ProFeatureGate(
            featureName: featureName,
            isFullPage: true,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // 1. If user is PRO, always allow
    if (isPro) {
      return child;
    }

    // 2. Check Remote Config (if disabled by admin globally)
    final config = ref.watch(appConfigProvider);
    final configKey = _mapFeatureName(featureName);
    final isGloballyLocked = config.proFeatures[configKey] ?? true;

    if (!isGloballyLocked) {
      return child;
    }

    // 3. Daily Free Usage Logic
    final lockedAsync = ref.watch(featureLockedProvider(configKey));

    return lockedAsync.when(
      data: (isLocked) {
        if (!isLocked) {
          // Track usage if it's a full page gate (counting view as usage)
          if (isFullPage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(featureUsageProvider).trackUsage(configKey);
              // Analytics: Free use
              ref.read(analyticsServiceProvider).logEvent(
                    name: 'pro_feature_free_use',
                    category: 'monetization',
                    properties: {'feature': featureName},
                    screenName: 'ProFeatureGate',
                  );
            });
          }
          return child;
        }

        // If locked (run out of free uses)
        if (lockedChild != null) return lockedChild!;

        // Analytics: Upsell View
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(analyticsServiceProvider).logEvent(
                name: 'pro_upsell_view',
                category: 'monetization',
                properties: {
                  'feature': featureName,
                  'type': isFullPage ? 'full_page' : 'inline'
                },
                screenName: 'ProFeatureGate',
              );
        });

        return isFullPage
            ? _buildFullPageLockedWidget(context, ref, lc)
            : _buildDefaultLockedWidget(context, ref, lc);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => child, // Fallback to content on error
    );
  }

  String _mapFeatureName(String display) {
    if (display.contains('Analist')) return 'ai_analyst';
    if (display.contains('Simülasyon')) return 'scenario_planner';
    if (display.contains('Karşılaştırma')) return 'investment_comparison';
    if (display.contains('Ekstre')) {
      return 'ai_analyst'; // Mapping to analyst for now
    }
    return display.toLowerCase().replaceAll(' ', '_');
  }

  Widget _buildFullPageLockedWidget(
      BuildContext context, WidgetRef ref, String lc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                size: 64, color: Colors.amber),
          ),
          const SizedBox(height: 32),
          Text(
            '$featureName (Pro)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.tr(AppStrings.upgradeToProDesc, lc),
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildFeatureList(context, lc),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleUpgrade(context, ref, lc),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                AppStrings.tr(AppStrings.upgradeNow, lc),
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppStrings.tr(AppStrings.maybeLater, lc),
              style: TextStyle(color: AppColors.textTertiary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context, String lc) {
    return Column(
      children: [
        _ProBenefitItem(
            label: AppStrings.tr(AppStrings.proFeatureAiAnalyst, lc)),
        const SizedBox(height: 12),
        _ProBenefitItem(
            label: AppStrings.tr(AppStrings.proFeatureScenario, lc)),
        const SizedBox(height: 12),
        _ProBenefitItem(
            label: AppStrings.tr(AppStrings.proFeatureUnlimited, lc)),
      ],
    );
  }

  void _handleUpgrade(BuildContext context, WidgetRef ref, String lc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPage()),
    );
  }

  Widget _buildDefaultLockedWidget(
      BuildContext context, WidgetRef ref, String lc) {
    return GestureDetector(
      onTap: () => _showUpsellDialog(context, ref, lc),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.border(context).withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_person_rounded,
                  color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    featureName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.tr(AppStrings.unlockProFeature, lc),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.amber, size: 14),
          ],
        ),
      ),
    );
  }

  void _showUpsellDialog(BuildContext context, WidgetRef ref, String lc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber),
            const SizedBox(width: 12),
            Text(
              AppStrings.tr(AppStrings.upgradeToProTitle, lc),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              '"$featureName" ${AppStrings.tr(AppStrings.upgradeToProDesc, lc)}',
              style: TextStyle(
                  color: AppColors.textSecondary(context), height: 1.4),
            ),
            const SizedBox(height: 24),
            _buildFeatureList(context, lc),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr(AppStrings.maybeLater, lc)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleUpgrade(context, ref, lc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppStrings.tr(AppStrings.upgradeNow, lc),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProBenefitItem extends StatelessWidget {
  final String label;
  const _ProBenefitItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
