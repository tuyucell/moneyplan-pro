import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:invest_guide/core/config/env_config.dart';

class FeatureFlag {
  final String id;
  final String name;
  final String description;
  final bool isPro;
  final bool isEnabled;
  final int? dailyFreeLimit;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureFlag({
    required this.id,
    required this.name,
    required this.description,
    required this.isPro,
    required this.isEnabled,
    this.dailyFreeLimit,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isPro: json['is_pro'] as bool,
      isEnabled: json['is_enabled'] as bool,
      dailyFreeLimit: json['daily_free_limit'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_pro': isPro,
      'is_enabled': isEnabled,
      'daily_free_limit': dailyFreeLimit,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FeatureFlagsResponse {
  final Map<String, FeatureFlag> features;
  final int version;
  final DateTime cachedUntil;

  FeatureFlagsResponse({
    required this.features,
    required this.version,
    required this.cachedUntil,
  });

  factory FeatureFlagsResponse.fromJson(Map<String, dynamic> json) {
    final featuresMap = <String, FeatureFlag>{};
    final features = json['features'] as Map<String, dynamic>;

    features.forEach((key, value) {
      featuresMap[key] = FeatureFlag.fromJson(value as Map<String, dynamic>);
    });

    return FeatureFlagsResponse(
      features: featuresMap,
      version: json['version'] as int,
      cachedUntil: DateTime.parse(json['cached_until'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final featuresJson = <String, dynamic>{};
    features.forEach((key, value) {
      featuresJson[key] = value.toJson();
    });

    return {
      'features': featuresJson,
      'version': version,
      'cached_until': cachedUntil.toIso8601String(),
    };
  }
}

class RemoteConfigService {
  static const String _cacheKey = 'feature_flags_cache';
  static const String _versionKey = 'feature_flags_version';
  static String get _baseUrl => EnvConfig.backendBaseUrl;

  final SharedPreferences _prefs;
  FeatureFlagsResponse? _cachedFlags;

  RemoteConfigService(this._prefs);

  /// Fetch feature flags from backend
  Future<FeatureFlagsResponse> fetchFlags({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _cachedFlags != null) {
      if (DateTime.now().isBefore(_cachedFlags!.cachedUntil)) {
        return _cachedFlags!;
      }
    }

    // Check persistent cache
    if (!forceRefresh) {
      final cached = await _loadFromCache();
      if (cached != null && DateTime.now().isBefore(cached.cachedUntil)) {
        _cachedFlags = cached;
        return cached;
      }
    }

    // Fetch from network
    try {
      final response = await http.get(Uri.parse('$_baseUrl/features'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final flags = FeatureFlagsResponse.fromJson(data);

        // Save to cache
        await _saveToCache(flags);
        _cachedFlags = flags;

        return flags;
      } else {
        throw Exception('Failed to load feature flags: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to cached version if network fails
      final cached = await _loadFromCache();
      if (cached != null) {
        _cachedFlags = cached;
        return cached;
      }
      rethrow;
    }
  }

  /// Get a specific feature flag
  Future<FeatureFlag?> getFlag(String flagId) async {
    final flags = await fetchFlags();
    return flags.features[flagId];
  }

  /// Check if a feature is available for the user
  Future<bool> isFeatureAvailable(String flagId, bool isProUser) async {
    try {
      final flag = await getFlag(flagId);

      if (flag == null || !flag.isEnabled) {
        return false;
      }

      // If feature is not PRO, it's available to everyone
      if (!flag.isPro) {
        return true;
      }

      // If user is PRO, they have access
      if (isProUser) {
        return true;
      }

      // If feature has daily free limit > 0, it's available (usage tracking is separate)
      if (flag.dailyFreeLimit != null && flag.dailyFreeLimit! > 0) {
        return true;
      }

      return false;
    } catch (e) {
      // On error, default to allowing access (fail open)
      return true;
    }
  }

  /// Save flags to persistent cache
  Future<void> _saveToCache(FeatureFlagsResponse flags) async {
    await _prefs.setString(_cacheKey, json.encode(flags.toJson()));
    await _prefs.setInt(_versionKey, flags.version);
  }

  /// Load flags from persistent cache
  Future<FeatureFlagsResponse?> _loadFromCache() async {
    final cached = _prefs.getString(_cacheKey);
    if (cached == null) return null;

    try {
      final data = json.decode(cached) as Map<String, dynamic>;
      return FeatureFlagsResponse.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache (for testing)
  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_versionKey);
    _cachedFlags = null;
  }
}

// Provider
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  throw UnimplementedError('RemoteConfigService must be initialized');
});

final featureFlagsProvider = FutureProvider<FeatureFlagsResponse>((ref) async {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.fetchFlags();
});

final featureFlagProvider =
    FutureProvider.family<FeatureFlag?, String>((ref, flagId) async {
  final service = ref.watch(remoteConfigServiceProvider);
  return service.getFlag(flagId);
});
