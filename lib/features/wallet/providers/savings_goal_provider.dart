import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';

class SavingsGoalNotifier extends StateNotifier<List<SavingsGoal>> {
  SavingsGoalNotifier() : super([]) {
    _loadGoals();
  }

  static const String _prefsKey = 'user_savings_goals';
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList
            .map((e) => SavingsGoal.fromJson(Map<String, dynamic>.from(e)))
            .map((goal) => goal.accrueUntil(DateTime.now()))
            .toList();
        await _saveGoals();
      } else {
        state = [];
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
      state = [];
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
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

  Future<SavingsGoal> addGoal(String name, double target, int color,
      {double currentAmount = 0,
      double? interestRate,
      DateTime? maturityDate,
      String currencyCode = 'TRY',
      SavingsPlanType planType = SavingsPlanType.savings,
      double periodicContribution = 0,
      ContributionPeriod contributionPeriod = ContributionPeriod.monthly,
      SavingsFundingMethod fundingMethod = SavingsFundingMethod.cash,
      String? paymentAccountId,
      bool automaticPayment = false,
      bool createWalletExpense = false,
      DateTime? contractStartDate,
      int? contractYears,
      int paymentDay = 1,
      double governmentContributionRate = 20,
      double estimatedAnnualReturnRate = 0,
      double annualProfitShareRate = 0}) async {
    await _initCompleter.future;
    final newGoal = SavingsGoal.create(
      name: name,
      targetAmount: target,
      currentAmount: currentAmount,
      colorValue: color,
      interestRate: interestRate,
      maturityDate: maturityDate,
      currencyCode: currencyCode,
      planType: planType,
      periodicContribution: periodicContribution,
      contributionPeriod: contributionPeriod,
      fundingMethod: fundingMethod,
      paymentAccountId: paymentAccountId,
      automaticPayment: automaticPayment,
      createWalletExpense: createWalletExpense,
      contractStartDate: contractStartDate,
      contractYears: contractYears,
      paymentDay: paymentDay,
      governmentContributionRate: governmentContributionRate,
      estimatedAnnualReturnRate: estimatedAnnualReturnRate,
      annualProfitShareRate: annualProfitShareRate,
    );
    state = [...state, newGoal];
    await _saveGoals();
    return newGoal;
  }

  Future<void> updateGoalAmount(String id, double newAmount) async {
    await _initCompleter.future;
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
    await _initCompleter.future;
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

  Future<void> updateGoal(SavingsGoal updatedGoal) async {
    await _initCompleter.future;
    state = [
      for (final goal in state)
        if (goal.id == updatedGoal.id) updatedGoal else goal,
    ];
    await _saveGoals();
  }

  Future<SavingsGoal?> syncGoal(String id, {DateTime? asOf}) async {
    await _initCompleter.future;
    SavingsGoal? synced;
    state = [
      for (final goal in state)
        if (goal.id == id)
          synced = goal.accrueUntil(asOf ?? DateTime.now())
        else
          goal,
    ];
    await _saveGoals();
    return synced;
  }

  Future<void> deleteGoal(String id) async {
    await _initCompleter.future;
    state = state.where((goal) => goal.id != id).toList();
    await _saveGoals();
  }

  Future<void> clearAll() async {
    await _initCompleter.future;
    state = const [];
    await _saveGoals();
  }
}

final savingsGoalProvider =
    StateNotifierProvider<SavingsGoalNotifier, List<SavingsGoal>>((ref) {
  return SavingsGoalNotifier();
});
