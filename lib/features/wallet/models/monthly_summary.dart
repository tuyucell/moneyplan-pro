import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/features/wallet/models/bank_account.dart';

class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense; // Sadece ödenen giderler
  final double totalPendingExpense; // Ödenmemiş giderler
  final double totalBES; // BES katkıları (pozitif tutar olarak)
  final double totalSavings; // Toplam tasarruf/yatırım (BES dahil)
  final double totalInterest; // Gecikme faizleri
  final Map<String, double> incomeByCategory;
  final Map<String, double> expenseByCategory;
  final List<WalletTransaction> overdueTransactions;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalPendingExpense,
    required this.totalBES,
    required this.totalSavings,
    required this.totalInterest,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.overdueTransactions,
  });

  // Kalan Bakiye: Toplam Gelir - Toplam Gider (Ödenen + Ödenmemiş)
  double get remainingBalance =>
      totalIncome - (totalExpense + totalPendingExpense);

  // Toplam Gider (Ödenen + Ödenmemiş)
  double get totalOutflow => totalExpense + totalPendingExpense;

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
    List<WalletTransaction> transactions,
    int year,
    int month, {
    Map<String, BankAccount>? bankAccounts,
    double Function(double amount, String currencyCode)? converter,
  }) {
    final monthTransactions = transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0; // Ödenen giderler
    double totalPendingExpense = 0; // Ödenmemiş giderler
    double totalBES = 0;
    double totalSavings = 0;
    double totalInterest = 0;
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};
    final overdueTransactions = <WalletTransaction>[];

    for (final transaction in monthTransactions) {
      // Normalize amount to base currency (TRY) for totals
      final normalizedAmount = converter != null
          ? converter(transaction.amount, transaction.currencyCode)
          : transaction.amount;

      // BES kontrolü
      final category = transaction.category;
      final isBES = category?.isBES ?? false;

      if (transaction.type == TransactionType.income) {
        totalIncome += normalizedAmount;
        incomeByCategory[transaction.categoryId] =
            (incomeByCategory[transaction.categoryId] ?? 0) + normalizedAmount;
      } else {
        // BES ayrı hesaplanır
        if (isBES) {
          totalBES += normalizedAmount;
        }

        // Tasarruf/Yatırım kontrolü
        if (category?.isSaving ?? false) {
          totalSavings += normalizedAmount;
        }

        // Ödenen ve ödenmemiş giderler
        if (transaction.isPaid) {
          totalExpense += normalizedAmount;
        } else {
          totalPendingExpense += normalizedAmount;
        }

        // Her iki durumda da kategori dökümüne ekle (kullanıcı listede görmeli)
        expenseByCategory[transaction.categoryId] =
            (expenseByCategory[transaction.categoryId] ?? 0) + normalizedAmount;

        // Gecikme faizi hesaplama
        if (transaction.isOverdue && transaction.bankAccountId != null) {
          final bankAccount = bankAccounts?[transaction.bankAccountId];
          if (bankAccount != null) {
            // Faiz de normalize edilmeli (banka hesabı para birimine göre veya TRY)
            // Banka hesabının kendi para birimi desteği de eklendiği için
            // Burada basitleştirmek için TRY üzerinden gidiyoruz
            final interest = bankAccount.calculateInterest(
              normalizedAmount,
              transaction.overdueDays,
            );
            totalInterest += interest;
          }
          overdueTransactions.add(transaction);
        }
      }
    }

    return MonthlySummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalPendingExpense: totalPendingExpense,
      totalBES: totalBES,
      totalSavings: totalSavings,
      totalInterest: totalInterest,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      overdueTransactions: overdueTransactions,
    );
  }

  /// Tüm zamanlar için BES toplamı hesapla
  static double calculateTotalBES(
    List<WalletTransaction> allTransactions, {
    double Function(double amount, String currencyCode)? converter,
  }) {
    double total = 0;
    for (final transaction in allTransactions) {
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
