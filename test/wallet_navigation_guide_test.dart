import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/core/providers/navigation_provider.dart';
import 'package:moneyplan_pro/features/wallet/widgets/wallet_quick_guide.dart';
import 'package:moneyplan_pro/features/wallet/widgets/wallet_selector.dart';

void main() {
  test('wallet is the default bottom navigation destination', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(bottomNavProvider), 1);
  });

  testWidgets('monthly selector returns directly to the current month',
      (tester) async {
    DateTime? selected;
    final now = DateTime.now();
    final previousYear = DateTime(now.year - 1, now.month);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WalletSelector(
              selectedDate: previousYear,
              isYearlyView: false,
              onDateChanged: (date) => selected = date,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bu aya dön'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet-current-period-button')));

    expect(selected?.year, now.year);
    expect(selected?.month, now.month);
  });

  testWidgets('yearly selector returns directly to the current year',
      (tester) async {
    DateTime? selected;
    final now = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WalletSelector(
              selectedDate: DateTime(now.year + 2),
              isYearlyView: true,
              onDateChanged: (date) => selected = date,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bu yıla dön'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet-current-period-button')));

    expect(selected?.year, now.year);
  });

  testWidgets('wallet guide is short, navigable, and dismissible',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WalletQuickGuide(languageCode: 'tr'),
        ),
      ),
    );

    expect(find.text('30 saniyelik cüzdan rehberi'), findsOneWidget);
    expect(find.text('Gelir veya gider ekle'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wallet-guide-next')));
    await tester.pumpAndSettle();
    expect(find.text('Tek seferlik mi, düzenli mi?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wallet-guide-next')));
    await tester.pumpAndSettle();
    expect(find.text('Kart ve KMH bilgilerini yönet'), findsOneWidget);
    expect(find.text('Anladım, başlayalım'), findsOneWidget);
  });
}
