import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppConfig {
  final int adFrequency;
  final int adDuration;
  final Map<String, bool> proFeatures; // featureKey: isProLocked

  AppConfig({
    required this.adFrequency,
    required this.adDuration,
    required this.proFeatures,
  });

  factory AppConfig.defaults() {
    return AppConfig(
      adFrequency: 3,
      adDuration: 3,
      proFeatures: {
        'ai_analyst': true,
        'scenario_planner': true,
        'investment_comparison': true,
        'real_estate_calculator': false, // currently free
      },
    );
  }

  AppConfig copyWith({
    int? adFrequency,
    int? adDuration,
    Map<String, bool>? proFeatures,
  }) {
    return AppConfig(
      adFrequency: adFrequency ?? this.adFrequency,
      adDuration: adDuration ?? this.adDuration,
      proFeatures: proFeatures ?? this.proFeatures,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adFrequency': adFrequency,
      'adDuration': adDuration,
      'proFeatures': proFeatures,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      adFrequency: json['adFrequency'] as int? ?? 3,
      adDuration: json['adDuration'] as int? ?? 3,
      proFeatures: Map<String, bool>.from(json['proFeatures'] ?? {}),
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfig> {
  AppConfigNotifier() : super(AppConfig.defaults()) {
    _loadConfig();
  }

  static const _storageKey = 'app_remote_config_overrides';

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        state = AppConfig.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // Fallback to defaults
      }
    }
  }

  Future<void> updateConfig(AppConfig newConfig) async {
    state = newConfig;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(newConfig.toJson()));
  }

  Future<void> resetToDefaults() async {
    state = AppConfig.defaults();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  // Helper to toggle a feature lock status
  Future<void> toggleFeatureLock(String featureKey) async {
    final currentStatus = state.proFeatures[featureKey] ?? false;
    final newFeatures = Map<String, bool>.from(state.proFeatures);
    newFeatures[featureKey] = !currentStatus;
    
    await updateConfig(state.copyWith(proFeatures: newFeatures));
  }
}

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});
