import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:invest_guide/core/config/api_config.dart';
import 'package:invest_guide/core/services/cache_service.dart';
import 'package:invest_guide/features/search/data/models/pension_fund.dart';

class PensionFundService {
  static final CacheService _cache = CacheService();

  /// Get all pension funds with optional type filter
  /// Uses cache with 10-minute expiration
  /// Falls back to mock data if API fails
  static Future<ApiResponse<List<PensionFund>>> getFunds({
    String? type,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate cache key
      final cacheKey = 'pension_funds_${type ?? 'all'}';

      // Check cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = _cache.get<List<PensionFund>>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('PensionFundService: Returning cached data');
          }
          return ApiResponse(
            status: ApiStatus.success,
            data: cached,
            fromCache: true,
          );
        }
      }

      // Try to fetch from API
      if (ApiConfig.egmApiKey.isNotEmpty) {
        try {
          final funds = await _fetchFromApi(type);
          _cache.set(cacheKey, funds, duration: ApiConfig.cacheDuration);

          return ApiResponse(
            status: ApiStatus.success,
            data: funds,
            fromCache: false,
          );
        } catch (e) {
          if (kDebugMode) {
            print('PensionFundService: API fetch failed: $e');
          }
          // Continue to fallback
        }
      }

      // Fallback to mock data
      if (ApiConfig.useMockFallback) {
        if (kDebugMode) {
          print('PensionFundService: Using mock data fallback');
        }

        await Future.delayed(const Duration(milliseconds: 500));
        final funds = _getMockFunds(type);

        // Cache mock data too
        _cache.set(cacheKey, funds, duration: ApiConfig.cacheDuration);

        return ApiResponse(
          status: ApiStatus.fallback,
          data: funds,
          fromCache: false,
        );
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: 'No API key configured and mock fallback disabled',
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('PensionFundService: Error in getFunds: $e');
        print('Stack trace: $stackTrace');
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Get single pension fund by ID
  static Future<ApiResponse<PensionFund>> getFundById(String id) async {
    try {
      final response = await getFunds();

      if (response.isSuccess && response.data != null) {
        final fund = response.data!.firstWhere(
          (f) => f.id == id,
          orElse: () => throw Exception('Fund not found'),
        );

        return ApiResponse(
          status: response.status,
          data: fund,
          fromCache: response.fromCache,
        );
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: response.error ?? 'Failed to fetch fund',
      );
    } catch (e) {
      if (kDebugMode) {
        print('PensionFundService: Error in getFundById: $e');
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Clear cache for pension funds
  static void clearCache() {
    _cache.clear('pension_funds_all');
    _cache.clear('pension_funds_interest');
    _cache.clear('pension_funds_participation');
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Fetch pension funds from real API
  /// Currently a placeholder - will be implemented when API is available
  static Future<List<PensionFund>> _fetchFromApi(String? type) async {
    final uri = Uri.parse('${ApiConfig.egmBaseUrl}/api/funds');

    final response = await http.get(
      uri.replace(queryParameters: type != null ? {'type': type} : null),
      headers: {
        ...ApiConfig.getDefaultHeaders(),
        if (ApiConfig.egmApiKey.isNotEmpty) 'Authorization': 'Bearer ${ApiConfig.egmApiKey}',
      },
    ).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => _parseFund(item)).toList();
    } else {
      throw Exception('API request failed with status ${response.statusCode}');
    }
  }

  /// Parse API response to PensionFund object
  static PensionFund _parseFund(Map<String, dynamic> json) {
    return PensionFund(
      id: json['id'] as String,
      name: json['name'] as String,
      institution: json['institution'] as String,
      returns1y: (json['returns_1y'] as num).toDouble(),
      returns3y: (json['returns_3y'] as num).toDouble(),
      returns5y: (json['returns_5y'] as num).toDouble(),
      totalAssets: (json['total_assets'] as num).toDouble(),
      riskLevel: json['risk_level'] as int,
      type: json['type'] as String,
    );
  }

  /// Get mock pension funds data
  static List<PensionFund> _getMockFunds(String? type) {
    final allFunds = [
      ..._getInterestBasedFunds(),
      ..._getParticipationFunds(),
    ];

    if (type != null) {
      return allFunds.where((f) => f.type == type).toList();
    }

    return allFunds;
  }

  static List<PensionFund> _getInterestBasedFunds() {
    return [
      PensionFund(
        id: 'akp_gelir',
        name: 'AKP Gelir Amaçlı Kamu Dış Borçlanma Araçları',
        institution: 'AvivaSA Emeklilik',
        returns1y: 42.5,
        returns3y: 125.3,
        returns5y: 287.4,
        totalAssets: 1250000000,
        riskLevel: 2,
        type: 'interest',
      ),
      PensionFund(
        id: 'gye_gelir',
        name: 'GYE Gelir Amaçlı Kamu Dış Borçlanma Araçları',
        institution: 'Garanti Emeklilik',
        returns1y: 41.8,
        returns3y: 122.7,
        returns5y: 278.3,
        totalAssets: 980000000,
        riskLevel: 2,
        type: 'interest',
      ),
      PensionFund(
        id: 'aye_buyume',
        name: 'AYE Büyüme Amaçlı Hisse Senedi',
        institution: 'Allianz Yaşam ve Emeklilik',
        returns1y: 38.2,
        returns3y: 115.6,
        returns5y: 245.8,
        totalAssets: 750000000,
        riskLevel: 5,
        type: 'interest',
      ),
      PensionFund(
        id: 'hye_standart',
        name: 'HYE Standart Emeklilik Yatırım Fonu',
        institution: 'Halk Hayat ve Emeklilik',
        returns1y: 36.7,
        returns3y: 108.3,
        returns5y: 225.1,
        totalAssets: 650000000,
        riskLevel: 3,
        type: 'interest',
      ),
      PensionFund(
        id: 'vye_dengeli',
        name: 'VYE Dengeli Emeklilik Yatırım Fonu',
        institution: 'Vakıf Emeklilik',
        returns1y: 35.4,
        returns3y: 102.8,
        returns5y: 218.5,
        totalAssets: 890000000,
        riskLevel: 4,
        type: 'interest',
      ),
    ];
  }

  static List<PensionFund> _getParticipationFunds() {
    return [
      PensionFund(
        id: 'akp_katilim',
        name: 'AKP Katılım Gelir Amaçlı Kira Sertifikası',
        institution: 'AvivaSA Emeklilik',
        returns1y: 39.8,
        returns3y: 118.4,
        returns5y: 265.7,
        totalAssets: 580000000,
        riskLevel: 2,
        type: 'participation',
      ),
      PensionFund(
        id: 'gye_katilim',
        name: 'GYE Katılım Katkı Emeklilik Yatırım Fonu',
        institution: 'Garanti Emeklilik',
        returns1y: 38.5,
        returns3y: 115.2,
        returns5y: 258.3,
        totalAssets: 720000000,
        riskLevel: 2,
        type: 'participation',
      ),
      PensionFund(
        id: 'aye_katilim_standart',
        name: 'AYE Katılım Standart Emeklilik Yatırım Fonu',
        institution: 'Allianz Yaşam ve Emeklilik',
        returns1y: 36.3,
        returns3y: 107.8,
        returns5y: 238.4,
        totalAssets: 490000000,
        riskLevel: 3,
        type: 'participation',
      ),
      PensionFund(
        id: 'hye_katilim',
        name: 'HYE Katılım Standart Emeklilik Yatırım Fonu',
        institution: 'Halk Hayat ve Emeklilik',
        returns1y: 35.1,
        returns3y: 103.5,
        returns5y: 228.7,
        totalAssets: 420000000,
        riskLevel: 3,
        type: 'participation',
      ),
      PensionFund(
        id: 'vye_katilim',
        name: 'VYE Katılım Gelir Amaçlı Kira Sertifikası',
        institution: 'Vakıf Emeklilik',
        returns1y: 34.8,
        returns3y: 101.2,
        returns5y: 221.6,
        totalAssets: 510000000,
        riskLevel: 2,
        type: 'participation',
      ),
    ];
  }
}
