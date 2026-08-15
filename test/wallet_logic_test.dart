import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/yearly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';

void main() {
  group('Wallet Logic Tests', () {
    test(
        'MonthlySummary should only include transactions from the target month',
        () {
      final transactions = [
        WalletTransaction(
          id: '1',
          categoryId: 'food',
          amount: 100,
          date: DateTime(2025, 12, 25),
          type: TransactionType.expense,
          isPaid: false, // Unpaid
        ),
        WalletTransaction(
          id: '2',
          categoryId: 'salary',
          amount: 5000,
          date: DateTime(2026, 1, 15),
          type: TransactionType.income,
          isPaid: true,
        ),
      ];

      final summaryJan = MonthlySummary.fromTransactions(transactions, 2026, 1);
      final summaryDec =
          MonthlySummary.fromTransactions(transactions, 2025, 12);

      expect(summaryJan.totalIncome, 5000);
      expect(summaryJan.totalPendingExpense, 0,
          reason: 'Dec transaction should not be in Jan');

      expect(summaryDec.totalIncome, 0);
      expect(summaryDec.totalPendingExpense, 100);
    });

    test('Available balance should be income - paid expenses - unpaid expenses',
        () {
      final transactions = [
        WalletTransaction(
          id: '1',
          categoryId: 'salary',
          amount: 10000,
          date: DateTime(2026, 1, 1),
          type: TransactionType.income,
          isPaid: true,
        ),
        WalletTransaction(
          id: '2',
          categoryId: 'rent',
          amount: 3000,
          date: DateTime(2026, 1, 5),
          type: TransactionType.expense,
          isPaid: true,
        ),
        WalletTransaction(
          id: '3',
          categoryId: 'bank_credit_card',
          amount: 4000,
          date: DateTime(2026, 1, 10),
          type: TransactionType.expense,
          isPaid: false, // CC bill unpaid
        ),
      ];

      final summary = MonthlySummary.fromTransactions(transactions, 2026, 1);

      expect(summary.remainingBalance, 7000, reason: '10000 - 3000');
      expect(summary.totalPendingExpense, 4000);
      expect(summary.availableBalance, 3000, reason: '7000 - 4000');
    });

    test('Yearly summaries include every monthly recurring income and expense',
        () {
      final transactions = [
        WalletTransaction(
          id: 'salary',
          categoryId: 'salary',
          amount: 5000,
          date: DateTime(2026, 1, 5),
          type: TransactionType.income,
          recurrence: RecurrenceType.monthly,
          recurrenceEndDate: DateTime(2026, 12, 31),
        ),
        WalletTransaction(
          id: 'rent',
          categoryId: 'rent',
          amount: 1500,
          date: DateTime(2026, 1, 10),
          type: TransactionType.expense,
          recurrence: RecurrenceType.monthly,
          recurrenceEndDate: DateTime(2026, 12, 31),
          isPaid: true,
        ),
      ];

      double yearlyIncome = 0;
      double yearlyExpense = 0;
      for (var month = 1; month <= 12; month++) {
        final expanded = List<WalletTransaction>.from(transactions)
          ..addAll(WalletNotifier.generateRecurringTransactionsForMonth(
            transactions,
            2026,
            month,
          ));
        final summary = MonthlySummary.fromTransactions(expanded, 2026, month);
        yearlyIncome += summary.totalIncome;
        yearlyExpense += summary.totalExpense;
      }

      expect(yearlyIncome, 60000);
      expect(yearlyExpense, 18000);
    });

    test('Cash-excluded recurring expense remains visible in analytics', () {
      final summary = MonthlySummary.fromTransactions(
        [
          WalletTransaction(
            id: 'card_subscription',
            categoryId: 'subscription',
            amount: 250,
            date: DateTime(2026, 1, 15),
            type: TransactionType.expense,
            isPaid: false,
            excludeFromBalance: true,
          ),
        ],
        2026,
        1,
      );

      expect(summary.totalExpense, 250);
      expect(summary.totalPendingExpense, 250);
      expect(summary.cashExpense, 0);
      expect(summary.pendingPayments, 250);
    });

    test('KMH snapshot starts in its entry month and rolls forward once', () {
      final kmh = BankAccount(
        id: 'kmh',
        name: 'Ek Hesap',
        accountType: 'Vadesiz Hesap',
        initialBalance: -64000,
        overdraftLimit: 100000,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );

      final july = MonthlySummary.fromTransactions(
        const [],
        2026,
        7,
        bankAccountList: [kmh],
      );
      final august = MonthlySummary.fromTransactions(
        const [],
        2026,
        8,
        bankAccountList: [kmh],
      );
      final september = MonthlySummary.fromTransactions(
        const [],
        2026,
        9,
        bankAccountList: [kmh],
      );

      expect(july.remainingBalance, 0);
      expect(july.totalOverdraftLimit, 0);
      expect(august.remainingBalance, -64000);
      expect(august.totalOverdraftLimit, 100000);
      expect(september.remainingBalance, -64000);

      final payment = WalletTransaction(
        id: 'kmh-payment',
        categoryId: 'transfer_deposit',
        amount: 64000,
        date: DateTime(2026, 9, 5),
        type: TransactionType.income,
        bankAccountId: kmh.id,
      );
      final paidSeptember = MonthlySummary.fromTransactions(
        [payment],
        2026,
        9,
        bankAccountList: [kmh],
      );
      final octoberAfterPayment = MonthlySummary.fromTransactions(
        [payment],
        2026,
        10,
        bankAccountList: [kmh],
      );

      expect(paidSeptember.remainingBalance, 0);
      expect(octoberAfterPayment.remainingBalance, 0);
    });

    test('yearly net excludes KMH snapshots and account limits', () {
      final kmh = BankAccount(
        id: 'kmh',
        name: 'Ek Hesap',
        accountType: 'Vadesiz Hesap',
        initialBalance: -64000,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );
      final months = List.generate(
        12,
        (index) => MonthlySummary.fromTransactions(
          const [],
          2026,
          index + 1,
          bankAccountList: [kmh],
        ),
      );

      expect(
        YearlySummary(year: 2026, monthlySummaries: months).remainingBalance,
        0,
      );
    });

    test('yearly net is income minus expense without counting pending twice',
        () {
      final august = MonthlySummary.fromTransactions(
        [
          WalletTransaction(
            id: 'income',
            categoryId: 'salary',
            amount: 717000,
            date: DateTime(2026, 8, 1),
            type: TransactionType.income,
          ),
          WalletTransaction(
            id: 'expense',
            categoryId: 'rent',
            amount: 208000,
            date: DateTime(2026, 8, 2),
            type: TransactionType.expense,
            isPaid: false,
          ),
        ],
        2026,
        8,
      );
      final yearly = YearlySummary(
        year: 2026,
        monthlySummaries: [august],
      );

      expect(yearly.totalIncome, 717000);
      expect(yearly.totalExpense, 208000);
      expect(yearly.totalOutflow, 208000);
      expect(yearly.remainingBalance, 509000);
    });

    test('recurring IDs with underscores resolve and can be skipped by month',
        () {
      final source = WalletTransaction(
        id: 'monthly_home_rent',
        categoryId: 'rent',
        amount: 15000,
        date: DateTime(2026, 7, 1),
        type: TransactionType.expense,
        recurrence: RecurrenceType.monthly,
      );
      final skip = source.copyWith(
        id: 'monthly_home_rent_skip_202608',
        amount: 0,
        recurrence: RecurrenceType.none,
        excludeFromBalance: true,
      );

      expect(
        WalletNotifier.recurringSourceId('monthly_home_rent_202608'),
        'monthly_home_rent',
      );
      expect(
        WalletNotifier.generateRecurringTransactionsForMonth(
          [source, skip],
          2026,
          8,
        ),
        isEmpty,
      );
    });
  });
}
