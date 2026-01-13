import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/features/wallet/models/portfolio_asset.dart';

class PortfolioNotifier extends StateNotifier<List<PortfolioAsset>> {
  static const String _storageKey = 'user_portfolio_assets';

  PortfolioNotifier() : super([]) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      state = jsonList.map((e) => PortfolioAsset.fromJson(e)).toList();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> addOrUpdateAsset(PortfolioAsset asset) async {
    final index = state.indexWhere((e) => e.symbol == asset.symbol);
    if (index >= 0) {
      // Update existing
      final existing = state[index];
      final newUnits = existing.units + asset.units;
      // Weighted average cost calculation
      final newAvgCost = ((existing.units * existing.averageCost) + (asset.units * asset.averageCost)) / newUnits;
      
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) 
            existing.copyWith(units: newUnits, averageCost: newAvgCost)
          else 
            state[i]
      ];
    } else {
      // Add new
      state = [...state, asset];
    }
    await _saveToPrefs();
  }

  Future<void> removeAsset(String symbol) async {
    state = state.where((e) => e.symbol != symbol).toList();
    await _saveToPrefs();
  }

  Future<void> updateAssetUnits(String symbol, double units) async {
    state = [
      for (final asset in state)
        if (asset.symbol == symbol) asset.copyWith(units: units) else asset
    ];
    await _saveToPrefs();
  }

  Future<void> updateAssetDetails(String symbol, double units, double averageCost) async {
    state = [
      for (final asset in state)
        if (asset.symbol == symbol) asset.copyWith(units: units, averageCost: averageCost) else asset
    ];
    await _saveToPrefs();
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, List<PortfolioAsset>>((ref) {
  return PortfolioNotifier();
});
