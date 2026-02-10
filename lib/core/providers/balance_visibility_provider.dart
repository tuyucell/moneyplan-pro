import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceVisibilityNotifier extends StateNotifier<bool> {
  static const _key = 'balance_visibility';
  final SharedPreferences _prefs;

  BalanceVisibilityNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }
}

final balanceVisibilityProvider = StateNotifierProvider<BalanceVisibilityNotifier, bool>((ref) {
  throw UnimplementedError(); // Initialized in main.dart
});

// For easier masking logic
extension BalanceMasking on String {
  String mask(bool visible) => visible ? this : '••••••';
}
