import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Initialize Supabase
    await SupabaseService.initialize();

    // Set App Group ID early for iOS
    await HomeWidget.setAppGroupId('group.com.turgayyucel.invest_guide');

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          balanceVisibilityProvider
              .overrideWith((ref) => BalanceVisibilityNotifier(prefs)),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
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
    // Widget launch check
    _setupWidgetLaunch();
  }

  void _setupWidgetLaunch() {
    // Initially launched
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleWidgetLaunch(uri);
    });
    // Listen for clicks while app is in background/foreground
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleWidgetLaunch(uri);
    });
  }

  Future<void> _handleWidgetLaunch(Uri uri) async {
    // Logic is now EXCLUSIVELY handled in AppRouter via dummy routes.
    // We removed this block to prevent "ghost" transactions (e.g. coffee added when clicking BES funds)
    // caused by HomeWidget's behavior of replaying the initial URI.
    debugPrint('WIDGET_LOG: Received URI: $uri');
  }

  @override
  Widget build(BuildContext context) {
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
