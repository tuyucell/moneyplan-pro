import 'package:flutter_test/flutter_test.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/features/wallet/models/monthly_summary.dart';

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
  });
}
