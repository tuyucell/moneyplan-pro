import 'package:flutter/foundation.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';

class MonthlySummary {
  final int year;
  final int month;
  final double initialBalance; // Sadece nakit/vadesiz hesapların başlangıcı
  final double totalOverdraftLimit; // KMH limitleri
  final double cashIncome; // Sadece nakit hesaplara giren (Bakiye etkileyen)
  final double cashExpense; // Sadece nakit hesaplardan çıkan (Bakiye etkileyen)
  final double
      cashPendingExpense; // Nakit hesaplardan çıkacak bekleyenler (Hariç CC)
  final double totalIncome; // Tüm hesaplar (Analiz için)
  final double totalExpense; // Tüm hesaplar - Toplam Harcama (Analiz için)
  final double
      totalPendingExpense; // Tüm hesaplar - Sadece Bekleyenler (Analiz için)

  final double totalBES; // BES katkıları (pozitif tutar olarak)
  final double totalSavings; // Toplam tasarruf/yatırım (BES dahil)
  final double totalInterest; // Gecikme faizleri
  final double
      pendingPayments; // Bekleyen ödemeler (excludeFromBalance=true olanlar)
  final Map<String, double> incomeByCurrency; // Para birimine göre toplam gelir
  final Map<String, double>
      expenseByCurrency; // Para birimine göre toplam gider (Tüm harcama)
  final Map<String, double>
      pendingExpenseByCurrency; // Para birimine göre bekleyen gider
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final List<WalletTransaction> overdueTransactions;
  final List<WalletTransaction>
      pendingPaymentTransactions; // Bekleyen ödeme işlemleri

  MonthlySummary({
    required this.year,
    required this.month,
    required this.initialBalance,
    required this.totalOverdraftLimit,
    required this.cashIncome,
    required this.cashExpense,
    required this.cashPendingExpense,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalPendingExpense,
    required this.totalBES,
    required this.totalSavings,
    required this.totalInterest,
    required this.pendingPayments,
    required this.incomeByCurrency,
    required this.expenseByCurrency,
    required this.pendingExpenseByCurrency,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.overdueTransactions,
    required this.pendingPaymentTransactions,
  });

  // Kalan Bakiye: Başlangıç Nakit + Nakit Gelir - Nakit Gider
  double get remainingBalance => initialBalance + cashIncome - cashExpense;

  // Kullanılabilir Bakiye yalnızca kullanıcının gerçek nakit pozisyonudur.
  // KMH limiti borçlanma kapasitesidir; gelir/nakit gibi cüzdan toplamına
  // eklenmez. Hesap bazındaki KMH kullanılabilirliği ayrıca gösterilebilir.
  // Kredi kartı ekstreleri nakit bakiyeyi etkilemez (ödenene kadar).
  double get availableBalance =>
      remainingBalance - (cashPendingExpense + pendingPayments);

  // Toplam Gider (Tüm Harcamalar)
  double get totalOutflow => totalExpense;

  // Tasarruf Oranı: (Toplam Tasarruf / Toplam Gelir) * 100
  double get savingsRate =>
      totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;

  bool get isPositive => remainingBalance >= 0;

  String get monthName {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }

