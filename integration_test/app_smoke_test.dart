import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moneyplan_pro/core/router/app_router.dart';
import 'package:moneyplan_pro/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/asset_detail_page.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/economic_calendar_page.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/fund_list_page.dart';
import 'package:moneyplan_pro/features/subscription/presentation/pages/subscription_page.dart';
import 'package:moneyplan_pro/features/wallet/pages/add_transaction_page.dart';
import 'package:moneyplan_pro/features/wallet/widgets/bank_account_editor_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moneyplan_pro/main.dart' as app;

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final attempts = timeout.inMilliseconds ~/ 500;
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Beklenen ekran öğesi $timeout içinde bulunamadı.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clean launch and primary navigation smoke test',
      (WidgetTester tester) async {
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      final normalizedMessage = message?.toLowerCase() ?? '';
      if (normalizedMessage.contains('error') ||
          normalizedMessage.contains('exception') ||
          normalizedMessage.contains('failed')) {
        previousDebugPrint(message, wrapWidth: wrapWidth);
      }
    };
    addTearDown(() => debugPrint = previousDebugPrint);

    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    app.main();
    await pumpUntilFound(tester, find.byType(OnboardingPage));

    expect(find.text('Configuration Error'), findsNothing);
    expect(tester.takeException(), isNull);

    final skipButton = find.byType(TextButton);
    expect(skipButton, findsOneWidget);
    await tester.tap(skipButton);
    await pumpUntilFound(tester, find.byType(BottomNavigationBar));
    expect(tester.takeException(), isNull);

    for (var tabIndex = 0; tabIndex < 5; tabIndex++) {
      var navigationBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      final tabLabel = navigationBar.items[tabIndex].label!;
      final tabFinder = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(tabLabel),
      );

      expect(tabFinder, findsOneWidget);
      await tester.tap(tabFinder);
      await tester.pump(const Duration(seconds: 2));

      navigationBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(navigationBar.currentIndex, tabIndex);
      expect(
        tester.takeException(),
        isNull,
        reason: '$tabLabel sekmesi açılırken Flutter hatası oluştu.',
      );
    }

    Future<void> verifyRoute(String path, Finder pageFinder) async {
      AppRouter.router.go(path);
      await pumpUntilFound(tester, pageFinder);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull,
          reason: '$path ekranı hata verdi.');

      AppRouter.router.go(AppRouter.home);
      await pumpUntilFound(tester, find.byType(BottomNavigationBar));
    }

    await verifyRoute('/funds', find.byType(FundListPage));
    await verifyRoute(AppRouter.calendar, find.byType(EconomicCalendarPage));
    await verifyRoute(
      '/exchanges/bitcoin',
      find.byType(AssetDetailPage),
    );

    AppRouter.router.go('/add-transaction');
    await pumpUntilFound(tester, find.byType(AddTransactionPage));

    await tester.tap(find.text('Ana Kategori').first);
    await pumpUntilFound(tester, find.text('Banka'));
    await tester.tap(find.text('Banka').last);
    await pumpUntilFound(tester, find.text('Kredi Kartı'));
    await tester.tap(find.text('Kredi Kartı').last);
    await pumpUntilFound(tester, find.text('Yeni Kart'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'Kart seçim ekranı açılırken Flutter hatası oluştu.');

    final newCardButton = find.byKey(
      const ValueKey('add_bank_account_from_picker'),
    );
    expect(newCardButton, findsOneWidget);
    await tester.tap(newCardButton);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull,
        reason: 'Yeni kart düğmesi çalışırken Flutter hatası oluştu.');
    await pumpUntilFound(tester, find.byType(BankAccountEditorDialog));
    expect(find.text('Yeni Kart Ekle'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bank_account_interest_rate')),
      findsOneWidget,
    );
    final initialBalanceField =
        find.byKey(const ValueKey('bank_account_initial_balance'));
    await tester.ensureVisible(initialBalanceField);
    await tester.enterText(initialBalanceField, '-12500');
    expect(
      tester.widget<TextFormField>(initialBalanceField).controller!.text,
      '-12500',
    );
    expect(tester.takeException(), isNull,
        reason: 'Yeni kart ekranı açılırken Flutter hatası oluştu.');
    await tester.tap(find.text('İPTAL').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Banka Hesabı').first);
    await pumpUntilFound(tester, find.byTooltip('Kartı düzenle'));
    await tester.pumpAndSettle();

    final editCardButton =
        find.byKey(const ValueKey('edit_bank_account_isbank_cc'));
    expect(editCardButton, findsOneWidget);
    await tester.tap(editCardButton);
    await pumpUntilFound(tester, find.byType(BankAccountEditorDialog));
    expect(find.text('Maximum Kart Ayarları'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'Kart ayarları açılırken Flutter hatası oluştu.');
    await tester.tap(find.text('İPTAL').last);
    await tester.pumpAndSettle();

    AppRouter.router.go(AppRouter.home);
    await pumpUntilFound(tester, find.byType(BottomNavigationBar));

    final walletNavigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    final walletLabel = walletNavigationBar.items[1].label!;
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(walletLabel),
      ),
    );
    await tester.pumpAndSettle();

    final creditCardsSection = find.text('KREDİ KARTLARIM');
    await tester.ensureVisible(creditCardsSection);
    await tester.tap(creditCardsSection);
    await tester.pumpAndSettle();

    final maximumCard = find.text('Maximum Kart').first;
    await tester.ensureVisible(maximumCard);
    await tester.tap(maximumCard);
    await pumpUntilFound(tester, find.text('Hesap Ayarları / Düzenle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hesap Ayarları / Düzenle'));
    await pumpUntilFound(tester, find.byType(BankAccountEditorDialog));
    expect(find.text('Maximum Kart Ayarları'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'Cüzdandaki kart ayarları açılırken Flutter hatası oluştu.');
    await tester.tap(find.text('İPTAL').last);
    await tester.pumpAndSettle();

    var navigationBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    final profileLabel = navigationBar.items[4].label!;
    final profileTab = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(profileLabel),
    );
    await tester.tap(profileTab);
    await tester.pump(const Duration(seconds: 2));

    final upgradeButton = find.text('Yükselt');
    expect(upgradeButton, findsOneWidget);
    await tester.tap(upgradeButton);
    await pumpUntilFound(tester, find.byType(SubscriptionPage));
    await tester.pump(const Duration(seconds: 3));

    expect(
      find.text(
        Platform.isIOS ? 'App Store’da yakında' : 'Google Play’de yakında',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
