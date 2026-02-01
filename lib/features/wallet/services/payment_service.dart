import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bank_account.dart';
import '../models/wallet_transaction.dart';
import '../models/transaction_category.dart';

/// Domain model for payment operations
class PaymentRequest {
  final WalletTransaction debtTransaction;
  final BankAccount debtAccount;
  final BankAccount payingAccount;
  final double paymentAmount;

  const PaymentRequest({
    required this.debtTransaction,
    required this.debtAccount,
    required this.payingAccount,
    required this.paymentAmount,
  });

  bool get isFullPayment => paymentAmount >= debtTransaction.amount;
  bool get isPartialPayment => !isFullPayment;
  String get currencyCode => debtTransaction.currencyCode;
}

/// Payment result with detailed status
class PaymentResult {
  final bool success;
  final String message;
  final WalletTransaction? paymentTransaction;
  final String? errorCode;

  const PaymentResult.success({
    required this.message,
    required this.paymentTransaction,
  })  : success = true,
        errorCode = null;

  const PaymentResult.failure({
    required this.message,
    this.errorCode,
  })  : success = false,
        paymentTransaction = null;
}

/// Account balance with currency support
class AccountBalance {
  final BankAccount account;
  final double balance;
  final double availableBalance; // balance + overdraft
  final String currency;

  const AccountBalance({
    required this.account,
    required this.balance,
    required this.availableBalance,
    required this.currency,
  });

  bool canPay(double amount, String targetCurrency) {
    // Same currency comparison
    if (currency != targetCurrency) return false;
    return availableBalance >= amount;
  }

  double get utilizationRate {
    if (account.overdraftLimit == 0) return 0;
    return (account.overdraftLimit - (availableBalance - balance)) /
        account.overdraftLimit;
  }
}

/// Service for payment operations - follows banking best practices
class PaymentService {
  /// Calculate available balance for an account
  /// Includes: initial balance + income - expenses + overdraft limit
  static AccountBalance calculateAccountBalance(
    BankAccount account,
    List<WalletTransaction> transactions,
  ) {
    var balance = account.initialBalance;

    for (final tx in transactions) {
      if (tx.bankAccountId != account.id) {
        continue;
      }

      // Only include transactions in same currency (or if currency is missing, assume account currency)
      if (tx.currencyCode.isNotEmpty &&
          tx.currencyCode != account.currencyCode) {
        continue;
      }

      // Standard balance calculation:
      // Balance = Initial + Sum(Income) - Sum(Expense)
      // This supports the new "Transfer" logic where paying a debt creates an offsetting Income.

      if (tx.type == TransactionType.income) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }

    return AccountBalance(
      account: account,
      balance: balance,
      availableBalance: balance + account.overdraftLimit,
      currency: account.currencyCode,
    );
  }

  /// Find suitable accounts for payment with currency matching
  static List<AccountBalance> findPayableAccounts(
    BankAccount debtAccount,
    List<BankAccount> allAccounts,
    List<WalletTransaction> transactions,
    String targetCurrency,
  ) {
    final payableAccounts = allAccounts
        .where((acc) =>
            acc.id != debtAccount.id && acc.accountType != 'Kredi Kartı')
        .toList();

    // Calculate balances and filter by currency
    final balances = payableAccounts
        .map((acc) => calculateAccountBalance(acc, transactions))
        .where((balance) => balance.currency == targetCurrency)
        .toList();

    // Sort by: 1) Sufficient balance, 2) Highest available balance
    balances.sort((a, b) {
      final aCanPay = a.canPay(0, targetCurrency) ? 1 : 0;
      final bCanPay = b.canPay(0, targetCurrency) ? 1 : 0;
      if (aCanPay != bCanPay) return bCanPay - aCanPay;
      return b.availableBalance.compareTo(a.availableBalance);
    });

    return balances;
  }

  /// Create payment transactions (Transfer: Expense from Source -> Income to Target)
  static List<WalletTransaction> createPaymentTransactions(
    PaymentRequest request,
  ) {
    debugPrint(
        '🏦 PaymentService: Creating transfer ${request.paymentAmount} from ${request.payingAccount.name} to ${request.debtAccount.name}');

    final now = DateTime.now();

    // 1. Expense from Paying Account
    final expenseTx = WalletTransaction(
      id: const Uuid().v4(), // Unique ID
      categoryId:
          request.debtTransaction.categoryId, // Keep category for tracking
      amount: request.paymentAmount,
      currencyCode: request.currencyCode,
      date: now,
      note: '${request.debtAccount.name} hesabına transfer/borç ödeme',
      type: TransactionType.expense,
      isPaid: true,
      bankAccountId: request.payingAccount.id,
      paymentMethod: PaymentMethod.bankTransfer,
      linkedTransactionId: request.debtTransaction.id, // Links to original debt
    );

    // 2. Income to Debt Account (The "Payment")
    // This effectively reduces the negative balance of the debt account
    final incomeTx = WalletTransaction(
      id: const Uuid().v4(),
      categoryId: 'transfer_deposit', // Special category or same as expense?
      // If we want it to show as "Debt Repayment", maybe use same category but Income type?
      // Usually "Transfer" or "Deposit". Let's use Income type.
      amount: request.paymentAmount,
      currencyCode: request.currencyCode,
      date: now,
      note: '${request.payingAccount.name} hesabından gelen ödeme',
      type: TransactionType.income,
      isPaid: true,
      bankAccountId: request.debtAccount.id,
      paymentMethod: PaymentMethod.bankTransfer,
      linkedTransactionId: expenseTx.id, // Link to the expense
    );

    return [expenseTx, incomeTx];
  }

  /// Validate payment request before execution
  static PaymentResult? validatePayment(
    PaymentRequest request,
    List<WalletTransaction> transactions,
  ) {
    final balance = calculateAccountBalance(
      request.payingAccount,
      transactions,
    );

    // Currency mismatch check
    if (balance.currency != request.currencyCode) {
      return PaymentResult.failure(
        message: 'Para birimi uyuşmazlığı: '
            'Hesap ${balance.currency}, Borç ${request.currencyCode}',
        errorCode: 'CURRENCY_MISMATCH',
      );
    }

    // Insufficient balance check
    if (!balance.canPay(request.paymentAmount, request.currencyCode)) {
      return PaymentResult.failure(
        message: 'Yetersiz bakiye!\n'
            'Gerekli: ${request.paymentAmount.toStringAsFixed(2)} ${request.currencyCode}\n'
            'Kullanılabilir: ${balance.availableBalance.toStringAsFixed(2)} ${balance.currency}',
        errorCode: 'INSUFFICIENT_BALANCE',
      );
    }

    return null; // No validation errors
  }
}
