import 'package:flutter/foundation.dart';

/// Cache entry with expiration time
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration duration;

  CachedData({
    required this.data,
    required this.timestamp,
    this.duration = const Duration(minutes: 10),
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > duration;
  }

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Cache service for storing API responses with expiration
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CachedData> _cache = {};

  /// Get cached data if available and not expired
  T? get<T>(String key) {
    try {
      final cached = _cache[key];
      if (cached != null && !cached.isExpired) {
        if (kDebugMode) {
          print('Cache HIT for $key (${cached.remainingTime.inSeconds}s remaining)');
        }
        return cached.data as T;
      }

      // Remove expired cache entry
      if (cached != null && cached.isExpired) {
        _cache.remove(key);
        if (kDebugMode) {
          print('Cache EXPIRED for $key');
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Cache ERROR for $key: $e');
      }
      return null;
    }
  }

  /// Set cached data with custom duration (default 10 minutes)
  void set<T>(String key, T data, {Duration? duration}) {
    try {
      _cache[key] = CachedData(
        data: data,
        timestamp: DateTime.now(),
        duration: duration ?? const Duration(minutes: 10),
      );
      if (kDebugMode) {
        print('Cache SET for $key (${(duration ?? const Duration(minutes: 10)).inMinutes}min)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache SET ERROR for $key: $e');
      }
    }
  }

  /// Clear specific cache entry
  void clear(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      print('Cache CLEAR for $key');
    }
  }

  /// Clear all cache entries
  void clearAll() {
    _cache.clear();
    if (kDebugMode) {
      print('Cache CLEAR ALL');
    }
  }

  /// Clear all expired cache entries
  void clearExpired() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (kDebugMode) {
      print('Cache CLEAR EXPIRED (${expiredKeys.length} entries)');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final activeEntries = _cache.entries.where((e) => !e.value.isExpired).length;
    final expiredEntries = _cache.entries.where((e) => e.value.isExpired).length;

    return {
      'total': _cache.length,
      'active': activeEntries,
      'expired': expiredEntries,
      'entries': _cache.entries.map((e) => {
            'key': e.key,
            'expired': e.value.isExpired,
            'age': now.difference(e.value.timestamp).inSeconds,
            'remaining': e.value.remainingTime.inSeconds,
          }).toList(),
    };
  }
}
