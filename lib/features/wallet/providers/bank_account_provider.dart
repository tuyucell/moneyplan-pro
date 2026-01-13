import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bank_account.dart';

class BankAccountNotifier extends StateNotifier<List<BankAccount>> {
  static const String _boxName = 'bank_accounts_box';

  BankAccountNotifier() : super(DefaultBankAccounts.accounts) {
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
  return BankAccountNotifier();
});
