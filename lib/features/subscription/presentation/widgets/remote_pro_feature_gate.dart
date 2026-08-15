import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/services/remote_config_service.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/features/subscription/presentation/widgets/pro_feature_gate.dart';

/// Enhanced ProFeatureGate that uses Remote Config
///
/// This widget checks both:
/// 1. Remote Config: Is the feature enabled globally?
/// 2. Local Logic: Does the user have access (PRO or daily limit)?
class RemoteProFeatureGate extends ConsumerWidget {
  static const _failClosedFeatures = {
    'crypto_market_data',
    'live_market_data',
    'gmail_import',
    'ai_features',
    'ai_analyst',
    'investment_wizard',
    'import_statement_ai',
    'email_automation',
  };

  final String featureId;
  final String? featureName;
  final Widget child;
  final Widget? lockedChild;
  final bool isFullPage;

  const RemoteProFeatureGate({
    super.key,
    required this.featureId,
    this.featureName,
    required this.child,
    this.lockedChild,
    this.isFullPage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagAsync = ref.watch(featureFlagProvider(featureId));
    final enabledAsync = ref.watch(featureEnabledProvider(featureId));

    return enabledAsync.when(
      data: (enabled) {
        if (!enabled) return const SizedBox.shrink();
        return flagAsync.when(
          data: (flag) {
            // Feature not found or disabled remotely
            if (flag == null || !flag.isEnabled) {
              return const SizedBox.shrink();
            }

            // Feature is enabled, now check access
            // If it's not a PRO feature, show directly
            if (!flag.isPro) {
              return child;
            }

            // It's a PRO feature, use ProFeatureGate with remote config
            return ProFeatureGate(
              featureName: featureName ?? flag.name,
              isFullPage: isFullPage,
              lockedChild: lockedChild,
              child: child,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => _failClosedFeatures.contains(featureId)
          ? const SizedBox.shrink()
          : child,
      error: (_, __) {
        return _failClosedFeatures.contains(featureId)
            ? const SizedBox.shrink()
            : child;
      },
    );
  }
}

/// Helper function to check if a feature is available
Future<bool> isFeatureAvailable(WidgetRef ref, String featureId) async {
  try {
    final service = ref.read(remoteConfigServiceProvider);
    final isPro = ref.read(isProUserProvider);
    return await service.isFeatureAvailable(featureId, isPro);
  } catch (e) {
    return !RemoteProFeatureGate._failClosedFeatures.contains(featureId);
  }
}
