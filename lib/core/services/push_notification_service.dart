import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:moneyplan_pro/core/config/env_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Remove this line for production
      unawaited(OneSignal.Debug.setLogLevel(OSLogLevel.verbose));

      OneSignal.initialize(EnvConfig.oneSignalAppId);

      // Request permission
      await OneSignal.Notifications.requestPermission(true);

      _initialized = true;
      debugPrint('PushNotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService: Initialization failed: $e');
    }
  }

  Future<void> login(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('PushNotificationService: User logged in with ID: $userId');
    } catch (e) {
      debugPrint('PushNotificationService: Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('PushNotificationService: User logged out');
    } catch (e) {
      debugPrint('PushNotificationService: Logout failed: $e');
    }
  }
}
