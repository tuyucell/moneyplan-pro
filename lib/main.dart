import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invest_guide/core/services/push_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invest_guide/core/theme/app_theme.dart';
import 'package:invest_guide/core/constants/app_constants.dart';
import 'package:invest_guide/core/router/app_router.dart';
import 'package:invest_guide/core/providers/theme_provider.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/services/api/supabase_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:invest_guide/core/providers/navigation_provider.dart';
import 'package:invest_guide/core/providers/balance_visibility_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/features/alerts/services/price_alert_monitor.dart';
import 'package:invest_guide/core/services/remote_config_service.dart';
import 'package:invest_guide/core/providers/common_providers.dart';
import 'package:invest_guide/core/services/data_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('APP_START: main() started');

  try {
    // 1. Initialize Hive
    debugPrint('APP_START: Initializing Hive...');
    await Hive.initFlutter();

    // 2. Initialize Supabase
    debugPrint('APP_START: Initializing Supabase...');
    await SupabaseService.initialize();

    // 3. Initialize SharedPreferences
    debugPrint('APP_START: Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();

    // 4. Initialize Non-blocking services
    debugPrint('APP_START: Starting non-blocking initializations...');

    // Set App Group ID (Try-catch to prevent splash crash)
    try {
      await HomeWidget.setAppGroupId('group.com.turgayyucel.investguide');
    } catch (e) {
      debugPrint('APP_START_ERROR: HomeWidget GroupID failed: $e');
    }

    // Initialize OneSignal
    unawaited(PushNotificationService().initialize());

    // Initialize Remote Config Service
    final remoteConfigService = RemoteConfigService(prefs);
    unawaited(remoteConfigService.fetchFlags());

    debugPrint('APP_START: All critical initializations done. Running app...');

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          balanceVisibilityProvider
              .overrideWith((ref) => BalanceVisibilityNotifier(prefs)),
          remoteConfigServiceProvider.overrideWithValue(remoteConfigService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('APP_START_CRITICAL_ERROR: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Configuration Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(e.toString(), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupWidgetLaunch();
    _startPriceAlertMonitoring();
  }

  void _startPriceAlertMonitoring() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(priceAlertMonitorProvider).start();
      }
    });
  }

  void _setupWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleWidgetLaunch(uri);
    });
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleWidgetLaunch(uri);
    });
  }

  Future<void> _handleWidgetLaunch(Uri uri) async {
    debugPrint('WIDGET_LOG: Received URI: $uri');
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Data Sync Service
    ref.watch(syncManagerProvider);

    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: snackbarKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: language.locale,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
    );
  }
}
