import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/yearly_summary.dart';
import 'package:invest_guide/features/wallet/models/monthly_summary.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/core/services/currency_service.dart';
import 'package:invest_guide/features/wallet/models/bank_account.dart';
import 'package:invest_guide/features/wallet/providers/bank_account_provider.dart';

class WalletNotifier extends StateNotifier<List<WalletTransaction>> {
  static const String _boxName = 'wallet_transactions';
  Box<Map>? _box;
  bool _isInitialized = false;
  final _initCompleter = Completer<void>();
  final CurrencyService _currencyService;

  WalletNotifier(this._currencyService) : super([]) {
    _initHive();
  }

  /// Initialize Hive database with error handling
  Future<void> _initHive() async {
    if (_isInitialized) {
      return;
    }

    try {
      _box = await Hive.openBox<Map>(_boxName);
      _loadTransactions();
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error initializing Hive: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = []; // Set empty state on error
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, stackTrace);
      }
      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }

  @override
  void dispose() {
    _box?.close();
    super.dispose();
  }

  /// Load transactions from Hive with error handling
  void _loadTransactions() {
    if (_box == null) return;

    try {
      final transactions = _box!.values.map((map) {
        return WalletTransaction.fromJson(Map<String, dynamic>.from(map));
      }).toList();

      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));
      state = transactions;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error loading transactions: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = []; // Set empty state on error
    }
  }

  /// Add transaction with error handling
  Future<void> addTransaction(WalletTransaction transaction) async {
    try {
      // Wait for initialization
      await _initCompleter.future;

      if (_box == null) {
        throw Exception('Hive box not initialized');
      }

      debugPrint('📥 Hive: Putting transaction ${transaction.id}');
      await _box!.put(transaction.id, transaction.toJson());
      _loadTransactions();
      debugPrint(
          '📥 Hive: Transaction saved, state updated. Count: ${state.length}');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error adding transaction: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }

  /// Update transaction with error handling and rollback
  Future<void> updateTransaction(WalletTransaction transaction) async {
    // Store old state for potential rollback
    final oldState = state;

    try {
      await _initCompleter.future;

      if (_box == null) {
        throw Exception('Hive box not initialized');
      }

      await _box!.put(transaction.id, transaction.toJson());
      _loadTransactions();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error updating transaction: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Rollback state on error
      state = oldState;
      rethrow;
    }
  }

  /// Delete transaction and all its associated records
  Future<void> deleteTransaction(String id) async {
    final oldState = state;

    try {
      await _initCompleter.future;

      if (_box == null) {
        throw Exception('Hive box not initialized');
      }

      // Find all related IDs (paid, skip, overrides)
      final allKeys = _box!.keys.cast<String>();
      final relatedKeys = allKeys
          .where((key) =>
                  key == id || // exact match
                  key.startsWith(
                      '${id}_') // relates (id_YYYYMM, id_paid_YYYYMM, id_skip_YYYYMM)
              )
          .toList();

      for (final key in relatedKeys) {
        await _box!.delete(key);
      }

      _loadTransactions();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error deleting transaction: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Rollback state on error
      state = oldState;
      rethrow;
    }
  }

  Future<void> markAsPaid(String id, bool isPaid) async {
    final oldState = state;
    try {
      await _initCompleter.future;
      if (_box == null) throw Exception('Hive box not initialized');

      final parts = id.split('_');
      final isRecurringInstance =
          parts.length >= 2 && RegExp(r'^\d{6}$').hasMatch(parts.last);

      if (isRecurringInstance) {
        // YearMonth suffix (e.g. 202601)
        final ym = parts.last;
        final year = int.parse(ym.substring(0, 4));
        final month = int.parse(ym.substring(4));

        // Find the instance in generated list
        final instancesTargetMonth =
            _generateRecurringTransactions(year, month);
        final instance = instancesTargetMonth.firstWhere((t) => t.id == id);

        // Materialize it in Hive with the new status
        await addTransaction(instance.copyWith(isPaid: isPaid));
      } else {
        // Check if it already exists in state
        final exists = state.any((t) => t.id == id);
        if (exists) {
          final transaction = state.firstWhere((t) => t.id == id);
          await updateTransaction(transaction.copyWith(isPaid: isPaid));
        } else {
          // If not found in state but called with a normal ID, it might be a newly added transaction
          // that hasn't synced to state yet, but this is rare.
          debugPrint('markAsPaid: Transaction $id not found in state.');
        }
      }
    } catch (e) {
      debugPrint('markAsPaid Error: $e');
      state = oldState;
      rethrow;
    }
  }

  List<WalletTransaction> getTransactionsByMonth(int year, int month) {
    final transactions = state.where((t) {
      // Skip transactions içermeyen ve amount > 0 olan işlemleri dahil et
      return t.date.year == year &&
          t.date.month == month &&
          !t.id.contains('_skip_') &&
          !t.id.contains(
              '_paid_') && // Ödeme kayıtlarını asıl listeden çıkar (gerçek işlem olarak değil, meta veri gibi kullanıyoruz)
          t.amount > 0;
    }).toList();

    // Tekrarlanan işlemleri ekle
    final recurringTransactions = _generateRecurringTransactions(year, month);
    transactions.addAll(recurringTransactions);

    return transactions;
  }

  List<WalletTransaction> _generateRecurringTransactions(int year, int month) {
    final targetDate = DateTime(year, month);
    final recurringTransactions = <WalletTransaction>[];

    for (final transaction in state) {
      if (transaction.recurrence == RecurrenceType.none) continue;

      // Debug: Tekrarlanan işlemleri logla
      if (kDebugMode) {
        debugPrint('🔄 Checking recurring transaction: ${transaction.id}');
        debugPrint(
            '   Type: ${transaction.type}, Category: ${transaction.categoryId}');
        debugPrint(
            '   Recurrence: ${transaction.recurrence}, Amount: ${transaction.amount}');
        debugPrint('   Target month: $year-$month');
      }

      // Tekrarlama bitiş tarihini kontrol et
      if (transaction.recurrenceEndDate != null) {
        if (targetDate.isAfter(transaction.recurrenceEndDate!)) {
          if (kDebugMode) {
            debugPrint('   ❌ Skipped: After recurrence end date');
          }
          continue;
        }
      }

      // İşlem tarihinden sonraki ayları kontrol et
      if (targetDate
          .isBefore(DateTime(transaction.date.year, transaction.date.month))) {
        if (kDebugMode) {
          debugPrint('   ❌ Skipped: Before transaction start date');
        }
        continue;
      }

      var shouldGenerate = false;

      if (transaction.recurrence == RecurrenceType.monthly) {
        // Her ay tekrarlanır (başlangıç ayı hariç - o zaten mevcut)
        if (targetDate
            .isAfter(DateTime(transaction.date.year, transaction.date.month))) {
          shouldGenerate = true;
        }
      } else if (transaction.recurrence == RecurrenceType.yearly) {
        // Her yıl aynı ayda tekrarlanır (başlangıç yılı hariç - o zaten mevcut)
        if (targetDate.month == transaction.date.month &&
            targetDate.year > transaction.date.year) {
          shouldGenerate = true;
        }
      }

      if (shouldGenerate) {
        // Bu ay için "skip" kaydı var mı kontrol et
        final monthStr = month.toString().padLeft(2, '0');
        final skipId = '${transaction.id}_skip_$year$monthStr';
        final isSkipped = state.any((t) => t.id == skipId);

        if (isSkipped) {
          // Bu ay hariç tutulmuş, tekrarlama oluşturma
          if (kDebugMode) {
            debugPrint('   ❌ Skipped: Skip record found for this month');
          }
          continue;
        }

        // Bu ay için el ile oluşturulmuş bir "instance" kaydı var mı?
        // (Orijinal ID + _YYYYMM formatında bir kayıt)
        final instanceId = '${transaction.id}_$year$monthStr';
        final hasOverride = state.any((t) => t.id == instanceId);

        if (hasOverride) {
          // Zaten el ile düzenlenmiş bir kayıt var, orijinalden üretme
          if (kDebugMode) {
            debugPrint('   ❌ Skipped: Override record already exists');
          }
          continue;
        }

        // Vade tarihini de güncelle - orijinal işlemle aynı gün olmalı
        final newDueDate = transaction.dueDate != null
            ? DateTime(year, month,
                transaction.dueDate!.day > 28 ? 28 : transaction.dueDate!.day)
            : null;

        // Her ay için paid kaydı ayrı kontrol edilmeli
        final paidId = '${transaction.id}_paid_$year$monthStr';
        final hasPaidRecord = state.any((t) => t.id == paidId);

        // Eğer paid kaydı varsa onun isPaid değerini kullan
        // Gelirler için varsayılan true, giderler için false (ödenmemiş)
        final isPaidThisMonth = hasPaidRecord
            ? state.firstWhere((t) => t.id == paidId).isPaid
            : (transaction.type == TransactionType.income);

        final recurringInstance = transaction.copyWith(
          id: instanceId, // Use padded ID
          date: DateTime(year, month,
              transaction.date.day > 28 ? 28 : transaction.date.day),
          dueDate: newDueDate,
          isPaid: isPaidThisMonth, // Her ay için ayrı paid durumu
        );

        recurringTransactions.add(recurringInstance);

        if (kDebugMode) {
          debugPrint(
              '   ✅ Generated recurring instance: ${recurringInstance.id}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('   ❌ Should not generate for this month');
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
          '📊 Generated ${recurringTransactions.length} recurring transactions for $year-$month');
    }

    return recurringTransactions;
  }

  MonthlySummary getMonthlySummary(
      int year, int month, List<BankAccount>? accounts) {
    // Collect ALL transactions to calculate brought-forward balance
    // This includes transactions in Hive AND generated recurring transactions for the target month
    // Actually, to be truly accurate, we need ALL transactions from past too.

    // We'll pass state (which contains all Hive transactions)
    return MonthlySummary.fromTransactions(
      state,
      year,
      month,
      bankAccountList: accounts,
      converter: (amount, currencyCode) =>
          _currencyService.convertToTRY(amount, currencyCode),
    );
  }

  YearlySummary getYearlySummary(int year, List<BankAccount>? accounts) {
    final summaries = <MonthlySummary>[];
    for (var month = 1; month <= 12; month++) {
      summaries.add(getMonthlySummary(year, month, accounts));
    }
    return YearlySummary(year: year, monthlySummaries: summaries);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, List<WalletTransaction>>((ref) {
  final currencyService = ref.watch(currencyServiceProvider);
  return WalletNotifier(currencyService);
});

// Provider for current month summary
final currentMonthSummaryProvider = Provider<MonthlySummary>((ref) {
  final now = DateTime.now();
  // Watch the state to trigger rebuild when transactions change
  ref.watch(walletProvider);
  final accounts = ref.watch(bankAccountProvider);
  final notifier = ref.read(walletProvider.notifier);
  return notifier.getMonthlySummary(now.year, now.month, accounts);
});

// Provider for selected month summary
final selectedMonthSummaryProvider =
    Provider.family<MonthlySummary, DateTime>((ref, date) {
  // Watch the state to trigger rebuild when transactions change
  ref.watch(walletProvider);
  final accounts = ref.watch(bankAccountProvider);
  final notifier = ref.read(walletProvider.notifier);
  return notifier.getMonthlySummary(date.year, date.month, accounts);
});

// Provider for total BES balance
final totalBESProvider = Provider<double>((ref) {
  final transactions = ref.watch(walletProvider);
  final currencyService = ref.watch(currencyServiceProvider);
  return MonthlySummary.calculateTotalBES(
    transactions,
    converter: (amount, currencyCode) =>
        currencyService.convertToTRY(amount, currencyCode),
  );
});

// Provider for yearly summary
final yearlySummaryProvider = Provider.family<YearlySummary, int>((ref, year) {
  ref.watch(walletProvider);
  final accounts = ref.watch(bankAccountProvider);
  final notifier = ref.read(walletProvider.notifier);
  return notifier.getYearlySummary(year, accounts);
});

// Provider for active subscriptions this month (Expenses only)
final activeSubscriptionsProvider = Provider<List<WalletTransaction>>((ref) {
  final now = DateTime.now();
  ref.watch(walletProvider);
  final notifier = ref.read(walletProvider.notifier);
  final monthTxs = notifier.getTransactionsByMonth(now.year, now.month);
  return monthTxs
      .where((t) => t.isSubscription && t.type == TransactionType.expense)
      .toList();
});
