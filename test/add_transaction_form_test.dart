import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/core/providers/common_providers.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/core/services/remote_config_service.dart';
import 'package:moneyplan_pro/features/wallet/pages/add_transaction_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('amount is grouped and recurring date does not close the form',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currencyServiceProvider.overrideWith(
            (ref) => CurrencyService(preferences),
          ),
          featureEnabledProvider('gmail_import').overrideWith(
            (ref) async => false,
          ),
        ],
        child: const MaterialApp(home: AddTransactionPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '40000');
    await tester.pump();
    expect(find.text('40.000'), findsOneWidget);

    await tester.tap(find.text('GELİR'));
    await tester.pump();
    await tester.tap(find.text('Düzenli Gelir'));
    await tester.pump();

    final endDateField = find.text('Tekrar Bitiş Tarihi (Opsiyonel)');
    await tester.ensureVisible(endDateField);
    await tester.pumpAndSettle();
    await tester.tap(endDateField);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AddTransactionPage), findsOneWidget);
    expect(find.text('KAYDET'), findsOneWidget);
    expect(find.text('40.000'), findsOneWidget);
  });
}
