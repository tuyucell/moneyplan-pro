import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyplan_pro/features/wallet/models/budget_limit.dart';

class BudgetNotifier extends StateNotifier<List<BudgetLimit>> {
  BudgetNotifier() : super([]) {
    _init();
  }

  Box? _box;
  final _initCompleter = Completer<void>();

  Future<void> _init() async {
    _box = await Hive.openBox('budget_limits');
    _loadBudgets();
    _initCompleter.complete();
  }

  void _loadBudgets() {
    if (_box == null) return;
    final budgets = _box!.values.map((map) {
      return BudgetLimit.fromJson(Map<String, dynamic>.from(map));
    }).toList();
    state = budgets;
  }

  Future<void> setBudget(BudgetLimit budget) async {
    await _initCompleter.future;
    final id = '${budget.categoryId}_${budget.year}_${budget.month}';
    await _box!.put(id, budget.toJson());
    _loadBudgets();
  }

  Future<void> deleteBudget(String categoryId, int year, int month) async {
    await _initCompleter.future;
    final id = '${categoryId}_${year}_$month';
    await _box!.delete(id);
    _loadBudgets();
  }

  BudgetLimit? getBudget(String categoryId, int year, int month) {
    try {
      return state.firstWhere(
        (b) => b.categoryId == categoryId && b.year == year && b.month == month,
      );
    } catch (_) {
      return null;
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, List<BudgetLimit>>((ref) {
  return BudgetNotifier();
});

// Helper provider to get budget for a specific category and month
final categoryBudgetProvider = Provider.family<BudgetLimit?, ({String categoryId, int year, int month})>((ref, arg) {
  final budgets = ref.watch(budgetProvider);
  try {
    return budgets.firstWhere(
      (b) => b.categoryId == arg.categoryId && b.year == arg.year && b.month == arg.month,
    );
  } catch (_) {
    return null;
  }
});
