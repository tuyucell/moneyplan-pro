import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/features/alerts/models/price_alert.dart';
import 'package:uuid/uuid.dart';

class AlertsNotifier extends StateNotifier<List<PriceAlert>> {
  AlertsNotifier() : super([]) {
    _loadAlerts();
  }

  static const String _prefsKey = 'user_price_alerts';

  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((e) => PriceAlert.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading alerts: $e');
    }
  }

  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving alerts: $e');
    }
  }

  Future<void> addAlert({
    required String assetId,
    required String symbol,
    required String name,
    required double targetPrice,
    required bool isAbove,
  }) async {
    final newAlert = PriceAlert(
      id: const Uuid().v4(),
      assetId: assetId,
      symbol: symbol,
      name: name,
      targetPrice: targetPrice,
      isAbove: isAbove,
    );
    state = [...state, newAlert];
    await _saveAlerts();
  }

  Future<void> removeAlert(String id) async {
    state = state.where((element) => element.id != id).toList();
    await _saveAlerts();
  }

  Future<void> toggleAlert(String id, bool isActive) async {
    state = [
      for (final alert in state)
        if (alert.id == id) alert.copyWith(isActive: isActive) else alert
    ];
    await _saveAlerts();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<PriceAlert>>((ref) {
  return AlertsNotifier();
});
