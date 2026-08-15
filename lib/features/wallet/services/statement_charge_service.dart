import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';

/// Produces deterministic monthly interest and tax ledger entries.
///
/// A charge is created only after an account's statement day, only for a
/// negative balance, and at most once per account/month.
class StatementChargeService {
  static List<WalletTransaction> createDueCharges({
    required BankAccount account,
    required List<WalletTransaction> transactions,
    required DateTime asOf,
  }) {
    if (!account.isActive || account.overdraftInterestRate <= 0) {
      return const [];
    }

    final charges = <WalletTransaction>[];
    final workingTransactions = List<WalletTransaction>.from(transactions);
    final firstMonth = account.createdAt == null
        ? DateTime(asOf.year, asOf.month)
        : DateTime(account.createdAt!.year, account.createdAt!.month);
    final lastMonth = DateTime(asOf.year, asOf.month);

    var cursor = firstMonth;
    while (!cursor.isAfter(lastMonth)) {
      final statementDate = _statementDate(
        cursor.year,
        cursor.month,
        account.paymentDay,
      );
      final createdDate = account.createdAt == null
          ? null
          : DateTime(
              account.createdAt!.year,
              account.createdAt!.month,
              account.createdAt!.day,
            );

      // An account opened on/after its statement day starts next month.
      final isAfterCreation =
          createdDate == null || statementDate.isAfter(createdDate);
      if (!statementDate.isAfter(asOf) && isAfterCreation) {
        final period =
            '${cursor.year}${cursor.month.toString().padLeft(2, '0')}';
        final interestId = 'statement_interest_${account.id}_$period';
        final taxId = 'statement_tax_${account.id}_$period';
        final alreadyCharged = workingTransactions.any(
          (tx) => tx.id == interestId || tx.id == taxId,
        );

        if (!alreadyCharged) {
          final balance = _balanceAtStatement(
            account,
            workingTransactions,
            statementDate,
          );
          final breakdown = account.calculateStatementCharges(balance);
          final interest = _roundCurrency(breakdown.interest);
          final tax = _roundCurrency(breakdown.tax);

          if (interest > 0) {
            final interestTransaction = WalletTransaction(
              id: interestId,
              categoryId: 'bank_interest',
              amount: interest,
              date: statementDate,
              note:
                  '${account.name} hesap kesim faizi (%${account.overdraftInterestRate.toStringAsFixed(2)})',
              type: TransactionType.expense,
              bankAccountId: account.id,
              dueDate: _dueDateFor(account, statementDate),
              isPaid: true,
              currencyCode: account.currencyCode,
              paymentMethod: account.accountType == 'Kredi Kartı'
                  ? PaymentMethod.creditCard
                  : PaymentMethod.bankTransfer,
            );
            charges.add(interestTransaction);
            workingTransactions.add(interestTransaction);
          }

          if (tax > 0) {
            final taxTransaction = WalletTransaction(
              id: taxId,
              categoryId: 'bank_tax',
              amount: tax,
              date: statementDate,
              note:
                  '${account.name} faiz vergileri (BSMV %${account.bsmvRate.toStringAsFixed(2)} + KKDF %${account.kkdfRate.toStringAsFixed(2)})',
              type: TransactionType.expense,
              bankAccountId: account.id,
              dueDate: _dueDateFor(account, statementDate),
              isPaid: true,
              currencyCode: account.currencyCode,
              paymentMethod: account.accountType == 'Kredi Kartı'
                  ? PaymentMethod.creditCard
                  : PaymentMethod.bankTransfer,
            );
            charges.add(taxTransaction);
            workingTransactions.add(taxTransaction);
          }
        }
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return charges;
  }

  static double _balanceAtStatement(
    BankAccount account,
    List<WalletTransaction> transactions,
    DateTime statementDate,
  ) {
    var balance = account.initialBalance;
    final statementEnd = DateTime(
      statementDate.year,
      statementDate.month,
      statementDate.day,
      23,
      59,
      59,
      999,
    );

    for (final tx in transactions) {
      if (tx.bankAccountId != account.id ||
          tx.excludeFromBalance ||
          tx.date.isAfter(statementEnd)) {
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

  static DateTime _statementDate(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay.clamp(1, lastDay));
  }

  static DateTime? _dueDateFor(
    BankAccount account,
    DateTime statementDate,
  ) {
    if (account.accountType != 'Kredi Kartı') return null;
    var dueMonth = statementDate.month;
    var dueYear = statementDate.year;
    if (account.dueDay <= statementDate.day) {
      dueMonth += 1;
      if (dueMonth > 12) {
        dueMonth = 1;
        dueYear += 1;
      }
    }
    final lastDay = DateTime(dueYear, dueMonth + 1, 0).day;
    return DateTime(dueYear, dueMonth, account.dueDay.clamp(1, lastDay));
  }

  static double _roundCurrency(double value) =>
      (value * 100).roundToDouble() / 100;
}
