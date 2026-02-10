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

        final remoteAccounts = response.map((json) {
          return BankAccount(
            id: json['id'] as String,
            name: json['account_name'] as String,
            accountType: json['account_type'] as String,
            initialBalance: (json['balance'] as num).toDouble(),
            currencyCode: json['currency'] as String,
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
      await _client.from('user_bank_accounts').upsert({
        'id': updatedAccount.id,
        'user_id': userId,
        'account_name': updatedAccount.name,
        'account_type': updatedAccount.accountType,
        'balance': updatedAccount.initialBalance,
        'currency': updatedAccount.currencyCode,
      });
    }
  }

  Future<void> addAccount(BankAccount newAccount) async {
    state = [...state, newAccount];
    await _saveToDisk();

    // Sync to Supabase
    if (userId != null) {
      await _client.from('user_bank_accounts').upsert({
        'id': newAccount.id,
        'user_id': userId,
        'account_name': newAccount.name,
        'account_type': newAccount.accountType,
        'balance': newAccount.initialBalance,
        'currency': newAccount.currencyCode,
      });
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

  Future<void> _saveToDisk() async {
    final box = await Hive.openBox(_boxName);
    await box.put('accounts', state.map((e) => e.toJson()).toList());
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
