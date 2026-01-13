import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/features/search/data/models/asset.dart';
import 'package:invest_guide/services/api/supabase_service.dart';

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider with error handling
final searchResultsProvider = FutureProvider.autoDispose<List<Asset>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];
  }

  try {
    return await SupabaseService.searchAssets(query);
  } catch (e) {
    // Log error and fallback to empty list for better UX
    debugPrint('Error searching assets for query "$query": $e');
    return [];
  }
});

// Popular searches provider with error handling
final popularSearchesProvider = FutureProvider<List<Asset>>((ref) async {
  try {
    return await SupabaseService.getPopularSearches(limit: 10);
  } catch (e) {
    debugPrint('Error fetching popular searches: $e');
    // Fallback to empty list if fails
    return [];
  }
});

// Assets by category provider with error handling
final assetsByCategoryProvider = FutureProvider.family<List<Asset>, int>((ref, categoryId) async {
  try {
    return await SupabaseService.getAssets(categoryId: categoryId, limit: 50);
  } catch (e) {
    debugPrint('Error fetching assets for category $categoryId: $e');
    // Fallback to empty list if fails
    return [];
  }
});

// Recent searches provider (requires user to be logged in) with error handling
final recentSearchesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = SupabaseService.client.auth.currentUser;

  if (user == null) {
    return [];
  }

  try {
    return await SupabaseService.getSearchHistory(user.id, limit: 10);
  } catch (e) {
    debugPrint('Error fetching search history for user ${user.id}: $e');
    return [];
  }
});
