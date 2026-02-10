/// API Configuration for all external data sources
class ApiConfig {
  // Cache duration for all API calls (1 hour for scraped data)
  static const Duration cacheDuration = Duration(hours: 1);

  // ============================================================================
  // PENSION FUNDS (BES - Bireysel Emeklilik Sistemi)
  // ============================================================================

  /// EGM (Emeklilik Gözetim Merkezi) - Official pension fund regulator
  /// Note: No public API available. Requires institutional access.
  /// Alternative: Consider web scraping or requesting institutional API access
  static const String egmBaseUrl = 'https://www.egm.org.tr';
  static const String egmApiKey = ''; // To be filled if API access is granted

  // ============================================================================
  // INSURANCE PRODUCTS
  // ============================================================================

  /// TSB (Türkiye Sigorta Birliği) - Turkish Insurance Association
  /// Note: No public API available. Statistical data published on website.
  /// Alternative: Consider web scraping or requesting API access
  static const String tsbBaseUrl = 'https://www.tsb.org.tr';
  static const String tsbApiKey = ''; // To be filled if API access is granted

  // ============================================================================
  // STOCK MARKET DATA (BIST - Borsa Istanbul)
  // ============================================================================

  /// BIST VERDA API - Official API (requires institutional access)
  /// Public data is 15 minutes delayed
  static const String bistVerdaUrl = 'https://verdauat.borsaistanbul.com';
  static const String bistApiKey = ''; // To be filled if institutional access is granted

  /// Alternative: RapidAPI - BIST100 Stock Data (15 minutes delayed)
  /// Free tier available with rate limits
  static const String rapidApiBistUrl = 'https://bist100-stock-data-15-minutes-late-live.p.rapidapi.com';
  static const String rapidApiKey = ''; // To be filled - Get from: https://rapidapi.com

  /// Alternative: Twelve Data - Multi-market data provider
  /// Supports BIST with free tier
  static const String twelveDataUrl = 'https://api.twelvedata.com';
  static const String twelveDataApiKey = ''; // To be filled - Get from: https://twelvedata.com

  // ============================================================================
  // CRYPTOCURRENCY DATA (Binance)
  // ============================================================================

  /// Binance Public API - For cryptocurrency prices and market data
  /// User has already added their Binance API key (read-only, no secret needed)
  static const String binanceBaseUrl = 'https://api.binance.com';
  static const String binanceApiKey = ''; // User already configured this

  // ============================================================================
  // GOLD & PRECIOUS METALS
  // ============================================================================

  /// TCMB (Türkiye Cumhuriyet Merkez Bankası) - Central Bank of Turkey
  /// Provides exchange rates and precious metal prices
  /// Public API available
  static const String tcmbBaseUrl = 'https://evds2.tcmb.gov.tr/service/evds';
  static const String tcmbApiKey = ''; // To be filled - Get from: https://evds2.tcmb.gov.tr

  // ============================================================================
  // GENERAL SETTINGS
  // ============================================================================

  /// HTTP timeout for all API calls
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum retry attempts for failed API calls
  static const int maxRetryAttempts = 3;

  /// Use mock data as fallback when API fails
  static const bool useMockFallback = true;

  /// Enable debug logging for API calls
  static const bool enableDebugLogging = true;

  // ============================================================================
  // API HEADERS
  // ============================================================================

  static Map<String, String> getDefaultHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'InvestGuide/1.0',
    };
  }

  static Map<String, String> getRapidApiHeaders() {
    return {
      ...getDefaultHeaders(),
      if (rapidApiKey.isNotEmpty) 'X-RapidAPI-Key': rapidApiKey,
      if (rapidApiKey.isNotEmpty) 'X-RapidAPI-Host': 'bist100-stock-data-15-minutes-late-live.p.rapidapi.com',
    };
  }

  static Map<String, String> getTwelveDataHeaders() {
    return {
      ...getDefaultHeaders(),
      if (twelveDataApiKey.isNotEmpty) 'Authorization': 'apikey $twelveDataApiKey',
    };
  }

  static Map<String, String> getTcmbHeaders() {
    return {
      ...getDefaultHeaders(),
      if (tcmbApiKey.isNotEmpty) 'key': tcmbApiKey,
    };
  }

  static Map<String, String> getBinanceHeaders() {
    return {
      ...getDefaultHeaders(),
      if (binanceApiKey.isNotEmpty) 'X-MBX-APIKEY': binanceApiKey,
    };
  }
}

/// API Response Status
enum ApiStatus {
  success,
  error,
  cached,
  fallback,
}

/// Generic API Response wrapper
class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? error;
  final DateTime timestamp;
  final bool fromCache;

  ApiResponse({
    required this.status,
    this.data,
    this.error,
    DateTime? timestamp,
    this.fromCache = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == ApiStatus.success && data != null;
  bool get isError => status == ApiStatus.error;
  bool get isCached => fromCache;
}
