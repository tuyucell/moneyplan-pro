class AppConstants {
  // App Info
  static const String appName = 'MoneyPlan Pro';
  static const String appVersion = '1.0.0';

  // API Base URLs
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // External APIs
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String alphaVantageApiKey = 'YOUR_API_KEY';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String currencyKey = 'preferred_currency';

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchDebounceMs = 300;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 1);
}