  static MonthlySummary fromTransactions(
    List<WalletTransaction> allTransactions,
    int year,
    int month, {
    List<BankAccount>? bankAccountList,
    double Function(double amount, String currencyCode)? converter,
    double Function(WalletTransaction transaction)? transactionConverter,
  }) {
    // 1. Calculate Initial Balance (Brought Forward)
    // - Sum of initial balances of CASH accounts (Exclude Credit Cards)
    // - Sum of all transactions before the start of the target month affecting CASH
    double initialBalance = 0;
    double totalOverdraftLimit = 0;
    final monthStart = DateTime(year, month);

    final cashAccountIds = <String>{};
    final cashAccountsById = <String, BankAccount>{};
    if (bankAccountList != null) {
      // debugPrint('🏦 MonthlySummary: Analyzing ${bankAccountList.length} accounts for CASH flow');
      for (final acc in bankAccountList) {
        if (acc.accountType != 'Kredi Kartı') {
          cashAccountIds.add(acc.id);
          cashAccountsById[acc.id] = acc;

          final effectiveDate = acc.balanceEffectiveDate ?? acc.createdAt;
          final effectiveMonth = effectiveDate == null
              ? null
              : DateTime(effectiveDate.year, effectiveDate.month);
          final snapshotApplies =
              effectiveMonth == null || !monthStart.isBefore(effectiveMonth);
          if (snapshotApplies) {
            final amount = acc.initialBalance;
            final normalized = converter != null
                ? converter(amount, acc.currencyCode)
                : amount;
            initialBalance += normalized;
            final limit = acc.overdraftLimit;
            totalOverdraftLimit +=
                converter != null ? converter(limit, acc.currencyCode) : limit;
            debugPrint(
                '   + [CASH ID ADDED] ${acc.name} (${acc.id}) Start: $normalized');
          } else {
            debugPrint(
                '   - [SKIP FUTURE CASH SNAPSHOT] ${acc.name} (${acc.id}) Effective: $effectiveDate');
          }
        } else {
          debugPrint('   - [SKIP CC ID] ${acc.name} (${acc.id})');
        }
      }
    }
    debugPrint('ℹ️ All Cash Account IDs: $cashAccountIds');

    // Past transactions affecting cash balance
    final pastTransactions =
        allTransactions.where((t) => t.date.isBefore(monthStart));

    for (final tx in pastTransactions) {
      if (tx.excludeFromBalance) continue;

      // Only affect top balance if it's a cash account or manual (null bank)
      final isCashAccount =
          tx.bankAccountId == null || cashAccountIds.contains(tx.bankAccountId);
      if (!isCashAccount) continue;

      final account =
          tx.bankAccountId == null ? null : cashAccountsById[tx.bankAccountId];
      final effectiveDate = account?.balanceEffectiveDate ?? account?.createdAt;
      if (effectiveDate != null && tx.date.isBefore(effectiveDate)) continue;

      final normalizedAmount = transactionConverter?.call(tx) ??
          (converter != null
              ? converter(tx.amount, tx.currencyCode)
              : tx.amount);

      if (tx.type == TransactionType.income) {
        initialBalance += normalizedAmount;
        debugPrint('   + [PAST INCOME] $normalizedAmount');
      } else {
        // Any expense assigned to a cash account in the past reduces starting balance
        initialBalance -= normalizedAmount;
        debugPrint(
            '   - [PAST CASH DEDUCTION] $normalizedAmount (${tx.categoryId})');
      }
      // Note: Unpaid CC debt from past doesn't reduce cash balance until paid.
    }
    debugPrint('💰 Calculated Monthly Initial Cash: $initialBalance');

    // 2. Process Current Month Transactions
    final monthTransactions = allTransactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;
    double totalPendingExpense = 0;

    double cashIncome = 0;
    double cashExpense = 0;
    double cashPendingExpense = 0;

    double totalBES = 0;
    double totalSavings = 0;
    double totalInterest = 0;
    double pendingPayments = 0;

    final incomeByCurrency = <String, double>{};
    final expenseByCurrency = <String, double>{};
    final pendingExpenseByCurrency = <String, double>{};

    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};
    final overdueTransactions = <WalletTransaction>[];
    final pendingPaymentTransactions = <WalletTransaction>[];

    final bankAccountsMap =
        bankAccountList != null ? {for (var a in bankAccountList) a.id: a} : {};

