import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moneyplan_pro/features/wallet/models/portfolio_asset.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/services/api/supabase_service.dart';

class PortfolioNotifier extends StateNotifier<List<PortfolioAsset>> {
  final String? userId;
  String get _storageKey => userId != null
      ? 'user_portfolio_assets_$userId'
      : 'user_portfolio_assets_guest';

  PortfolioNotifier(this.userId) : super([]) {
    _loadFromPrefs();
  }

  final _client = SupabaseService.client;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = json.decode(data);
        state = jsonList.map((e) => PortfolioAsset.fromJson(e)).toList();
      }

      // Sync with Supabase
      if (userId != null) {
        final List<dynamic> response = await _client
            .from('user_portfolio_assets')
            .select('*')
            .eq('user_id', userId!);

        final remoteAssets = response.map((json) {
          return PortfolioAsset(
            id: json['id'] as String,
            symbol: json['symbol'] as String,
            name: json['name'] as String? ?? '',
            units: (json['quantity'] as num).toDouble(),
            averageCost: (json['average_cost'] as num).toDouble(),
            category: json['type'] as String?,
            currencyCode: json['currency'] as String? ?? 'TRY',
          );
        }).toList();

        state = remoteAssets;
        await _saveToPrefs();
      }
    } catch (e) {
      // ignore
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
      final newAvgCost = ((existing.units * existing.averageCost) +
              (asset.units * asset.averageCost)) /
          newUnits;

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

    // Sync to Supabase
    if (userId != null) {
      final updated = state.firstWhere((e) => e.symbol == asset.symbol);
      await _client.from('user_portfolio_assets').upsert({
        'user_id': userId,
        'symbol': updated.symbol,
        'name': updated.name,
        'quantity': updated.units,
        'average_cost': updated.averageCost,
        'type': updated.category,
        'currency': updated.currencyCode,
      });
    }
  }

  Future<void> removeAsset(String symbol) async {
    state = state.where((e) => e.symbol != symbol).toList();
    await _saveToPrefs();

    // Sync to Supabase
    if (userId != null) {
      await _client
          .from('user_portfolio_assets')
          .delete()
          .eq('user_id', userId!)
          .eq('symbol', symbol);
    }
  }

  Future<void> updateAssetUnits(String symbol, double units) async {
    state = [
      for (final asset in state)
        if (asset.symbol == symbol) asset.copyWith(units: units) else asset
    ];
    await _saveToPrefs();

    // Sync to Supabase
    if (userId != null) {
      final updated = state.firstWhere((e) => e.symbol == symbol);
      await _client.from('user_portfolio_assets').upsert({
        'user_id': userId,
        'symbol': updated.symbol,
        'name': updated.name,
        'quantity': updated.units,
        'average_cost': updated.averageCost,
        'type': updated.category,
        'currency': updated.currencyCode,
      });
    }
  }

  Future<void> updateAssetDetails(
      String symbol, double units, double averageCost) async {
    state = [
      for (final asset in state)
        if (asset.symbol == symbol)
          asset.copyWith(units: units, averageCost: averageCost)
        else
          asset
    ];
    await _saveToPrefs();

    // Sync to Supabase
    if (userId != null) {
      final updated = state.firstWhere((e) => e.symbol == symbol);
      await _client.from('user_portfolio_assets').upsert({
        'user_id': userId,
        'symbol': updated.symbol,
        'name': updated.name,
        'quantity': updated.units,
        'average_cost': updated.averageCost,
        'type': updated.category,
        'currency': updated.currencyCode,
      });
    }
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, List<PortfolioAsset>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  String? userId;
  if (authState is AuthAuthenticated) {
    userId = authState.user.id;
  }
  return PortfolioNotifier(userId);
});
