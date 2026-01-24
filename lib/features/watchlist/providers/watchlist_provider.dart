import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watchlist_item.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';

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
      final watchlistJson = prefs.getString(_watchlistKey);

      if (watchlistJson != null && watchlistJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(watchlistJson);
        final items = decoded
            .map((item) => WatchlistItem.fromJson(item as Map<String, dynamic>))
            .toList();
        state = items;
      }

      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error loading watchlist: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      state = [];
      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e, stackTrace);
      }
      // Re-throw to allow UI to handle the error
      rethrow;
    }
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
      if (!state.contains(item)) {
        state = [...state, item];
        await _saveWatchlist();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error adding to watchlist: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Rollback state on error
      state = state.where((i) => i != item).toList();
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
