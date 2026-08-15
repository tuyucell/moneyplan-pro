import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses the last verified TCMB cache instead of static example rates',
      () async {
    SharedPreferences.setMockInitialValues({
      'tcmb_reference_rates_v1': jsonEncode({
        'rateDate': '2026-08-15T00:00:00.000',
        'fetchedAt': '2026-08-15T16:45:00.000+03:00',
        'rates': [
          {'code': 'TRY', 'symbol': '₺', 'rateToTRY': 1.0},
          {'code': 'USD', 'symbol': r'$', 'rateToTRY': 40.1},
          {'code': 'EUR', 'symbol': '€', 'rateToTRY': 44.2},
        ],
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final service = CurrencyService(prefs);

    expect(service.convertToTRY(100, 'USD'), 4010);
    expect(service.convertFromTRY(4420, 'EUR'), 100);
    expect(service.rateDate, DateTime(2026, 8, 15));
    expect(service.isStale, isTrue);
  });

  test('does not invent a one-to-one rate when no official cache exists',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = CurrencyService(prefs);

    expect(service.convertToTRY(100, 'USD'), 0);
    expect(service.getAvailableCurrencies(),
        containsAll(['TRY', 'USD', 'EUR', 'GBP']));
  });
}
