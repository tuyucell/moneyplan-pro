import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/providers/common_providers.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyRate {
  final String code;
  final String symbol;
  final double rateToTRY;

  const CurrencyRate({
    required this.code,
    required this.symbol,
    required this.rateToTRY,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
        'rateToTRY': rateToTRY,
      };

  factory CurrencyRate.fromJson(Map<String, dynamic> json) {
    return CurrencyRate(
      code: json['code'] as String,
      symbol: json['symbol'] as String? ?? json['code'] as String,
      rateToTRY: (json['rateToTRY'] as num).toDouble(),
    );
  }
}

class CurrencyService extends ChangeNotifier {
  CurrencyService(this._preferences) {
    _loadCachedRates();
  }

  static const _cacheKey = 'tcmb_reference_rates_v1';
  static const _symbolMap = {
    'TRY': '₺',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'CHF': 'CHF',
    'JPY': '¥',
    'CAD': r'C$',
    'AUD': r'A$',
    'DKK': 'DKK',
    'SEK': 'SEK',
    'NOK': 'NOK',
    'SAR': 'SAR',
  };

  final SharedPreferences _preferences;
  final Map<String, CurrencyRate> _rates = {
    'TRY': const CurrencyRate(code: 'TRY', symbol: '₺', rateToTRY: 1),
  };

  bool _isRefreshing = false;
  DateTime? _rateDate;
  DateTime? _fetchedAt;
  bool _isStale = true;

  bool get hasReferenceRates => _rates.length > 1;
  bool get isRefreshing => _isRefreshing;
  DateTime? get rateDate => _rateDate;
  DateTime? get fetchedAt => _fetchedAt;
  bool get isStale => _isStale;
  String get source => 'TCMB';

  void _loadCachedRates() {
    final raw = _preferences.getString(_cacheKey);
    if (raw == null) return;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final cachedRates = (payload['rates'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => CurrencyRate.fromJson(
                Map<String, dynamic>.from(item),
              ));
      for (final rate in cachedRates) {
        if (rate.rateToTRY > 0) _rates[rate.code] = rate;
      }
      _rateDate = DateTime.tryParse(payload['rateDate'] as String? ?? '');
      _fetchedAt = DateTime.tryParse(payload['fetchedAt'] as String? ?? '');
      _isStale = true;
    } catch (error) {
      debugPrint('Currency cache parse error: $error');
    }
  }

  Future<bool> refresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    notifyListeners();
    try {
      final payload = await MoneyPlanProApi.getTcmbReferenceRates();
      if (payload == null) return false;
      final incoming = (payload['rates'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw));
      final parsed = <String, CurrencyRate>{};
      for (final item in incoming) {
        final code = item['code'] as String? ?? item['symbol'] as String?;
        final rate = (item['rate_to_try'] as num?)?.toDouble();
        if (code == null || rate == null || rate <= 0) continue;
        parsed[code] = CurrencyRate(
          code: code,
          symbol: _symbolMap[code] ?? code,
          rateToTRY: rate,
        );
      }
      if (!parsed.containsKey('TRY')) {
        parsed['TRY'] =
            const CurrencyRate(code: 'TRY', symbol: '₺', rateToTRY: 1);
      }
      if (parsed.length <= 1) return false;

      _rates
        ..clear()
        ..addAll(parsed);
      _rateDate = DateTime.tryParse(payload['rate_date'] as String? ?? '');
      _fetchedAt = DateTime.tryParse(payload['fetched_at'] as String? ?? '');
      _isStale = payload['stale'] as bool? ?? false;
      await _preferences.setString(
        _cacheKey,
        jsonEncode({
          'rateDate': _rateDate?.toIso8601String(),
          'fetchedAt': _fetchedAt?.toIso8601String(),
          'rates': _rates.values.map((rate) => rate.toJson()).toList(),
        }),
      );
      return true;
    } catch (error) {
      debugPrint('Currency refresh error: $error');
      return false;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  double convertToTRY(double amount, String fromCurrency) {
    if (fromCurrency == 'TRY') return amount;
    final rate = _rates[fromCurrency]?.rateToTRY;
    // Never present an invented 1:1 conversion while the first official rate
    // is loading. Cached values remain available offline after first sync.
    return rate == null ? 0 : amount * rate;
  }

  double? rateToTRY(String currencyCode) {
    if (currencyCode == 'TRY') return 1;
    return _rates[currencyCode]?.rateToTRY;
  }

  double convertFromTRY(double amountInTRY, String toCurrency) {
    if (toCurrency == 'TRY') return amountInTRY;
    final rate = _rates[toCurrency]?.rateToTRY;
    return rate == null || rate <= 0 ? 0 : amountInTRY / rate;
  }

  String getSymbol(String code) => _symbolMap[code] ?? code;

  List<String> getAvailableCurrencies() {
    final preferred = ['TRY', 'USD', 'EUR', 'GBP'];
    final available = _rates.keys.toSet();
    available.removeAll(preferred);
    final additional = available.toList()..sort();
    return [...preferred, ...additional];
  }
}

final currencyServiceProvider = ChangeNotifierProvider<CurrencyService>((ref) {
  final service = CurrencyService(ref.watch(sharedPreferencesProvider));
  unawaited(service.refresh());
  return service;
});

final financeDisplayCurrencyProvider = StateProvider<String>((ref) => 'TRY');
final investDisplayCurrencyProvider = StateProvider<String>((ref) => 'TRY');
