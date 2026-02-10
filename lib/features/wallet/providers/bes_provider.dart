import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bes_models.dart';

class BesNotifier extends StateNotifier<BesAccount?> {
  static const String _boxName = 'bes_account';
  Box? _box;

  BesNotifier() : super(null) {
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox(_boxName);
    _loadAccount();
  }

  void _loadAccount() {
    if (_box == null || _box!.isEmpty) return;
    final map = _box!.get('current');
    if (map != null) {
      state = BesAccount.fromJson(Map<String, dynamic>.from(map));
    }
  }

  Future<void> updateAccount(BesAccount account) async {
    state = account;
    await _box?.put('current', account.toJson());
  }

  Future<void> clearAccount() async {
    state = null;
    await _box?.clear();
  }
}

final besProvider = StateNotifierProvider<BesNotifier, BesAccount?>((ref) {
  return BesNotifier();
});
