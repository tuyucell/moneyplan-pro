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

  BankAccountNotifier(this.userId) : super(DefaultBankAccounts.accounts) {
    _loadAccounts();
  }

  final _client = SupabaseService.client;

  Future<void> _loadAccounts() async {
    final box = await Hive.openBox(_boxName);
    final List<dynamic>? savedData = box.get('accounts');

    if (savedData != null) {
      final savedAccounts = savedData
          .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Merge: Keep saved settings for existing accounts, add missing default accounts
      final merged = [...savedAccounts];
      for (final defaultAcc in DefaultBankAccounts.accounts) {
        if (!merged.any((a) => a.id == defaultAcc.id)) {
          merged.add(defaultAcc);
        }
      }
      state = merged;
    }

    // Sync from Supabase
    if (userId != null) {
      try {
        final List<dynamic> response = await _client
            .from('user_bank_accounts')
            .select('*')
            .eq('user_id', userId!);

        final localAccounts = {
          for (final account in state) account.id: account
        };
        final remoteAccounts = response.map((json) {
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
            paymentDay: json['payment_day'] as int? ?? local?.paymentDay ?? 1,
            dueDay: json['due_day'] as int? ?? local?.dueDay ?? 10,
            isActive: json['is_active'] as bool? ?? local?.isActive ?? true,
            createdAt: json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String)
                : local?.createdAt,
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
        }).toList();

        if (remoteAccounts.isNotEmpty) {
          state = remoteAccounts;
          await _saveToDisk();
        }
      } catch (e) {
        // ignore
      }
    }
  }

  Future<void> updateAccount(BankAccount updatedAccount) async {
    state = [
      for (final account in state)
        if (account.id == updatedAccount.id) updatedAccount else account
    ];
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _upsertRemoteAccount(updatedAccount);
    }
  }

  Future<void> addAccount(BankAccount newAccount) async {
    state = [...state, newAccount];
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _upsertRemoteAccount(newAccount);
    }
  }

  Future<void> deleteAccount(String id) async {
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

  Future<void> resetAll() async {
    state = List<BankAccount>.from(DefaultBankAccounts.accounts);
    await _saveToDisk();

    if (userId != null) {
      await _client.from('user_bank_accounts').delete().eq('user_id', userId!);
    }
  }

  Future<void> _saveToDisk() async {
    final box = await Hive.openBox(_boxName);
    await box.put('accounts', state.map((e) => e.toJson()).toList());
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

final bankAccountProvider =
    StateNotifierProvider<BankAccountNotifier, List<BankAccount>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  String? userId;
  if (authState is AuthAuthenticated) {
    userId = authState.user.id;
  }
  return BankAccountNotifier(userId);
});
