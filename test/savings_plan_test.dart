import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';

void main() {
  test('legacy savings JSON stays backward compatible', () {
    final goal = SavingsGoal.fromJson({
      'id': 'legacy',
      'name': 'Eski birikim',
      'targetAmount': 1000,
      'currentAmount': 250,
      'colorValue': 0xFFFFA726,
    });

    expect(goal.planType, SavingsPlanType.savings);
    expect(goal.automaticPayment, isFalse);
    expect(goal.governmentContributionRate, 20);
    expect(goal.currentAmount, 250);
  });

  test('BES monthly sync adds contribution and editable government share once',
      () {
    const goal = SavingsGoal(
      id: 'bes-plan',
      name: 'BES',
      targetAmount: 100000,
      currentAmount: 1000,
      colorValue: 0xFFFFA726,
      planType: SavingsPlanType.bes,
      periodicContribution: 100,
      automaticPayment: true,
      governmentContributionRate: 20,
      contractStartDate: null,
      lastAccrualDate: null,
    );
    final seeded = goal.copyWith(
      contractStartDate: DateTime(2026, 1, 1),
      lastAccrualDate: DateTime(2026, 1, 1),
    );

    final february = seeded.accrueUntil(DateTime(2026, 2, 15));
    final repeated = february.accrueUntil(DateTime(2026, 2, 28));

    expect(february.currentAmount, 1120);
    expect(february.governmentContributionBalance, 20);
    expect(repeated.currentAmount, 1120,
        reason: 'the same month must not be compounded twice');
  });

  test('quarterly recurring plan only produces every third month', () {
    final source = WalletTransaction(
      id: 'quarterly-bes',
      categoryId: 'bes',
      amount: 1000,
      date: DateTime(2026, 1, 15),
      type: TransactionType.expense,
      recurrence: RecurrenceType.quarterly,
    );

    expect(
      WalletNotifier.generateRecurringTransactionsForMonth(
        [source],
        2026,
        2,
      ),
      isEmpty,
    );
    expect(
      WalletNotifier.generateRecurringTransactionsForMonth(
        [source],
        2026,
        4,
      ).single.id,
      'quarterly-bes_202604',
    );
  });
}
