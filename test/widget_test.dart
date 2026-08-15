import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moneyplan_pro/core/config/env_config.dart';
import 'package:moneyplan_pro/core/providers/balance_visibility_provider.dart';
import 'package:moneyplan_pro/core/providers/common_providers.dart';
import 'package:moneyplan_pro/core/services/remote_config_service.dart';
import 'package:moneyplan_pro/main.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    final prefs = await SharedPreferences.getInstance();
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
    final remoteConfigService = RemoteConfigService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          balanceVisibilityProvider.overrideWith(
            (ref) => BalanceVisibilityNotifier(prefs),
          ),
          remoteConfigServiceProvider.overrideWithValue(remoteConfigService),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
