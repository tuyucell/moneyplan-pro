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

      // Balance calculation (same as widget):
      // 1. UNPAID debts → Reduce credit
      // 2. PAID debts (original, no linkedTx) → Skip
      // 3. Payment transactions (has linkedTx) → Include
      // 4. Regular expenses → Include
      // 5. Income → Include

      final isUnpaidDebt = !tx.isPaid &&
          tx.type == TransactionType.expense &&
          tx.categoryId == 'bank_credit_card';

      final isPaidDebt = tx.isPaid &&
          tx.type == TransactionType.expense &&
          tx.categoryId == 'bank_credit_card' &&
          tx.linkedTransactionId == null;

      if (isUnpaidDebt) {
        balance -= tx.amount;
      } else if (!isPaidDebt) {
        // Include payments, regular expenses, income
        final amount =
            tx.type == TransactionType.income ? tx.amount : -tx.amount;
        balance += amount;
      }
      // Skip isPaidDebt
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

  /// Create payment transaction following banking standards
  /// Ensures atomicity and proper audit trail
  static WalletTransaction createPaymentTransaction(
    PaymentRequest request,
  ) {
    debugPrint(
        '🏦 PaymentService: Creating transaction for debt on ${request.debtAccount.name}');
    debugPrint(
        '   - From Account: ${request.payingAccount.name} (Type: ${request.payingAccount.accountType})');
    debugPrint('   - Amount: ${request.paymentAmount} ${request.currencyCode}');

    return WalletTransaction(
      id: const Uuid().v4(),
      categoryId: request.debtTransaction.categoryId,
      amount: request.paymentAmount,
      currencyCode: request.currencyCode,
      date: DateTime.now(),
      note:
          '${request.debtAccount.name} borcunu ${request.payingAccount.name} ile ödeme '
          '(${request.isPartialPayment ? "Kısmi " : ""}${request.paymentAmount.toStringAsFixed(2)} ${request.currencyCode})',
      type: TransactionType.expense,
      isPaid: true,
      bankAccountId: request.payingAccount.id,
      paymentMethod: PaymentMethod.bankTransfer,
      linkedTransactionId: request.debtTransaction.id,
    );
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
