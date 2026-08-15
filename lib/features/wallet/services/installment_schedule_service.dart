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
      final date = account.createdAt ?? asOf;
      if (!date.isAfter(asOf)) {
        final openingDebt = WalletTransaction(
          id: openingDebtTransactionId(account.id),
          categoryId: 'bank_credit_card',
          amount: _roundCurrency(-account.initialBalance),
          date: date,
          note: '${account.name} başlangıç ekstre borcu',
          type: TransactionType.expense,
          bankAccountId: account.id,
          dueDate: _dueDateFor(account, date),
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
      final statementDate = _dateWithClampedDay(
        installment.statementMonth.year,
        installment.statementMonth.month,
        account.paymentDay,
      );
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
        dueDate: _dueDateFor(account, statementDate),
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
      if (transactionIds
          .contains(installment.ledgerTransactionId(account.id))) {
        return total;
      }
      return total + installment.amount;
    });
  }

  static DateTime _dateWithClampedDay(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay.clamp(1, lastDay));
  }

  static DateTime _dueDateFor(
    BankAccount account,
    DateTime statementDate,
  ) {
    var dueMonth = statementDate.month;
    var dueYear = statementDate.year;
    if (account.dueDay <= statementDate.day) {
      dueMonth += 1;
      if (dueMonth > 12) {
        dueMonth = 1;
        dueYear += 1;
      }
    }
    return _dateWithClampedDay(dueYear, dueMonth, account.dueDay);
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
