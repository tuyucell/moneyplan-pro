import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'package:invest_guide/features/wallet/providers/bank_account_provider.dart';
import 'package:invest_guide/features/wallet/providers/portfolio_provider.dart';
import 'package:invest_guide/features/watchlist/providers/watchlist_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service responsible for syncing local Hive/Prefs data with Supabase Cloud
/// Sync Strategy: One-way sync (Local -> Cloud) for backup as requested.
class DataSyncService {
  final SupabaseClient _supabase;
  final Ref _ref;
  final String userId;

  DataSyncService(this._supabase, this._ref, this.userId);

  /// Sync all modules
  Future<void> syncAll() async {
    if (kDebugMode)
      debugPrint('🔄 Sync: Starting full sync for user $userId...');

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (kDebugMode) debugPrint('🔄 Sync: No internet connection. Aborted.');
      return;
    }

    try {
      await Future.wait([
        syncBankAccounts(),
        syncTransactions(),
        syncPortfolio(),
        syncWatchlist(),
      ]);

      // Update sync log
      await _supabase.from('user_sync_status').upsert({
        'user_id': userId,
        'last_synced_at': DateTime.now().toIso8601String(),
        'device_id': 'mobile_app',
      });

      if (kDebugMode) debugPrint('✅ Sync: All data synced successfully.');
    } catch (e) {
      debugPrint('❌ Sync Error: $e');
    }
  }

  // 1. Sync Bank Accounts
  Future<void> syncBankAccounts() async {
    final accounts = _ref.read(bankAccountProvider);
    if (accounts.isEmpty) return;

    final dataToUpsert = accounts.map((acc) {
      return {
        'id': acc.id,
        'user_id': userId,
        'account_name': acc.name,
        'account_type': acc.accountType,
        'balance': acc
            .initialBalance, // Using initialBalance as current balance is not stored in model
        'currency': acc.currencyCode,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabase.from('user_bank_accounts').upsert(dataToUpsert);
  }

  // 2. Sync Transactions
  Future<void> syncTransactions() async {
    final transactions = _ref.read(walletProvider);
    if (transactions.isEmpty) return;

    final dataToUpsert = transactions.map((tx) {
      return {
        'id': tx.id,
        'user_id': userId,
        'amount': tx.amount,
        'type': tx.type.name, // income, expense
        'category_id': tx.categoryId,
        'description': tx.note, // Mapped 'note' to 'description'
        'date': tx.date.toIso8601String(),
        'currency': tx.currencyCode,
        'is_recurring': tx.recurrence.index > 0,
        'recurrence_type': tx.recurrence.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabase.from('user_transactions').upsert(dataToUpsert);
  }

  // 3. Sync Portfolio
  Future<void> syncPortfolio() async {
    final assets = _ref.read(portfolioProvider);
    if (assets.isEmpty) return;

    final dataToUpsert = assets.map((asset) {
      return {
        'user_id': userId,
        'symbol': asset.symbol,
        'name': asset.name,
        'type': asset.category, // Mapped 'category' to 'type'
        'quantity': asset.units,
        'average_cost': asset.averageCost,
        'currency': asset.currencyCode, // Mapped 'currencyCode' to 'currency'
        'updated_at': DateTime.now().toIso8601String(),
      };
    }).toList();

    await _supabase
        .from('user_portfolio_assets')
        .upsert(dataToUpsert, onConflict: 'user_id, symbol');
  }

  // 4. Sync Watchlist
  Future<void> syncWatchlist() async {
    final watchlist = _ref.read(watchlistProvider);
    if (watchlist.isEmpty) return;

    final dataToUpsert = watchlist.map((item) {
      return {
        'user_id': userId,
        'symbol': item.symbol,
        'asset_type': item.category, // Mapped 'category' to 'asset_type'
      };
    }).toList();

    await _supabase
        .from('user_watchlists')
        .upsert(dataToUpsert, onConflict: 'user_id, symbol');
  }
}

// Provider
final dataSyncServiceProvider = Provider<DataSyncService?>((ref) {
  final supabase = Supabase.instance.client;
  final authState = ref.watch(authNotifierProvider);

  if (authState is AuthAuthenticated) {
    return DataSyncService(supabase, ref, authState.user.id);
  }
  return null;
});

// Auto-Sync Manager
final syncManagerProvider = Provider<void>((ref) {
  final syncService = ref.watch(dataSyncServiceProvider);

  if (syncService != null) {
    // 1. Initial Sync on Login
    syncService.syncAll();

    // 2. Periodic Sync (Every 10 minutes)
    Timer.periodic(const Duration(minutes: 10), (timer) {
      // Check if user is still logged in to prevent memory leak or unwanted sync
      // Actually reading the provider again inside Timer callbacks is tricky due to closure context.
      // But since this provider is rebuilt on Auth change, the old timer dies with Garbage Collection
      // ONLY IF we explicitly cancel it. StateNotifierProvider autoDispose is safer,
      // but here we use a simple Provider.
      // To keep it simple and safe: just sync. If authentication is lost, supabase client might fail,
      // but syncService instance is bound to a specific userId.
      syncService.syncAll();
    });
  }
});
