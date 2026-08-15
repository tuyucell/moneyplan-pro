import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clear all waits for loading and cannot restore an old savings goal',
      () async {
    const oldGoal = SavingsGoal(
      id: 'old-goal',
      name: 'Eski Birikim',
      targetAmount: 100000,
      currentAmount: 25000,
      colorValue: 0xFF000000,
    );
    SharedPreferences.setMockInitialValues({
      'user_savings_goals': jsonEncode([oldGoal.toJson()]),
    });

    final notifier = SavingsGoalNotifier();
    await notifier.clearAll();

    expect(notifier.state, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('user_savings_goals')!), isEmpty);
    notifier.dispose();
  });
}
