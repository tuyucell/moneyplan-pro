import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';

/// Converts future credit-card installment commitments into ledger debt when
/// their statement month arrives.
class InstallmentScheduleService {
  static String openingDebtTransactionId(String accountId) =>
      'card_opening_debt_$accountId';

  static List<WalletTransaction> createDueTransactions({
    required BankAccount account,
    required List<WalletTransaction> transactions,
    required DateTime asOf,
  }) {
    if (!account.isActive || account.accountType != 'Kredi Kartı') {
      return const [];
    }

    final existingById = {
      for (final transaction in transactions) transaction.id: transaction,
    };
    final dueTransactions = <WalletTransaction>[];

    if (account.initialBalance < 0) {
      final date = account.balanceEffectiveFrom;
      if (!date.isAfter(asOf)) {
        final statementDate = account.nextStatementOnOrAfter(date);
        final openingDebt = WalletTransaction(
          id: openingDebtTransactionId(account.id),
          categoryId: 'bank_credit_card',
          amount: _roundCurrency(-account.initialBalance),
          date: date,
          note: '${account.name} başlangıç ekstre borcu',
          type: TransactionType.expense,
          bankAccountId: account.id,
          dueDate: account.dueDateForStatement(statementDate),
          isPaid: true,
          currencyCode: account.currencyCode,
          paymentMethod: PaymentMethod.creditCard,
          excludeFromBalance: true,
        );
        final existing = existingById[openingDebt.id];
        if (!_sameGeneratedTransaction(existing, openingDebt)) {
          dueTransactions.add(openingDebt);
          existingById[openingDebt.id] = openingDebt;
        }
      }
    }

    for (final installment in account.installmentPlan) {
      if (installment.amount <= 0) continue;

      final transactionId = installment.ledgerTransactionId(account.id);
      final statementDate = account.statementDateFor(
        installment.statementMonth.year,
        installment.statementMonth.month,
      );
      if (statementDate.isBefore(account.balanceEffectiveFrom)) continue;
      if (statementDate.isAfter(asOf)) continue;

      final description = installment.note?.trim();
      final generated = WalletTransaction(
        id: transactionId,
        categoryId: 'bank_credit_card',
        amount: _roundCurrency(installment.amount),
        date: statementDate,
        note: description == null || description.isEmpty
            ? '${account.name} taksit borcu'
            : '${account.name} taksit borcu - $description',
        type: TransactionType.expense,
        bankAccountId: account.id,
        dueDate: account.dueDateForStatement(statementDate),
        isPaid: false,
        currencyCode: account.currencyCode,
        paymentMethod: PaymentMethod.creditCard,
      );
      final existing = existingById[transactionId];
      if (!_sameGeneratedTransaction(existing, generated)) {
        dueTransactions.add(generated);
        existingById[transactionId] = generated;
      }
    }

    return dueTransactions;
  }

  static double pendingTotal({
    required BankAccount account,
    required List<WalletTransaction> transactions,
  }) {
    final transactionIds =
        transactions.map((transaction) => transaction.id).toSet();
    return account.installmentPlan.fold<double>(0, (total, installment) {
      if (installment.amount <= 0) return total;
      final statementDate = account.statementDateFor(
        installment.statementMonth.year,
        installment.statementMonth.month,
      );
      if (statementDate.isBefore(account.balanceEffectiveFrom)) return total;
      if (transactionIds
          .contains(installment.ledgerTransactionId(account.id))) {
        return total;
      }
      return total + installment.amount;
    });
  }

  static double _roundCurrency(double value) =>
      (value * 100).roundToDouble() / 100;

  static bool _sameGeneratedTransaction(
    WalletTransaction? existing,
    WalletTransaction generated,
  ) {
    if (existing == null) return false;
    return existing.amount == generated.amount &&
        existing.date == generated.date &&
        existing.note == generated.note &&
        existing.dueDate == generated.dueDate &&
        existing.currencyCode == generated.currencyCode &&
        existing.excludeFromBalance == generated.excludeFromBalance;
  }
}
