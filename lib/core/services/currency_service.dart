import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyRate {
  final String code;
  final String symbol;
  final double rateToTRY;

  CurrencyRate({
    required this.code,
    required this.symbol,
    required this.rateToTRY,
  });
}

class CurrencyService {
  // Mock rates - in a real app, these would come from an API
  final Map<String, CurrencyRate> _rates = {
    'TRY': CurrencyRate(code: 'TRY', symbol: '₺', rateToTRY: 1.0),
    'USD': CurrencyRate(code: 'USD', symbol: '\$', rateToTRY: 30.5),
    'EUR': CurrencyRate(code: 'EUR', symbol: '€', rateToTRY: 33.2),
    'GBP': CurrencyRate(code: 'GBP', symbol: '£', rateToTRY: 38.5),
  };

  double convertToTRY(double amount, String fromCurrency) {
    final rate = _rates[fromCurrency]?.rateToTRY ?? 1.0;
    return amount * rate;
  }

  double convertFromTRY(double amountInTRY, String toCurrency) {
    final rate = _rates[toCurrency]?.rateToTRY ?? 1.0;
    return amountInTRY / rate;
  }

  String getSymbol(String code) {
    return _rates[code]?.symbol ?? '₺';
  }

  List<String> getAvailableCurrencies() {
    return _rates.keys.toList();
  }
}

final currencyServiceProvider = Provider((ref) => CurrencyService());

final financeDisplayCurrencyProvider = StateProvider<String>((ref) => 'TRY');
final investDisplayCurrencyProvider = StateProvider<String>((ref) => 'TRY');
