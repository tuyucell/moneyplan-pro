import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PushAuthorizationStatus {
  notDetermined,
  denied,
  authorized,
  provisional,
  unsupported,
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const _channel = MethodChannel('pro.moneyplan.app/push');
  bool _initialized = false;
  bool _enabled = false;
  String? _userId;
  String? _deviceToken;
  static const _preferenceKey = 'push_notifications_enabled';

  Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_preferenceKey) ?? false;

      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onToken' && call.arguments is String) {
          _deviceToken = call.arguments as String;
          await _registerCurrentToken();
        } else if (call.method == 'onRegistrationError') {
          debugPrint('Native push registration failed: ${call.arguments}');
        }
      });

      final status = await authorizationStatus();
      if (_enabled &&
          (status == PushAuthorizationStatus.authorized ||
              status == PushAuthorizationStatus.provisional)) {
        await _channel.invokeMethod<void>('registerToken');
      }
      _initialized = true;
      await _registerCurrentToken();
      debugPrint('PushNotificationService: Native APNs configured');
    } catch (e) {
      debugPrint('PushNotificationService: Native initialization failed: $e');
    }
  }

  Future<void> login(String userId) async {
    _userId = userId;
    await initialize();
    await _registerCurrentToken();
  }

  Future<PushAuthorizationStatus> authorizationStatus() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return PushAuthorizationStatus.unsupported;
    }
    try {
      final raw = await _channel.invokeMethod<String>('getAuthorizationStatus');
      return switch (raw) {
        'authorized' => PushAuthorizationStatus.authorized,
        'provisional' => PushAuthorizationStatus.provisional,
        'denied' => PushAuthorizationStatus.denied,
        _ => PushAuthorizationStatus.notDetermined,
      };
    } catch (_) {
      return PushAuthorizationStatus.unsupported;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_preferenceKey) ?? false;
    final status = await authorizationStatus();
    return _enabled &&
        (status == PushAuthorizationStatus.authorized ||
            status == PushAuthorizationStatus.provisional);
  }

  /// Call only after the user accepts the in-app explanation.
  Future<bool> enable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    await initialize();

    try {
      final granted =
          await _channel.invokeMethod<bool>('requestPermission') ?? false;
      if (!granted) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preferenceKey, true);
      _enabled = true;
      await _channel.invokeMethod<void>('registerToken');
      await _registerCurrentToken();
      return true;
    } catch (e) {
      debugPrint('PushNotificationService: Permission request failed: $e');
      return false;
    }
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, false);
    _enabled = false;
    await _deactivateCurrentToken();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _channel.invokeMethod<void>('unregisterToken');
    }
  }

  Future<void> openSystemSettings() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _channel.invokeMethod<void>('openSettings');
    }
  }

  Future<void> _registerCurrentToken() async {
    if (!_enabled) return;
    final token = _deviceToken;
    final userId = _userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (token == null || userId == null) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await Supabase.instance.client.from('push_devices').upsert(
        {
          'user_id': userId,
          'platform': 'ios',
          'token': token,
          'environment': kReleaseMode ? 'production' : 'sandbox',
          'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
          'is_active': true,
          'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'platform,token',
      );
      debugPrint('PushNotificationService: APNs token registered');
    } catch (e) {
      debugPrint('PushNotificationService: Token registration failed: $e');
    }
  }

  Future<void> _deactivateCurrentToken() async {
    final token = _deviceToken;
    final userId = _userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (token == null || userId == null) return;

    try {
      await Supabase.instance.client
          .from('push_devices')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('platform', 'ios')
          .eq('token', token);
    } catch (e) {
      debugPrint('PushNotificationService: Token deactivation failed: $e');
    }
  }

  Future<void> logout() async {
    final token = _deviceToken;
    final userId = _userId;
    if (token != null && userId != null) {
      try {
        await Supabase.instance.client
            .from('push_devices')
            .delete()
            .eq('user_id', userId)
            .eq('platform', 'ios')
            .eq('token', token);
      } catch (e) {
        debugPrint('PushNotificationService: Token deactivation failed: $e');
      }
    }
    _userId = null;
  }
}
