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
      loading: () {
        // While loading, show the child (fail open)
        // This prevents blocking users if network is slow
        return child;
      },
      error: (_, __) {
        // On error, show the child (fail open)
        return child;
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
    // On error, default to allowing access
    return true;
  }
}
