import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppConfig {
  // Reklam Ayarları (Her X işlemde bir göster mantığı)
  final int nativeAdFrequency; // İşlem listelerinde her X kayıtta bir
  final int interstitialAdFrequency; // Her X sayfa geçişinde bir
  final int rewardedAdEnabled; // 0: Kapalı, 1: Açık

  // Reklam Süreleri (saniye)
  final int interstitialDuration; // Interstitial reklamların max süresi

  final Map<String, bool> proFeatures; // featureKey: isProLocked

  AppConfig({
    required this.nativeAdFrequency,
    required this.interstitialAdFrequency,
    required this.rewardedAdEnabled,
    required this.interstitialDuration,
    required this.proFeatures,
  });

  factory AppConfig.defaults() {
    return AppConfig(
      // BAŞLANGIÇ: Kullanıcıyı kaçırmamak için ÇOK DÜŞÜK frekans
      nativeAdFrequency: 15, // Her 15 işlemde bir (çok seyrek)
      interstitialAdFrequency: 10, // Her 10 sayfa geçişinde bir
      rewardedAdEnabled: 1, // Açık (kullanıcı isteğine bağlı)
      interstitialDuration: 3, // Max 3 saniye
      proFeatures: {
        'ai_analyst': true,
        'scenario_planner': true,
        'investment_comparison': true,
        'email_automation': true,
        'real_estate_calculator': false, // Şimdilik ücretsiz
      },
    );
  }

  AppConfig copyWith({
    int? nativeAdFrequency,
    int? interstitialAdFrequency,
    int? rewardedAdEnabled,
    int? interstitialDuration,
    Map<String, bool>? proFeatures,
  }) {
    return AppConfig(
      nativeAdFrequency: nativeAdFrequency ?? this.nativeAdFrequency,
      interstitialAdFrequency:
          interstitialAdFrequency ?? this.interstitialAdFrequency,
      rewardedAdEnabled: rewardedAdEnabled ?? this.rewardedAdEnabled,
      interstitialDuration: interstitialDuration ?? this.interstitialDuration,
      proFeatures: proFeatures ?? this.proFeatures,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nativeAdFrequency': nativeAdFrequency,
      'interstitialAdFrequency': interstitialAdFrequency,
      'rewardedAdEnabled': rewardedAdEnabled,
      'interstitialDuration': interstitialDuration,
      'proFeatures': proFeatures,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      nativeAdFrequency: json['nativeAdFrequency'] as int? ?? 15,
      interstitialAdFrequency: json['interstitialAdFrequency'] as int? ?? 10,
      rewardedAdEnabled: json['rewardedAdEnabled'] as int? ?? 1,
      interstitialDuration: json['interstitialDuration'] as int? ?? 3,
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

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier();
});
