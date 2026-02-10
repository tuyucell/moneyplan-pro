import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  static const String _pensionFundKey = 'favorite_pension_funds';
  static const String _insuranceKey = 'favorite_insurance_products';

  SharedPreferences? _prefsCache;
  bool _isInitialized = false;

  FavoritesNotifier() : super([]) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    if (_isInitialized) return;

    try {
      _prefsCache = await SharedPreferences.getInstance();
      _loadFavorites();
      _isInitialized = true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error initializing favorites: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = [];
    }
  }

  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  void _loadFavorites() {
    if (_prefsCache == null) return;

    try {
      final pensionFunds = _prefsCache!.getStringList(_pensionFundKey) ?? [];
      final insurance = _prefsCache!.getStringList(_insuranceKey) ?? [];

      state = [...pensionFunds, ...insurance];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error loading favorites: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = [];
    }
  }

  Future<void> _saveFavorites(String key, List<String> items) async {
    try {
      final prefs = await _prefs;
      await prefs.setStringList(key, items);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error saving favorites: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // Pension fund favorites
  Future<void> togglePensionFund(String fundId) async {
    await _initPrefs();

    final prefs = await _prefs;
    final currentFunds = prefs.getStringList(_pensionFundKey) ?? [];

    if (currentFunds.contains(fundId)) {
      currentFunds.remove(fundId);
    } else {
      currentFunds.add(fundId);
    }

    await _saveFavorites(_pensionFundKey, currentFunds);
    _loadFavorites();
  }

  bool isPensionFundFavorite(String fundId) {
    if (!_isInitialized || _prefsCache == null) return false;
    final currentFunds = _prefsCache!.getStringList(_pensionFundKey) ?? [];
    return currentFunds.contains(fundId);
  }

  List<String> getPensionFundFavorites() {
    if (!_isInitialized || _prefsCache == null) return [];
    return _prefsCache!.getStringList(_pensionFundKey) ?? [];
  }

  // Insurance product favorites
  Future<void> toggleInsuranceProduct(String productId) async {
    await _initPrefs();

    final prefs = await _prefs;
    final currentProducts = prefs.getStringList(_insuranceKey) ?? [];

    if (currentProducts.contains(productId)) {
      currentProducts.remove(productId);
    } else {
      currentProducts.add(productId);
    }

    await _saveFavorites(_insuranceKey, currentProducts);
    _loadFavorites();
  }

  bool isInsuranceProductFavorite(String productId) {
    if (!_isInitialized || _prefsCache == null) return false;
    final currentProducts = _prefsCache!.getStringList(_insuranceKey) ?? [];
    return currentProducts.contains(productId);
  }

  List<String> getInsuranceProductFavorites() {
    if (!_isInitialized || _prefsCache == null) return [];
    return _prefsCache!.getStringList(_insuranceKey) ?? [];
  }

  // Clear all favorites
  Future<void> clearAll() async {
    await _initPrefs();
    final prefs = await _prefs;

    await prefs.remove(_pensionFundKey);
    await prefs.remove(_insuranceKey);

    _loadFavorites();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<String>>((ref) {
  return FavoritesNotifier();
});

// Provider to check if a pension fund is favorite
final isPensionFundFavoriteProvider =
    Provider.family<bool, String>((ref, fundId) {
  final notifier = ref.watch(favoritesProvider.notifier);
  ref.watch(favoritesProvider); // Watch for changes
  return notifier.isPensionFundFavorite(fundId);
});

// Provider to check if an insurance product is favorite
final isInsuranceProductFavoriteProvider =
    Provider.family<bool, String>((ref, productId) {
  final notifier = ref.watch(favoritesProvider.notifier);
  ref.watch(favoritesProvider); // Watch for changes
  return notifier.isInsuranceProductFavorite(productId);
});