    for (final transaction in monthTransactions) {
      final currency = transaction.currencyCode;
      final amount = transaction.amount;

      // Normalize amount for TRY-based totals
      final normalizedAmount = transactionConverter?.call(transaction) ??
          (converter != null ? converter(amount, currency) : amount);

      // Identify if this affects CASH balance
      final isCashAccount = transaction.bankAccountId == null ||
          cashAccountIds.contains(transaction.bankAccountId);
      final account = transaction.bankAccountId == null
          ? null
          : cashAccountsById[transaction.bankAccountId];
      final effectiveDate = account?.balanceEffectiveDate ?? account?.createdAt;
      final isOnOrAfterBalanceSnapshot =
          effectiveDate == null || !transaction.date.isBefore(effectiveDate);

      // Some recurring/card entries are excluded from the cash balance, but
      // they must remain visible in expense analytics and yearly reports.
      final affectsCashBalance = !transaction.excludeFromBalance &&
          isCashAccount &&
          isOnOrAfterBalanceSnapshot;

      if (transaction.excludeFromBalance && !transaction.isPaid) {
        pendingPayments += normalizedAmount;
        pendingPaymentTransactions.add(transaction);
        debugPrint(
            '   📝 PENDING (Excluded from cash): $normalizedAmount on ${transaction.bankAccountId} (${transaction.note})');
      }

      // Finansman teslimatı nakit bakiyeyi artırır fakat kazanılmış gelir
      // değildir. Yıllık gelir ve tasarruf oranını yapay biçimde şişirmeyiz.
      final includeInAnalytics = transaction.categoryId != 'financing_inflow';

      // Analytics: Tüm normal gider/gelir işlemlerini toplarız.
      if (transaction.type == TransactionType.income) {
        if (includeInAnalytics) {
          totalIncome += normalizedAmount;
          incomeByCurrency[currency] =
              (incomeByCurrency[currency] ?? 0) + amount;

          incomeByCategory[transaction.categoryId] =
              (incomeByCategory[transaction.categoryId] ?? 0) +
                  normalizedAmount;
        }

        if (affectsCashBalance) {
          cashIncome += normalizedAmount;
        }
      } else {
        // Gider işlemleri
        // Standard Ledger Logic: Any expense assigned to an account reduces its balance
        // unless explicitly excluded (reminder/placeholder).

        // Add to main analytics fields (ALL spending)
        totalExpense += normalizedAmount;
        expenseByCurrency[currency] =
            (expenseByCurrency[currency] ?? 0) + amount;

        // If not realized yet, also track as pending
        if (!transaction.isPaid) {
          totalPendingExpense += normalizedAmount;
          pendingExpenseByCurrency[currency] =
              (pendingExpenseByCurrency[currency] ?? 0) + amount;
        }

        if (affectsCashBalance) {
          if (transaction.isPaid) {
            cashExpense += normalizedAmount;
            debugPrint(
                '   💸 CASH Deduction: $normalizedAmount on ${transaction.bankAccountId} (${transaction.note})');
          } else {
            cashPendingExpense += normalizedAmount;
            debugPrint(
                '   ⏳ CASH Pending: $normalizedAmount on ${transaction.bankAccountId} (${transaction.note})');
          }
        }

        // Kategori bazlı döküm (Analytics)
        expenseByCategory[transaction.categoryId] =
            (expenseByCategory[transaction.categoryId] ?? 0) + normalizedAmount;

        // BES / Tasarruf kontrolü
        final category = transaction.category;
        if (category?.isBES ?? false) totalBES += normalizedAmount;
        if (category?.isSaving ?? false) totalSavings += normalizedAmount;

        // Gecikme faizi (Sadece nakit/vadesiz hesaplardaki borçlar için)
        if (transaction.isOverdue &&
            transaction.bankAccountId != null &&
            affectsCashBalance) {
          final bankAccount = bankAccountsMap[transaction.bankAccountId];
          if (bankAccount != null) {
            totalInterest += bankAccount.calculateInterest(
                normalizedAmount, transaction.overdueDays);
          }
          overdueTransactions.add(transaction);
        }
      }
    }

    debugPrint(
        '📊 Summary [Final]: Initial=$initialBalance, Income=$cashIncome, Expense=$cashExpense, Pending=$cashPendingExpense');
    debugPrint('   => Remaining: ${initialBalance + cashIncome - cashExpense}');

    return MonthlySummary(
      year: year,
      month: month,
      initialBalance: initialBalance,
      totalOverdraftLimit: totalOverdraftLimit,
      cashIncome: cashIncome,
      cashExpense: cashExpense,
      cashPendingExpense: cashPendingExpense,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalPendingExpense: totalPendingExpense,
      totalBES: totalBES,
      totalSavings: totalSavings,
      totalInterest: totalInterest,
      pendingPayments: pendingPayments,
      incomeByCurrency: incomeByCurrency,
      expenseByCurrency: expenseByCurrency,
      pendingExpenseByCurrency: pendingExpenseByCurrency,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      overdueTransactions: overdueTransactions,
      pendingPaymentTransactions: pendingPaymentTransactions,
    );
  }

  /// Tüm zamanlar için BES toplamı hesapla
  static double calculateTotalBES(
    List<WalletTransaction> allTransactions, {
    double Function(double amount, String currencyCode)? converter,
  }) {
    double total = 0;
    for (final transaction in allTransactions) {
      // Bakiyeden hariç tutulanları atla
      if (transaction.excludeFromBalance) {
        continue;
      }

      final category = transaction.category;
      if (category?.isBES ?? false) {
        final normalizedAmount = converter != null
            ? converter(transaction.amount, transaction.currencyCode)
            : transaction.amount;
        total += normalizedAmount;
      }
    }
    return total;
  }
}
