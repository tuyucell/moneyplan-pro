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
      'user_savings_goals_test-user': jsonEncode([oldGoal.toJson()]),
    });

    final prefs = await SharedPreferences.getInstance();
    final notifier = SavingsGoalNotifier(
      preferences: prefs,
      userId: 'test-user',
    );
    await notifier.clearAll();

    expect(notifier.state, isEmpty);
    expect(
      jsonDecode(prefs.getString('user_savings_goals_test-user')!),
      isEmpty,
    );
    notifier.dispose();
  });

  test('legacy goals are claimed once by the signed-in user', () async {
    const legacyGoal = SavingsGoal(
      id: 'legacy-goal',
      name: 'Eski Birikim',
      targetAmount: 50000,
      currentAmount: 10000,
      colorValue: 0xFF000000,
    );
    SharedPreferences.setMockInitialValues({
      'user_savings_goals': jsonEncode([legacyGoal.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();
    final firstUser = SavingsGoalNotifier(
      preferences: prefs,
      userId: 'first-user',
    );
    await firstUser.clearAll();

    expect(prefs.containsKey('user_savings_goals'), isFalse);
    expect(prefs.containsKey('user_savings_goals_first-user'), isTrue);

    final secondUser = SavingsGoalNotifier(
      preferences: prefs,
      userId: 'second-user',
    );
    await secondUser.clearAll();
    expect(
      jsonDecode(prefs.getString('user_savings_goals_second-user')!),
      isEmpty,
    );
    firstUser.dispose();
    secondUser.dispose();
  });
}
