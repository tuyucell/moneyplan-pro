import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
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

  test('savings financing tracks principal fee and delayed dates separately',
      () {
    final goal = SavingsGoal(
      id: 'finance-plan',
      name: '1M plan',
      targetAmount: 1000000,
      currentAmount: 40000,
      colorValue: 0xFFFFA726,
      planType: SavingsPlanType.savingsFinance,
      periodicContribution: 40000,
      contractStartDate: DateTime(2026, 7, 15),
      contractMonths: 25,
      minimumDeliveryMonths: 6,
      deliveryThresholdRate: 50,
      organizationFeeRate: 7,
      organizationFeePaid: 43750,
      missedPaymentMonths: 1,
    );

    expect(goal.organizationFeeAmount, 70000);
    expect(goal.organizationFeeRemaining, 26250);
    expect(goal.principalRemaining, 960000);
    expect(goal.effectiveDeliveryDate, DateTime(2027, 2, 15));
    expect(goal.contractEndDate, DateTime(2028, 9, 15));
    expect(goal.isDeliveryEligibleAt(DateTime(2027, 2, 15)), isFalse,
        reason: 'date alone is not enough before the payment threshold');
  });

  test('financing delivery affects cash but does not inflate earned income',
      () {
    final summary = MonthlySummary.fromTransactions(
      [
        WalletTransaction(
          id: 'delivery',
          categoryId: 'financing_inflow',
          amount: 1000000,
          date: DateTime(2026, 8, 15),
          type: TransactionType.income,
        ),
      ],
      2026,
      8,
    );

    expect(summary.cashIncome, 1000000);
    expect(summary.remainingBalance, 1000000);
    expect(summary.totalIncome, 0);
    expect(summary.incomeByCategory, isEmpty);
  });

  test('financing JSON roundtrip preserves contract state', () {
    final goal = SavingsGoal(
      id: 'finance-plan',
      name: 'Plan',
      targetAmount: 1000000,
      currentAmount: 80000,
      colorValue: 0xFFFFA726,
      planType: SavingsPlanType.savingsFinance,
      contractStartDate: DateTime(2026, 7, 15),
      contractMonths: 25,
      plannedDeliveryDate: DateTime(2027, 1, 15),
      organizationFeeRate: 7,
      organizationFeePaid: 43750,
      missedPaymentMonths: 1,
      financingDelivered: true,
      financingDeliveryDate: DateTime(2027, 2, 15),
      financingReceivingAccountId: 'cash-account',
    );

    final restored = SavingsGoal.fromJson(goal.toJson());

    expect(restored.planType, SavingsPlanType.savingsFinance);
    expect(restored.contractMonths, 25);
    expect(restored.organizationFeePaid, 43750);
    expect(restored.missedPaymentMonths, 1);
    expect(restored.financingDelivered, isTrue);
    expect(restored.financingReceivingAccountId, 'cash-account');
  });
}
