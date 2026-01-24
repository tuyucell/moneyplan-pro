import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bank_account.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';

class BankAccountNotifier extends StateNotifier<List<BankAccount>> {
  final String? userId;
  String get _boxName =>
      userId != null ? 'bank_accounts_box_$userId' : 'bank_accounts_box_guest';

  BankAccountNotifier(this.userId) : super(DefaultBankAccounts.accounts) {
    _loadAccounts();
  }

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
  }

  Future<void> updateAccount(BankAccount updatedAccount) async {
    state = [
      for (final account in state)
        if (account.id == updatedAccount.id) updatedAccount else account
    ];
    await _saveToDisk();
  }

  Future<void> addAccount(BankAccount newAccount) async {
    state = [...state, newAccount];
    await _saveToDisk();
  }

  Future<void> deleteAccount(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _saveToDisk();
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
