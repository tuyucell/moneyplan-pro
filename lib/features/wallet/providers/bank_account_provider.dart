import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bank_account.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/services/api/supabase_service.dart';

class BankAccountNotifier extends StateNotifier<List<BankAccount>> {
  final String? userId;
  String get _boxName =>
      userId != null ? 'bank_accounts_box_$userId' : 'bank_accounts_box_guest';

  final Set<String> _deletedAccountIds = {};

  BankAccountNotifier(this.userId) : super(const []) {
    _loadAccounts();
  }

  final _client = SupabaseService.client;

  Future<void> _loadAccounts() async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic>? savedData = box.get('accounts');
    final deletedData = box.get('deleted_account_ids');
    if (deletedData is List) {
      _deletedAccountIds.addAll(deletedData.whereType<String>());
    }

    final hasLocalSnapshot = savedData != null;
    final savedAccounts = (savedData ?? const [])
        .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e)))
        .where((account) => !_deletedAccountIds.contains(account.id))
        .toList();

    state = hasLocalSnapshot
        ? savedAccounts
        : DefaultBankAccounts.accounts
            .where((account) => !_deletedAccountIds.contains(account.id))
            .toList();

    // Sync from Supabase
    if (userId != null) {
      try {
        final List<dynamic> response = await _client
            .from('user_bank_accounts')
            .select('*')
            .eq('user_id', userId!);

        final localAccounts = {
          for (final account in savedAccounts) account.id: account
        };
        final remoteAccounts = response
            .map((json) {
              final local = localAccounts[json['id'] as String];
              final remoteInstallmentPlan = json['installment_plan'];
              return BankAccount(
                id: json['id'] as String,
                name: json['account_name'] as String,
                accountType: json['account_type'] as String,
                initialBalance: (json['balance'] as num).toDouble(),
                currencyCode: json['currency'] as String,
                overdraftInterestRate:
                    (json['monthly_interest_rate'] as num?)?.toDouble() ??
                        local?.overdraftInterestRate ??
                        4.5,
                bsmvRate: (json['bsmv_rate'] as num?)?.toDouble() ??
                    local?.bsmvRate ??
                    15,
                kkdfRate: (json['kkdf_rate'] as num?)?.toDouble() ??
                    local?.kkdfRate ??
                    15,
                overdraftLimit: (json['overdraft_limit'] as num?)?.toDouble() ??
                    local?.overdraftLimit ??
                    0,
                paymentDay:
                    json['payment_day'] as int? ?? local?.paymentDay ?? 1,
                dueDay: json['due_day'] as int? ?? local?.dueDay ?? 10,
                dueDaysAfterStatement:
                    json['due_days_after_statement'] as int? ??
                        local?.dueDaysAfterStatement ??
                        10,
                isActive: json['is_active'] as bool? ?? local?.isActive ?? true,
                createdAt: json['created_at'] != null
                    ? DateTime.tryParse(json['created_at'] as String)
                    : local?.createdAt,
                balanceEffectiveDate: json['balance_effective_date'] != null
                    ? DateTime.tryParse(
                        json['balance_effective_date'] as String)
                    : local?.balanceEffectiveDate,
                updatedAt: json['updated_at'] != null
                    ? DateTime.tryParse(json['updated_at'] as String)
                    : null,
                installmentPlan: remoteInstallmentPlan is List
                    ? remoteInstallmentPlan
                        .whereType<Map>()
                        .map(
                          (entry) => CreditCardInstallmentEntry.fromJson(
                            Map<String, dynamic>.from(entry),
                          ),
                        )
                        .toList()
                    : local?.installmentPlan ?? const [],
              );
            })
            .where((account) => !_deletedAccountIds.contains(account.id))
            .toList();

        state = mergeBankAccountSnapshots(
          local: savedAccounts,
          remote: remoteAccounts,
          hasLocalSnapshot: hasLocalSnapshot,
          defaults: DefaultBankAccounts.accounts,
          deletedIds: _deletedAccountIds,
        );
        await _saveToDisk();
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> updateAccount(BankAccount updatedAccount) async {
    final normalized = updatedAccount.copyWith(updatedAt: DateTime.now());
    _deletedAccountIds.remove(normalized.id);
    state = [
      for (final account in state)
        if (account.id == normalized.id) normalized else account
    ];
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _upsertRemoteAccount(normalized);
    }
  }

  Future<void> addAccount(BankAccount newAccount) async {
    final normalized = newAccount.copyWith(updatedAt: DateTime.now());
    _deletedAccountIds.remove(normalized.id);
    state = [
      ...state.where((account) => account.id != normalized.id),
      normalized
    ];
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _upsertRemoteAccount(normalized);
    }
  }

  Future<void> deleteAccount(String id) async {
    _deletedAccountIds.add(id);
    state = state.where((a) => a.id != id).toList();
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _client
          .from('user_bank_accounts')
          .delete()
          .eq('user_id', userId!)
          .eq('id', id);
    }
  }

  Future<void> resetCashBalances() async {
    await _resetBalances(
      (account) => account.accountType != 'Kredi Kartı',
    );
  }

  Future<void> resetCreditCardBalances() async {
    await _resetBalances(
      (account) => account.accountType == 'Kredi Kartı',
    );
  }

  Future<void> resetAllBalances() async {
    await _resetBalances((_) => true);
  }

  /// Resets current debt/cash snapshots while preserving the user's account
  /// configuration (name, limit, rates, statement and due-date settings).
  Future<void> _resetBalances(bool Function(BankAccount) shouldReset) async {
    final now = DateTime.now();
    final changed = <BankAccount>[];
    state = state.map((account) {
      if (!shouldReset(account)) return account;
      final reset = resetBankAccountBalanceSnapshot(account, now);
      changed.add(reset);
      return reset;
    }).toList();
    await _saveToDisk();

    if (userId != null) {
      for (final account in changed) {
        try {
          await _upsertRemoteAccount(account);
        } catch (_) {
          // Local state remains authoritative through its newer updatedAt.
        }
      }
    }
  }

  Future<void> _saveToDisk() async {
    final box = await Hive.openBox(_boxName);
    await box.put('accounts', state.map((e) => e.toJson()).toList());
    await box.put('deleted_account_ids', _deletedAccountIds.toList());
  }

  Future<void> _upsertRemoteAccount(BankAccount account) async {
    if (userId == null) return;
    final basePayload = {
      'id': account.id,
      'user_id': userId,
      'account_name': account.name,
      'account_type': account.accountType,
      'balance': account.initialBalance,
      'currency': account.currencyCode,
      'updated_at': (account.updatedAt ?? DateTime.now()).toIso8601String(),
    };

    try {
      await _client.from('user_bank_accounts').upsert({
        ...basePayload,
        'monthly_interest_rate': account.overdraftInterestRate,
        'bsmv_rate': account.bsmvRate,
        'kkdf_rate': account.kkdfRate,
        'overdraft_limit': account.overdraftLimit,
        'payment_day': account.paymentDay,
        'due_day': account.dueDay,
        'due_days_after_statement': account.dueDaysAfterStatement,
        'balance_effective_date':
            account.balanceEffectiveFrom.toIso8601String(),
        'is_active': account.isActive,
        'installment_plan':
            account.installmentPlan.map((entry) => entry.toJson()).toList(),
      });
    } catch (_) {
      // Older deployments may not have the finance columns yet. Keep account
      // creation functional; Hive remains the source for the extra settings.
      await _client.from('user_bank_accounts').upsert(basePayload);
    }
  }
}

