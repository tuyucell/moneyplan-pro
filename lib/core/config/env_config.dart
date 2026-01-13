class EnvConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://gbncnwinlmniohafhnqf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdibmNud2lubG1uaW9oYWZobnFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxNzAzNjksImV4cCI6MjA4MTc0NjM2OX0.yNlFRikUab3o4enRJEo98L7tF9lyurGdUwXMUeIA7o4';

  // External API Keys (Opsiyonel)
  static const String coinGeckoApiKey = ''; // Optional - ücretsiz kullanılabilir
  static const String alphaVantageApiKey = ''; // Daha sonra eklenebilir

  // Validate configuration
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey != 'YOUR_ANON_KEY_HERE' &&
        supabaseAnonKey.startsWith('eyJ'); // JWT token kontrolü
  }

  static void validate() {
    if (!isConfigured) {
      throw Exception(
        '❌ Supabase yapılandırması eksik!\n\n'
        'Lütfen lib/core/config/env_config.dart dosyasını güncelleyin:\n'
        '1. Supabase Dashboard > Settings > API sayfasına gidin\n'
        '2. "anon/public" key\'i kopyalayın (eyJhbGciOi... ile başlar)\n'
        '3. supabaseAnonKey değişkenine yapıştırın\n\n'
        '⚠️ DİKKAT: service_role key\'i ASLA kullanmayın!',
      );
    }
  }
}
