import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/alerts/providers/alerts_provider.dart';
import 'package:moneyplan_pro/features/watchlist/providers/asset_cache_provider.dart';
import 'package:moneyplan_pro/core/services/notification_service.dart';

class PriceAlertMonitor {
  final Ref ref;
  Timer? _timer;
  final Set<String> _triggeredAlerts = {};
  final NotificationService _notificationService = NotificationService();

  PriceAlertMonitor(this.ref);

  Future<void> start() async {
    await _notificationService.initialize();

    // Check immediately
    await _checkAlerts();

    // Then check every 10 seconds (app is open anyway)
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkAlerts();
    });

    debugPrint('Price Alert Monitor started (checking every 10 seconds)');
  }

  Future<void> _checkAlerts() async {
    try {
      final alerts = ref.read(alertsProvider);
      final activeAlerts = alerts.where((a) => a.isActive).toList();

      if (activeAlerts.isEmpty) return;

      for (final alert in activeAlerts) {
        // Skip if already triggered in this session
        if (_triggeredAlerts.contains(alert.id)) continue;

        // Get current price
        final assetAsync = ref.read(assetProvider(alert.assetId));
        final currentPrice = assetAsync.value?.currentPriceUsd;

        if (currentPrice == null) continue;

        // Check if alert condition is met
        var isTriggered = false;
        if (alert.isAbove && currentPrice >= alert.targetPrice) {
          isTriggered = true;
        } else if (!alert.isAbove && currentPrice <= alert.targetPrice) {
          isTriggered = true;
        }

        if (isTriggered) {
          // Send notification
          await _notificationService.showPriceAlert(
            symbol: alert.symbol,
            targetPrice: alert.targetPrice,
            currentPrice: currentPrice,
            isAbove: alert.isAbove,
          );

          // Mark as triggered to avoid spam
          _triggeredAlerts.add(alert.id);

          // Optionally disable the alert after triggering
          await ref.read(alertsProvider.notifier).toggleAlert(alert.id, false);

          debugPrint(
              'Alert triggered: ${alert.symbol} at \$${currentPrice.toStringAsFixed(2)}');
        }
      }
    } catch (e) {
      debugPrint('Error checking alerts: $e');
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _triggeredAlerts.clear();
    debugPrint('Price Alert Monitor stopped');
  }

  void reset() {
    _triggeredAlerts.clear();
  }
}

final priceAlertMonitorProvider = Provider<PriceAlertMonitor>((ref) {
  final monitor = PriceAlertMonitor(ref);
  ref.onDispose(() => monitor.stop());
  return monitor;
});
