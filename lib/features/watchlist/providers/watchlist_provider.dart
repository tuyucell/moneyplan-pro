import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_item.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/services/api/supabase_service.dart';

class WatchlistNotifier extends StateNotifier<List<WatchlistItem>> {
  final String? userId;
  String get _watchlistKey =>
      userId != null ? 'watchlist_items_$userId' : 'watchlist_items_guest';

  // Cache SharedPreferences instance to avoid repeated getInstance() calls
  SharedPreferences? _prefsCache;
  bool _isInitialized = false;
  final _initCompleter = Completer<void>();

  WatchlistNotifier(this.userId) : super([]) {
    _loadWatchlist();
  }

  final _client = SupabaseService.client;

  /// Get cached SharedPreferences instance or create new one
  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  /// Load watchlist from disk (cached after first load)
  Future<void> _loadWatchlist() async {
    if (_isInitialized) {
      return;
    }

    try {
      final prefs = await _prefs;

      // 1. GUEST TO USER MIGRATION
      if (userId != null) {
        const guestKey = 'watchlist_items_guest';
        final guestWatchlistJson = prefs.getString(guestKey);
        if (guestWatchlistJson != null && guestWatchlistJson.isNotEmpty) {
          final List<dynamic> guestItems = jsonDecode(guestWatchlistJson);
          if (guestItems.isNotEmpty) {
            final userKey = 'watchlist_items_$userId';
            debugPrint(
                'Migrating ${guestItems.length} guest items to user: $userId');
            final userWatchlistJson = prefs.getString(userKey) ?? '[]';
            final List<dynamic> userItems = jsonDecode(userWatchlistJson);

            final existingSymbols =
                userItems.map((e) => e['symbol'] as String).toSet();
            var migratedCount = 0;
            for (var item in guestItems) {
              if (!existingSymbols.contains(item['symbol'])) {
                userItems.add(item);
                migratedCount++;
              }
            }

            if (migratedCount > 0) {
              await prefs.setString(userKey, jsonEncode(userItems));
              debugPrint(
                  'Sync: Migrated $migratedCount items from guest to user $userId');
            }
            // IMPORTANT: Clear guest items after migration
            await prefs.remove(guestKey);
          }
        }
      }

      // Load items from current context's key
      final watchlistJson = prefs.getString(_watchlistKey);

      if (watchlistJson != null && watchlistJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(watchlistJson);
        final items = decoded.map((item) {
          final w = WatchlistItem.fromJson(item as Map<String, dynamic>);
          // Self-heal: ensure assetId exists
          if (w.assetId == null || w.assetId!.isEmpty) {
            return WatchlistItem(
              symbol: w.symbol,
              name: w.name,
              assetId: w.symbol, // Fallback to symbol
              category: w.category,
            );
          }
          return w;
        }).toList();
        state = items; // Set local data immediately
      }

      // 2. REMOTE SYNC (Non-blocking)
      if (userId != null) {
        debugPrint('Sync: Starting remote pull for user $userId');
        try {
          final List<dynamic> response = await _client
              .from('user_watchlists')
              .select('*')
              .eq('user_id', userId!);

          if (response.isNotEmpty) {
            final remoteItems = response.map((json) {
              return WatchlistItem(
                symbol: json['symbol'] as String,
                name: json['asset_name'] as String? ?? '',
                assetId:
                    json['asset_id'] as String? ?? json['symbol'] as String,
                category: json['asset_type'] as String?,
              );
            }).toList();

            // Merge local and remote
            final merged = <String, WatchlistItem>{};
            for (var item in state) {
              merged[item.symbol] = item;
            }
            for (var item in remoteItems) {
              merged[item.symbol] = item;
            }

            state = merged.values.toList();
            await _saveWatchlist();
            debugPrint(
                'Sync: Remote pull completed. Total items: ${state.length}');
          }
        } catch (syncError) {
          debugPrint('Sync: Remote pull failed (preserving local): $syncError');
        }

        // Also push local items to remote that might be missing
        _pushLocalToRemote();
      }

      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      debugPrint('Sync: Critical initialization error: $e');
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  void _pushLocalToRemote() {
    if (userId == null || state.isEmpty) return;

    debugPrint('Sync: Pushing ${state.length} items to remote...');
    final List<Map<String, dynamic>> batch = state
        .map((item) => {
              'user_id': userId,
              'symbol': item.symbol,
              'asset_name': item.name,
              'asset_type': item.category,
              'asset_id': item.assetId,
            })
        .toList();

    _client
        .from('user_watchlists')
        .upsert(batch, onConflict: 'user_id, symbol')
        .then((_) {
      debugPrint('Sync: Batch push completed for ${batch.length} items');
    }).catchError((e) {
      debugPrint('Sync: Batch push failed: $e');
    });
  }

  /// Save watchlist to disk with error handling
  Future<void> _saveWatchlist() async {
    try {
      // Wait for initialization to complete
      await _initCompleter.future;

      final prefs = await _prefs;
      final jsonList = state.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final success = await prefs.setString(_watchlistKey, jsonString);

      if (!success && kDebugMode) {
        debugPrint('Warning: Failed to save watchlist to SharedPreferences');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error saving watchlist: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Re-throw to allow UI to handle the error
      rethrow;
    }
  }

  /// Add item to watchlist with error handling
  Future<void> addToWatchlist(WatchlistItem item) async {
    try {
      if (!state.any((e) => e.symbol == item.symbol)) {
        state = [...state, item];
        await _saveWatchlist();

        // Sync to Supabase - NON-BLOCKING
        if (userId != null) {
          await _client.from('user_watchlists').upsert({
            'user_id': userId,
            'symbol': item.symbol,
            'asset_name': item.name,
            'asset_type': item.category,
            'asset_id': item.assetId,
          }, onConflict: 'user_id, symbol').then((_) {
            debugPrint('Sync: Successfully pushed ${item.symbol}');
          }).catchError((e) {
            debugPrint('Sync: Push failed for ${item.symbol}: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('Error adding to watchlist locally: $e');
      rethrow;
    }
  }

  /// Remove item from watchlist with error handling
  Future<void> removeFromWatchlist(String symbol) async {
    // Store old state for rollback
    final oldState = state;

    try {
      state = state.where((item) => item.symbol != symbol).toList();
      await _saveWatchlist();

      // Sync to Supabase
      if (userId != null) {
        await _client
            .from('user_watchlists')
            .delete()
            .eq('user_id', userId!)
            .eq('symbol', symbol);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error removing from watchlist: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Rollback state on error
      state = oldState;
      rethrow;
    }
  }

  /// Check if symbol is in watchlist (cached, no disk I/O)
  bool isInWatchlist(String symbol) {
    return state.any((item) => item.symbol == symbol);
  }

  /// Get watchlist items (cached, no disk I/O)
  List<WatchlistItem> getWatchlist() {
    return state;
  }

  /// Update item order in watchlist
  Future<void> reorder(int oldIndex, int newIndex) async {
    final items = List<WatchlistItem>.from(state);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
    await _saveWatchlist();
  }

  /// Force reload from disk (useful for debugging or sync)
  Future<void> reload() async {
    _isInitialized = false;
    await _loadWatchlist();
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<WatchlistItem>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  String? userId;
  if (authState is AuthAuthenticated) {
    userId = authState.user.id;
  }
  return WatchlistNotifier(userId);
});
