import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';

class StatementChargePlan {
  final List<WalletTransaction> upserts;
  final List<String> removals;

  const StatementChargePlan({
    this.upserts = const [],
    this.removals = const [],
  });
}

/// Reconciles deterministic monthly interest and tax ledger entries.
///
/// Credit-card interest is generated only after the statement's due date and
/// only for the part of that statement which was still unpaid at that date.
/// Reconciliation also removes stale automatic entries after an account's
/// opening balance or cycle settings are changed.
class StatementChargeService {
  static List<WalletTransaction> createDueCharges({
    required BankAccount account,
    required List<WalletTransaction> transactions,
    required DateTime asOf,
  }) =>
      buildPlan(
        account: account,
        transactions: transactions,
        asOf: asOf,
      ).upserts;

  static StatementChargePlan buildPlan({
    required BankAccount account,
    required List<WalletTransaction> transactions,
    required DateTime asOf,
  }) {
    final generated = transactions
        .where((tx) => _isGeneratedForAccount(tx, account.id))
        .toList();

    if (!account.isActive || account.overdraftInterestRate <= 0) {
      return StatementChargePlan(
        removals: generated.map((tx) => tx.id).toList(),
      );
    }

    final expected = _expectedCharges(
      account: account,
      transactions: transactions
          .where((tx) => !_isGeneratedForAccount(tx, account.id))
          .toList(),
      asOf: asOf,
    );
    final expectedById = {for (final tx in expected) tx.id: tx};
    final existingById = {for (final tx in generated) tx.id: tx};

    return StatementChargePlan(
      upserts: expected.where((tx) {
        final existing = existingById[tx.id];
        return existing == null || !_sameCharge(existing, tx);
      }).toList(),
      removals: generated
          .where((tx) => !expectedById.containsKey(tx.id))
          .map((tx) => tx.id)
          .toList(),
    );
  }

