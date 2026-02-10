import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
  }

  Future<void> showPriceAlert({
    required String symbol,
    required double targetPrice,
    required double currentPrice,
    required bool isAbove,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Fiyat Alarmları',
      channelDescription: 'Hedef fiyata ulaşıldığında bildirim gönderir',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final direction = isAbove ? 'üstüne çıktı' : 'altına düştü';
    final title = '🎯 $symbol Hedef Fiyata Ulaştı!';
    final body =
        '\$${currentPrice.toStringAsFixed(2)} - Hedef: \$${targetPrice.toStringAsFixed(2)} $direction';

    await _notifications.show(
      symbol.hashCode, // Unique ID per symbol
      title,
      body,
      details,
      payload: symbol,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
