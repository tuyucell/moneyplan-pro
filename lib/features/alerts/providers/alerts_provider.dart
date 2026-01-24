import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/features/alerts/models/price_alert.dart';
import 'package:invest_guide/services/api/supabase_service.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';

class AlertsNotifier extends StateNotifier<List<PriceAlert>> {
  AlertsNotifier() : super([]) {
    _loadAlerts();
  }

  static const String _prefsKey = 'user_price_alerts';
  final _client = SupabaseService.client;

  Future<void> _loadAlerts() async {
    try {
      // 1. Load from local cache first for instant UI
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((e) => PriceAlert.fromJson(e)).toList();
      }

      // 2. Sync with Supabase if logged in
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final response = await _client
            .from('price_alerts')
            .select('*')
            .eq('user_id', currentUser.id)
            .order('created_at', ascending: false);

        final remoteAlerts = (response as List).map((json) {
          return PriceAlert(
            id: json['id'],
            assetId: json['asset_id'],
            symbol: json['symbol'],
            name: json['asset_name'],
            targetPrice: (json['target_price'] as num).toDouble(),
            isAbove: json['is_above'],
            isActive: json['is_active'],
            createdAt: DateTime.parse(json['created_at']),
            lastTriggeredAt: json['last_triggered_at'] != null
                ? DateTime.parse(json['last_triggered_at'])
                : null,
          );
        }).toList();

        state = remoteAlerts;
        await _saveLocally();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  Future<void> _saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving alerts locally: $e');
    }
  }

  Future<void> addAlert({
    required String assetId,
    required String symbol,
    required String name,
    required double targetPrice,
    required bool isAbove,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return;

      final response = await _client
          .from('price_alerts')
          .insert({
            'user_id': currentUser.id,
            'asset_id': assetId,
            'asset_name': name,
            'symbol': symbol,
            'target_price': targetPrice,
            'is_above': isAbove,
            'is_active': true,
          })
          .select()
          .single();

      final newAlert = PriceAlert(
        id: response['id'],
        assetId: response['asset_id'],
        symbol: response['symbol'],
        name: response['asset_name'],
        targetPrice: (response['target_price'] as num).toDouble(),
        isAbove: response['is_above'],
        isActive: response['is_active'],
        createdAt: DateTime.parse(response['created_at']),
      );

      state = [newAlert, ...state];
      await _saveLocally();
    } catch (e) {
      debugPrint('Error adding alert: $e');
    }
  }

  Future<void> removeAlert(String id) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        await _client.from('price_alerts').delete().eq('id', id);
      }
      state = state.where((element) => element.id != id).toList();
      await _saveLocally();
    } catch (e) {
      debugPrint('Error removing alert: $e');
    }
  }

  Future<void> toggleAlert(String id, bool isActive) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        await _client
            .from('price_alerts')
            .update({'is_active': isActive}).eq('id', id);
      }
      state = [
        for (final alert in state)
          if (alert.id == id) alert.copyWith(isActive: isActive) else alert
      ];
      await _saveLocally();
    } catch (e) {
      debugPrint('Error toggling alert: $e');
    }
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, List<PriceAlert>>((ref) {
  // Re-initialize when auth state changes (login/logout)
  ref.watch(authStateProvider);
  return AlertsNotifier();
});
