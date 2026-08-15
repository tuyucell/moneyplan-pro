import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';

void main() {
  test('historical summary uses the transaction rate snapshot', () {
    final transaction = WalletTransaction(
      id: 'usd-expense',
      categoryId: 'bills',
      amount: 100,
      date: DateTime(2026, 8, 15),
      type: TransactionType.expense,
      currencyCode: 'USD',
      exchangeRateToTRY: 40,
      exchangeRateDate: DateTime(2026, 8, 15),
      exchangeRateSource: 'TCMB',
      isPaid: true,
    );

    final restored = WalletTransaction.fromJson(transaction.toJson());
    final summary = MonthlySummary.fromTransactions(
      [restored],
      2026,
      8,
      converter: (amount, _) => amount * 99,
      transactionConverter: (item) =>
          item.amount * (item.exchangeRateToTRY ?? 99),
    );

    expect(restored.exchangeRateToTRY, 40);
    expect(restored.exchangeRateSource, 'TCMB');
    expect(summary.totalExpense, 4000);
  });
}
