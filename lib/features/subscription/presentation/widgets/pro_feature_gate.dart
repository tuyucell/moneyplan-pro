import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:invest_guide/core/config/providers/app_config_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class ProFeatureGate extends ConsumerWidget {
  final Widget child;
  final Widget? lockedChild;
  final String featureName;

  const ProFeatureGate({
    super.key,
    required this.child,
    this.lockedChild,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Check Remote Config
    final config = ref.watch(appConfigProvider);
    final configKey = _mapFeatureName(featureName);
    final isLocked = config.proFeatures[configKey] ?? true;

    // If feature is not locked by admin, show it
    if (!isLocked) {
      return child;
    }

    // If locked, check if user is pro
    if (isPro) {
      return child;
    }

    return lockedChild ?? _buildDefaultLockedWidget(context, ref, lc);
  }

  String _mapFeatureName(String display) {
    if (display.contains('Analist')) return 'ai_analyst';
    if (display.contains('Simülasyon')) return 'scenario_planner';
    if (display.contains('Karşılaştırma')) return 'investment_comparison';
    return display.toLowerCase().replaceAll(' ', '_');
  }

  Widget _buildDefaultLockedWidget(
      BuildContext context, WidgetRef ref, String lc) {
    return GestureDetector(
      onTap: () => _showUpsellDialog(context, ref, lc),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.amber),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$featureName (Pro)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    AppStrings.tr(AppStrings.unlockProFeature, lc),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showUpsellDialog(BuildContext context, WidgetRef ref, String lc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr(AppStrings.upgradeToProTitle, lc)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '"$featureName" ${AppStrings.tr(AppStrings.upgradeToProDesc, lc)}'),
            const SizedBox(height: 16),
            _ProBenefitItem(
                label: AppStrings.tr(AppStrings.proFeatureAiAnalyst, lc)),
            const SizedBox(height: 8),
            _ProBenefitItem(
                label: AppStrings.tr(AppStrings.proFeatureScenario, lc)),
            const SizedBox(height: 8),
            _ProBenefitItem(
                label: AppStrings.tr(AppStrings.proFeatureUnlimited, lc)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.tr(AppStrings.maybeLater, lc)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(subscriptionProvider.notifier).upgradeToPro();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.tr(AppStrings.proActivated, lc)),
                  backgroundColor: Colors.amber,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: Text(AppStrings.tr(AppStrings.upgradeNow, lc)),
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
        const Icon(Icons.check, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(label,
            style:
                TextStyle(color: AppColors.textPrimary(context), fontSize: 13)),
      ],
    );
  }
}
