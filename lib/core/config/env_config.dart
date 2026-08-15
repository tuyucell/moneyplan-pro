class EnvConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://fadzhvakdivhisnmfyqn.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_l9-UK9xkD4sV5PBYGuZnaA_-FD-k_hB';

  // External API Keys (Opsiyonel)
  static const String coinGeckoApiKey =
      ''; // Optional - ücretsiz kullanılabilir
  static const String alphaVantageApiKey = ''; // Daha sonra eklenebilir
  static const String googleIosClientId =
      '342870422238-2d0fmm4b6922n5rdskdk1lj9s2h4gemn.apps.googleusercontent.com';
  static const String oneSignalAppId = '4c57d6a6-9e5f-4738-94c0-e864cbb95845';

  // Backend Configuration
  static String get backendBaseUrl {
    // -----------------------------------------------------------------
    // PRODUCTION (Remote - Hugging Face)
    // -----------------------------------------------------------------
    return 'https://tuyucel-moneyplanpro.hf.space/api/v1';

    // DEVELOPMENT (Local)
    // if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    // if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    // return 'http://192.168.68.102:8000/api/v1';
  }

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey != 'YOUR_ANON_KEY_HERE' &&
        (supabaseAnonKey.startsWith('eyJ') ||
            supabaseAnonKey.startsWith('sb_publishable_')) &&
        googleIosClientId.isNotEmpty &&
        oneSignalAppId.isNotEmpty;
  }

  static void validate() {
    if (!isConfigured) {
      throw Exception(
        '❌ Supabase yapılandırması eksik!\n\n'
        'Lütfen lib/core/config/env_config.dart dosyasını güncelleyin:\n'
        '1. Supabase Dashboard > Settings > API sayfasına gidin\n'
        '2. "publishable" veya eski "anon/public" key\'i kopyalayın\n'
        '3. supabaseAnonKey değişkenine yapıştırın\n\n'
        '⚠️ DİKKAT: service_role key\'i ASLA kullanmayın!',
      );
    }
  }
}