  static List<WalletTransaction> _expectedCharges({
    required BankAccount account,
    required List<WalletTransaction> transactions,
    required DateTime asOf,
  }) {
    final charges = <WalletTransaction>[];
    final workingTransactions = List<WalletTransaction>.from(transactions);
    final effectiveDate = account.balanceEffectiveDate ??
        account.createdAt ??
        DateTime(asOf.year, asOf.month);
    final firstMonth = DateTime(effectiveDate.year, effectiveDate.month);
    final lastMonth = DateTime(asOf.year, asOf.month);
    final calendarAsOf = DateTime(asOf.year, asOf.month, asOf.day);

    var cursor = firstMonth;
    while (!cursor.isAfter(lastMonth)) {
      final statementDate = account.statementDateFor(cursor.year, cursor.month);
      final period = '${cursor.year}${cursor.month.toString().padLeft(2, '0')}';

      if (statementDate.isAfter(effectiveDate)) {
        DateTime chargeDate;
        DateTime? dueDate;
        double chargeableBalance;

        if (account.accountType == 'Kredi Kartı') {
          dueDate = account.dueDateForStatement(statementDate);
          if (!calendarAsOf.isAfter(dueDate)) {
            cursor = DateTime(cursor.year, cursor.month + 1);
            continue;
          }

          final statementBalance = _balanceAt(
            account,
            workingTransactions,
            statementDate,
            effectiveDate,
          );
          final statementDebt = statementBalance < 0 ? -statementBalance : 0.0;
          final payments = _paymentsThroughDueDate(
            account,
            workingTransactions,
            statementDate,
            dueDate,
          );
          final unpaidDebt =
              (statementDebt - payments).clamp(0, double.infinity);
          chargeableBalance = -unpaidDebt.toDouble();
          chargeDate = dueDate.add(const Duration(days: 1));
        } else {
          if (statementDate.isAfter(calendarAsOf)) {
            cursor = DateTime(cursor.year, cursor.month + 1);
            continue;
          }
          chargeableBalance = _balanceAt(
            account,
            workingTransactions,
            statementDate,
            effectiveDate,
          );
          chargeDate = statementDate;
          dueDate = null;
        }

        final breakdown = account.calculateStatementCharges(chargeableBalance);
        final interest = _roundCurrency(breakdown.interest);
        final tax = _roundCurrency(breakdown.tax);

        if (interest > 0) {
          final transaction = WalletTransaction(
            id: 'statement_interest_${account.id}_$period',
            categoryId: 'bank_interest',
            amount: interest,
            date: chargeDate,
            note: account.accountType == 'Kredi Kartı'
                ? '${account.name} ödenmemiş ekstre faizi (%${account.overdraftInterestRate.toStringAsFixed(2)})'
                : '${account.name} hesap faizi (%${account.overdraftInterestRate.toStringAsFixed(2)})',
            type: TransactionType.expense,
            bankAccountId: account.id,
            dueDate: dueDate,
            isPaid: true,
            currencyCode: account.currencyCode,
            paymentMethod: account.accountType == 'Kredi Kartı'
                ? PaymentMethod.creditCard
                : PaymentMethod.bankTransfer,
          );
          charges.add(transaction);
          workingTransactions.add(transaction);
        }

        if (tax > 0) {
          final transaction = WalletTransaction(
            id: 'statement_tax_${account.id}_$period',
            categoryId: 'bank_tax',
            amount: tax,
            date: chargeDate,
            note:
                '${account.name} faiz vergileri (BSMV %${account.bsmvRate.toStringAsFixed(2)} + KKDF %${account.kkdfRate.toStringAsFixed(2)})',
            type: TransactionType.expense,
            bankAccountId: account.id,
            dueDate: dueDate,
            isPaid: true,
            currencyCode: account.currencyCode,
            paymentMethod: account.accountType == 'Kredi Kartı'
                ? PaymentMethod.creditCard
                : PaymentMethod.bankTransfer,
          );
          charges.add(transaction);
          workingTransactions.add(transaction);
        }
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return charges;
  }

  static double _balanceAt(
    BankAccount account,
    List<WalletTransaction> transactions,
    DateTime date,
    DateTime effectiveDate,
  ) {
    var balance = account.initialBalance;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    for (final tx in transactions) {
      if (tx.bankAccountId != account.id ||
          tx.excludeFromBalance ||
          tx.date.isBefore(effectiveDate) ||
          tx.date.isAfter(end)) {
        continue;
      }
      if (tx.currencyCode.isNotEmpty &&
          tx.currencyCode != account.currencyCode) {
        continue;
      }
      balance += tx.type == TransactionType.income ? tx.amount : -tx.amount;
    }
    return balance;
  }

  static double _paymentsThroughDueDate(
    BankAccount account,
    List<WalletTransaction> transactions,
    DateTime statementDate,
    DateTime dueDate,
  ) {
    final statementEnd = DateTime(
      statementDate.year,
      statementDate.month,
      statementDate.day,
      23,
      59,
      59,
      999,
    );
    final dueEnd = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
      999,
    );
    return transactions.fold<double>(0, (total, tx) {
      if (tx.bankAccountId != account.id ||
          tx.excludeFromBalance ||
          tx.type != TransactionType.income ||
          !tx.date.isAfter(statementEnd) ||
          tx.date.isAfter(dueEnd)) {
        return total;
      }
      if (tx.currencyCode.isNotEmpty &&
          tx.currencyCode != account.currencyCode) {
        return total;
      }
      return total + tx.amount;
    });
  }

  static bool _isGeneratedForAccount(WalletTransaction tx, String accountId) {
    return tx.id.startsWith('statement_interest_${accountId}_') ||
        tx.id.startsWith('statement_tax_${accountId}_');
  }

  static bool _sameCharge(WalletTransaction left, WalletTransaction right) {
    return left.amount == right.amount &&
        left.date == right.date &&
        left.dueDate == right.dueDate &&
        left.note == right.note;
  }

  static double _roundCurrency(double value) =>
      (value * 100).roundToDouble() / 100;
}