BankAccount resetBankAccountBalanceSnapshot(
  BankAccount account,
  DateTime effectiveDate,
) {
  return account.copyWith(
    initialBalance: 0,
    balanceEffectiveDate: effectiveDate,
    updatedAt: effectiveDate,
    installmentPlan: account.accountType == 'Kredi Kartı'
        ? const []
        : account.installmentPlan,
  );
}

List<BankAccount> mergeBankAccountSnapshots({
  required List<BankAccount> local,
  required List<BankAccount> remote,
  required bool hasLocalSnapshot,
  required List<BankAccount> defaults,
  Set<String> deletedIds = const {},
}) {
  if (!hasLocalSnapshot) {
    final source = remote.isNotEmpty ? remote : defaults;
    return source.where((account) => !deletedIds.contains(account.id)).toList();
  }

  final merged = <String, BankAccount>{
    for (final account in local)
      if (!deletedIds.contains(account.id)) account.id: account,
  };

  for (final remoteAccount in remote) {
    if (deletedIds.contains(remoteAccount.id)) continue;
    final localAccount = merged[remoteAccount.id];
    if (localAccount == null) {
      merged[remoteAccount.id] = remoteAccount;
      continue;
    }

    // Legacy local records do not have an updatedAt value. They are kept as
    // the safest source so an app update cannot replace user customizations
    // with an older/default cloud row.
    final localUpdatedAt = localAccount.updatedAt;
    final remoteUpdatedAt = remoteAccount.updatedAt;
    if (localUpdatedAt != null &&
        remoteUpdatedAt != null &&
        remoteUpdatedAt.isAfter(localUpdatedAt)) {
      merged[remoteAccount.id] = remoteAccount;
    }
  }

  return merged.values.toList();
}

final bankAccountProvider =
    StateNotifierProvider<BankAccountNotifier, List<BankAccount>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  String? userId;
  if (authState is AuthAuthenticated) {
    userId = authState.user.id;
  }
  return BankAccountNotifier(userId);
});
