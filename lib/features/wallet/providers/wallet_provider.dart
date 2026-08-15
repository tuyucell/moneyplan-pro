import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/yearly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/services/installment_schedule_service.dart';
import 'package:moneyplan_pro/features/wallet/services/statement_charge_service.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/services/api/supabase_service.dart';

class WalletNotifier extends StateNotifier<List<WalletTransaction>> {
  final String? userId;
  String get _boxName => userId != null
      ? 'wallet_transactions_$userId'
      : 'wallet_transactions_guest';
  String get _pendingClearKey =>
      'wallet_pending_remote_clear_${userId ?? 'guest'}';
  String get _deletedIdsKey => 'wallet_deleted_remote_ids_${userId ?? 'guest'}';

  Box<Map>? _box;
  bool _isInitialized = false;
  final _initCompleter = Completer<void>();
  final CurrencyService _currencyService;
  final List<BankAccount> _accounts;
  Timer? _statementChargeTimer;
  bool _pendingRemoteClear = false;
  final Set<String> _pendingRemoteDeletionIds = {};

  WalletNotifier(this._currencyService, this.userId, this._accounts)
      : super([]) {
    _initHive();
  }

  /// Initialize Hive database with error handling
  Future<void> _initHive() async {
    if (_isInitialized) {
      return;
    }

    try {
      _box = await Hive.openBox<Map>(_boxName);
      await _loadSyncMetadata();
      _loadTransactions();

      // Sync with Supabase if logged in
      if (userId != null) {
        final client = SupabaseService.client;
        await _retryPendingRemoteClear();

        if (_pendingRemoteClear) {
          _finishInitialization();
          return;
        }

        final List<dynamic> response = await client
            .from('user_transactions')
            .select('*')
            .eq('user_id', userId!);

        final remoteTransactions = response.map((json) {
          return WalletTransaction(
            id: json['id'] as String,
            amount: (json['amount'] as num).toDouble(),
            categoryId: json['category_id'] as String? ?? 'unknown',
            note: json['description'] as String?,
            date: DateTime.parse(json['date'] as String),
            type: TransactionType.values.firstWhere(
              (e) => e.name == (json['type'] as String).toLowerCase(),
              orElse: () => TransactionType.expense,
            ),
            currencyCode: json['currency'] as String? ?? 'TRY',
            bankAccountId: json['account_id'] as String?,
            recurrence: json['is_recurring'] == true
                ? RecurrenceType.values.firstWhere(
                    (e) => e.name == json['recurrence_type'],
                    orElse: () => RecurrenceType.none,
                  )
                : RecurrenceType.none,
            recurrenceEndDate: json['recurrence_end_date'] != null
                ? DateTime.parse(json['recurrence_end_date'] as String)
                : null,
            dueDate: json['due_date'] != null
                ? DateTime.parse(json['due_date'] as String)
                : null,
            isPaid: json['is_paid'] as bool? ?? false,
            paymentMethod: PaymentMethod.values.firstWhere(
              (method) => method.name == json['payment_method'],
              orElse: () => PaymentMethod.cash,
            ),
            excludeFromBalance: json['exclude_from_balance'] as bool? ?? false,
            linkedTransactionId: json['linked_transaction_id'] as String?,
          );
        }).where((transaction) {
          return !_pendingRemoteDeletionIds.contains(transaction.id);
        }).toList();

        if (remoteTransactions.isNotEmpty) {
          // Update Hive with remote data in batch
          final batch = {
            for (final tx in remoteTransactions) tx.id: tx.toJson()
          };
          await _box!.putAll(batch);
          _loadTransactions();
        }
        await _retryPendingRemoteDeletes();
      }

      _finishInitialization();
      try {
        await _syncStatementCharges();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Statement charge sync failed: $error');
          debugPrint('$stackTrace');
        }
      }
      _scheduleStatementChargeSync();
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

  void _finishInitialization() {
    _isInitialized = true;
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> _loadSyncMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingRemoteClear = prefs.getBool(_pendingClearKey) ?? false;
    _pendingRemoteDeletionIds
      ..clear()
      ..addAll(prefs.getStringList(_deletedIdsKey) ?? const []);
  }

  Future<void> _saveSyncMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingClearKey, _pendingRemoteClear);
    await prefs.setStringList(
      _deletedIdsKey,
      _pendingRemoteDeletionIds.toList()..sort(),
    );
  }

  Future<void> _retryPendingRemoteDeletes() async {
    if (userId == null || _pendingRemoteDeletionIds.isEmpty) return;
    final deleted = <String>{};
    for (final id in _pendingRemoteDeletionIds) {
      try {
        await SupabaseService.client
            .from('user_transactions')
            .delete()
            .eq('user_id', userId!)
            .eq('id', id);
        deleted.add(id);
      } catch (_) {
        // Keep the tombstone and retry on next initialization.
      }
    }
    if (deleted.isNotEmpty) {
      _pendingRemoteDeletionIds.removeAll(deleted);
      await _saveSyncMetadata();
    }
  }

  Future<void> _retryPendingRemoteClear() async {
    if (userId == null || !_pendingRemoteClear) return;
    try {
      await SupabaseService.client
          .from('user_transactions')
          .delete()
          .eq('user_id', userId!);
      _pendingRemoteClear = false;
      _pendingRemoteDeletionIds.clear();
      await _saveSyncMetadata();
    } catch (_) {
      // Keep the local reset authoritative and retry before the next sync.
    }
  }

  @override
  void dispose() {
    _statementChargeTimer?.cancel();
    _box?.close();
    super.dispose();
  }

  Future<void> _syncStatementCharges() async {
    final pendingCharges = <WalletTransaction>[];
    final asOf = DateTime.now();
    for (final account in _accounts) {
      final openingDebtId =
          InstallmentScheduleService.openingDebtTransactionId(account.id);
      if (account.accountType == 'Kredi Kartı' &&
          account.initialBalance >= 0 &&
          state.any((transaction) => transaction.id == openingDebtId)) {
        await deleteTransaction(openingDebtId);
      }
      pendingCharges.addAll(
        InstallmentScheduleService.createDueTransactions(
          account: account,
          transactions: [...state, ...pendingCharges],
          asOf: asOf,
        ),
      );
      final statementPlan = StatementChargeService.buildPlan(
        account: account,
        transactions: [...state, ...pendingCharges],
        asOf: asOf,
      );
      for (final transactionId in statementPlan.removals) {
        await deleteTransaction(transactionId);
      }
      pendingCharges.addAll(statementPlan.upserts);
    }
    if (pendingCharges.isNotEmpty) {
      await addTransactions(pendingCharges);
    }
  }

  void _scheduleStatementChargeSync() {
    _statementChargeTimer?.cancel();
    _statementChargeTimer = Timer(const Duration(hours: 6), () async {
      try {
        await _syncStatementCharges();
      } finally {
        if (mounted) _scheduleStatementChargeSync();
      }
    });
  }

  /// Load transactions from Hive with error handling
  void _loadTransactions() {
    if (_box == null) return;

    try {
      final transactions = _box!.values
          .map((map) {
            return WalletTransaction.fromJson(Map<String, dynamic>.from(map));
          })
          .where(
            (transaction) =>
                !_pendingRemoteDeletionIds.contains(transaction.id),
          )
          .toList();

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

  /// Add multiple transactions with atomic local save and batch sync
  Future<void> addTransactions(List<WalletTransaction> transactions) async {
    try {
      await _initCompleter.future;
      if (_box == null) throw Exception('Hive box not initialized');

      final revivedIds = transactions
          .map((transaction) => transaction.id)
          .where(_pendingRemoteDeletionIds.contains)
          .toSet();
      if (revivedIds.isNotEmpty) {
        _pendingRemoteDeletionIds.removeAll(revivedIds);
        await _saveSyncMetadata();
      }

      debugPrint('📥 Hive: Putting ${transactions.length} transactions');
      for (final tx in transactions) {
        await _box!.put(tx.id, tx.toJson());
      }
      _loadTransactions();

      // Sync to Supabase in background
      if (userId != null) {
        await _retryPendingRemoteClear();
        if (_pendingRemoteClear) return;
        final client = SupabaseService.client;
        // Supabase upsert handles batches naturally if we pass a list
        final batch = transactions
            .map((t) => {
                  'id': t.id,
                  'user_id': userId,
                  'amount': t.amount,
                  'type': t.type.name,
                  'category_id': t.categoryId,
                  'description': t.note,
                  'date': t.date.toIso8601String(),
                  'currency': t.currencyCode,
                  'account_id': t.bankAccountId,
                  'is_recurring': t.recurrence != RecurrenceType.none,
                  'recurrence_type': t.recurrence.name,
                  'recurrence_end_date': t.recurrenceEndDate?.toIso8601String(),
                  'due_date': t.dueDate?.toIso8601String(),
                  'is_paid': t.isPaid,
                  'payment_method': t.paymentMethod.name,
                  'exclude_from_balance': t.excludeFromBalance,
                  'linked_transaction_id': t.linkedTransactionId,
                })
            .toList();

        await client.from('user_transactions').upsert(batch);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error adding transactions: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Add transaction with error handling
  Future<void> addTransaction(WalletTransaction transaction) async {
    await addTransactions([transaction]);
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

      if (_pendingRemoteDeletionIds.remove(transaction.id)) {
        await _saveSyncMetadata();
      }

      await _box!.put(transaction.id, transaction.toJson());
      _loadTransactions();

      // Sync to Supabase
      if (userId != null) {
        await _retryPendingRemoteClear();
        if (_pendingRemoteClear) return;
        final client = SupabaseService.client;
        await client.from('user_transactions').upsert({
          'id': transaction.id,
          'user_id': userId,
          'amount': transaction.amount,
          'type': transaction.type.name,
          'category_id': transaction.categoryId,
          'description': transaction.note,
          'date': transaction.date.toIso8601String(),
          'currency': transaction.currencyCode,
          'account_id': transaction.bankAccountId,
          'is_recurring': transaction.recurrence != RecurrenceType.none,
          'recurrence_type': transaction.recurrence.name,
          'recurrence_end_date':
              transaction.recurrenceEndDate?.toIso8601String(),
          'due_date': transaction.dueDate?.toIso8601String(),
          'is_paid': transaction.isPaid,
          'payment_method': transaction.paymentMethod.name,
          'exclude_from_balance': transaction.excludeFromBalance,
          'linked_transaction_id': transaction.linkedTransactionId,
        });
      }
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
    await _initCompleter.future;
    if (_box == null) {
      throw Exception('Hive box not initialized');
    }

    final idsToDelete = <String>{id};
    idsToDelete.addAll(
      _box!.keys.cast<String>().where(
            (key) => key == id || key.startsWith('${id}_'),
          ),
    );

    _pendingRemoteDeletionIds.addAll(idsToDelete);
    await _saveSyncMetadata();

    for (final key in idsToDelete) {
      await _box!.delete(key);
    }

    // Update the visible list before waiting for network I/O.
    state = state
        .where((transaction) => !idsToDelete.contains(transaction.id))
        .toList();

    if (userId != null) {
      final deletedRemotely = <String>{};
      for (final transactionId in idsToDelete) {
        try {
          await SupabaseService.client
              .from('user_transactions')
              .delete()
              .eq('user_id', userId!)
              .eq('id', transactionId);
          deletedRemotely.add(transactionId);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('Remote transaction delete deferred: $error');
            debugPrint('$stackTrace');
          }
        }
      }
      _pendingRemoteDeletionIds.removeAll(deletedRemotely);
    } else {
      _pendingRemoteDeletionIds.removeAll(idsToDelete);
    }
    await _saveSyncMetadata();
  }

  static String? recurringSourceId(String transactionId) {
    final match = RegExp(r'^(.*)_(\d{6})$').firstMatch(transactionId);
    return match?.group(1);
  }

  /// Removes one generated recurrence without deleting its source or future
  /// months. A zero-value skip marker is persisted and synced.
  Future<void> deleteTransactionOccurrence(
    WalletTransaction transaction,
  ) async {
    final sourceId = recurringSourceId(transaction.id);
    WalletTransaction? source;
    if (sourceId != null) {
      for (final item in state) {
        if (item.id == sourceId) {
          source = item;
          break;
        }
      }
    }
    if (source == null || source.recurrence == RecurrenceType.none) {
      await deleteTransaction(transaction.id);
      return;
    }

    final yearMonth = transaction.id.substring(transaction.id.length - 6);
    final skipId = '${source.id}_skip_$yearMonth';
    await addTransaction(
      transaction.copyWith(
        id: skipId,
        amount: 0,
        note: 'Skipped recurrence: ${source.id}',
        recurrence: RecurrenceType.none,
        applyMonthly: false,
        excludeFromBalance: true,
      ),
    );
  }

  /// Removes only ledger rows generated from a bank/card configuration.
  /// Manual expenses and payments intentionally remain untouched.
  Future<void> deleteGeneratedTransactionsForAccount(String accountId) async {
    await _initCompleter.future;
    if (_box == null) {
      throw Exception('Hive box not initialized');
    }

    final generatedIds = state
        .where(
          (transaction) =>
              transaction.bankAccountId == accountId &&
              (transaction.id ==
                      InstallmentScheduleService.openingDebtTransactionId(
                        accountId,
                      ) ||
                  transaction.id.startsWith(
                    'card_installment_${accountId}_',
                  ) ||
                  transaction.id.startsWith(
                    'statement_interest_${accountId}_',
                  ) ||
                  transaction.id.startsWith(
                    'statement_tax_${accountId}_',
                  )),
        )
        .map((transaction) => transaction.id)
        .toSet();

    _pendingRemoteDeletionIds.addAll(generatedIds);
    await _saveSyncMetadata();
    for (final id in generatedIds) {
      await _box!.delete(id);
    }
    state = state
        .where((transaction) => !generatedIds.contains(transaction.id))
        .toList();

    if (userId != null) {
      final deletedRemotely = <String>{};
      for (final id in generatedIds) {
        try {
          await SupabaseService.client
              .from('user_transactions')
              .delete()
              .eq('user_id', userId!)
              .eq('id', id);
          deletedRemotely.add(id);
        } catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('Remote generated transaction delete deferred: $error');
            debugPrint('$stackTrace');
          }
        }
      }
      _pendingRemoteDeletionIds.removeAll(deletedRemotely);
    } else {
      _pendingRemoteDeletionIds.removeAll(generatedIds);
    }
    await _saveSyncMetadata();
  }

  Future<void> clearAllTransactions() async {
    await _initCompleter.future;
    if (_box == null) {
      throw Exception('Hive box not initialized');
    }

    _pendingRemoteClear = userId != null;
    _pendingRemoteDeletionIds.clear();
    await _saveSyncMetadata();

    await _box!.clear();
    state = const [];

    if (userId != null) {
      try {
        await SupabaseService.client
            .from('user_transactions')
            .delete()
            .eq('user_id', userId!);
        _pendingRemoteClear = false;
        await _saveSyncMetadata();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('Remote transaction clear deferred: $error');
          debugPrint('$stackTrace');
        }
      }
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
            generateRecurringTransactionsForMonth(state, year, month);
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
    final recurringTransactions =
        generateRecurringTransactionsForMonth(state, year, month);
    transactions.addAll(recurringTransactions);

    return transactions;
  }

  static List<WalletTransaction> generateRecurringTransactionsForMonth(
    List<WalletTransaction> source,
    int year,
    int month,
  ) {
    final targetDate = DateTime(year, month);
    final recurringTransactions = <WalletTransaction>[];

    for (final transaction in source) {
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
        final isSkipped = source.any((t) => t.id == skipId);

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
        final hasOverride = source.any((t) => t.id == instanceId);

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
        final hasPaidRecord = source.any((t) => t.id == paidId);

        // Eğer paid kaydı varsa onun isPaid değerini kullan
        // Gelirler için varsayılan true, giderler için false (ödenmemiş)
        final isPaidThisMonth = hasPaidRecord
            ? source.firstWhere((t) => t.id == paidId).isPaid
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
    final transactions = List<WalletTransaction>.from(state)
      ..addAll(generateRecurringTransactionsForMonth(state, year, month));

    return MonthlySummary.fromTransactions(
      transactions,
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
  final accounts = ref.watch(bankAccountProvider);
  final authState = ref.watch(authNotifierProvider);
  String? userId;
  if (authState is AuthAuthenticated) {
    userId = authState.user.id;
  }
  return WalletNotifier(currencyService, userId, accounts);
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

// Helper class for account metrics
class AccountStats {
  final Map<String, double> balances;
  final double interest;
  final double tax;

  AccountStats({
    required this.balances,
    this.interest = 0.0,
    this.tax = 0.0,
  });
}

// Provider for all account statistics (Balances, Costs)
// Returns Map<BankId, AccountStats>
final accountStatsProvider = Provider<Map<String, AccountStats>>((ref) {
  final transactions = ref.watch(walletProvider);
  final accounts = ref.watch(bankAccountProvider);

  final stats = <String, AccountStats>{};
  final accountsById = {for (final account in accounts) account.id: account};

  // Initialize with initial balances from accounts
  for (final acc in accounts) {
    stats[acc.id] = AccountStats(
      balances: {acc.currencyCode: acc.initialBalance},
      interest: 0.0,
      tax: 0.0,
    );
  }

  // Apply all transactions
  for (final tx in transactions) {
    if (tx.bankAccountId == null || tx.excludeFromBalance) continue;

    final bankId = tx.bankAccountId!;
    final account = accountsById[bankId];
    final effectiveDate = account?.balanceEffectiveDate ?? account?.createdAt;
    if (effectiveDate != null && tx.date.isBefore(effectiveDate)) continue;
    if (!stats.containsKey(bankId)) {
      stats[bankId] = AccountStats(balances: {});
    }

    final currentStats = stats[bankId]!;
    final balances = currentStats.balances;
    final currency = tx.currencyCode.isEmpty ? 'TRY' : tx.currencyCode;
    final currentBalance = balances[currency] ?? 0.0;

    // 1. Update Balance
    if (tx.type == TransactionType.income) {
      balances[currency] = currentBalance + tx.amount;
    } else {
      balances[currency] = currentBalance - tx.amount;
    }

    // 2. Update Costs (Interest/Tax)
    // Note: These are already subtracted from balance above,
    // we just track them separately for UI display.
    var newInterest = currentStats.interest;
    var newTax = currentStats.tax;

    if (tx.categoryId == 'bank_interest') {
      newInterest += tx.amount;
    } else if (tx.categoryId == 'bank_tax') {
      newTax += tx.amount;
    }

    stats[bankId] = AccountStats(
      balances: balances,
      interest: newInterest,
      tax: newTax,
    );
  }

  return stats;
});
