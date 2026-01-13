import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/features/wallet/models/savings_goal.dart';

class SavingsGoalNotifier extends StateNotifier<List<SavingsGoal>> {
  SavingsGoalNotifier() : super([]) {
    _loadGoals();
  }

  static const String _prefsKey = 'user_savings_goals';

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((e) => SavingsGoal.fromJson(e)).toList();
      } else {
        // Initial Mock Data to motivate user
        state = [
          SavingsGoal.create(
            name: 'Yaz Tatili',
            targetAmount: 50000,
            currentAmount: 15400,
            colorValue: 0xFFFFA726, // Orange
          ),
          SavingsGoal.create(
            name: 'Yeni Araba',
            targetAmount: 1200000,
            currentAmount: 340000,
            colorValue: 0xFF29B6F6, // Light Blue
          ),
        ];
        await _saveGoals();
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
      state = [];
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  Future<void> addGoal(String name, double target, int color,
      {double currentAmount = 0,
      double? interestRate,
      DateTime? maturityDate,
      String currencyCode = 'TRY'}) async {
    final newGoal = SavingsGoal.create(
      name: name,
      targetAmount: target,
      currentAmount: currentAmount,
      colorValue: color,
      interestRate: interestRate,
      maturityDate: maturityDate,
      currencyCode: currencyCode,
    );
    state = [...state, newGoal];
    await _saveGoals();
  }

  Future<void> updateGoalAmount(String id, double newAmount) async {
    state = [
      for (final goal in state)
        if (goal.id == id) goal.copyWith(currentAmount: newAmount) else goal
    ];
    await _saveGoals();
  }

  Future<void> updateGoalDetails(String id,
      {required String name,
      required double targetAmount,
      required int colorValue}) async {
    state = [
      for (final goal in state)
        if (goal.id == id)
          goal.copyWith(
            name: name,
            targetAmount: targetAmount,
            colorValue: colorValue,
          )
        else
          goal
    ];
    await _saveGoals();
  }

  Future<void> deleteGoal(String id) async {
    state = state.where((goal) => goal.id != id).toList();
    await _saveGoals();
  }
}

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalNotifier, List<SavingsGoal>>((ref) {
  return SavingsGoalNotifier();
});
