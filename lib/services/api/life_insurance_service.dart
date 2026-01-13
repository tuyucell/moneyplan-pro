import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:invest_guide/core/config/api_config.dart';
import 'package:invest_guide/core/services/cache_service.dart';
// Use relative import to avoid potential package resolution issues or type mismatch
import '../../features/search/data/models/insurance_product.dart';

class LifeInsuranceService {
  static final CacheService _cache = CacheService();

  /// Get all insurance products with optional type filter
  /// Uses cache with 10-minute expiration
  /// Falls back to mock data if API fails
  static Future<ApiResponse<List<InsuranceProduct>>> getProducts({
    String? type,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate cache key
      final cacheKey = 'insurance_products_${type ?? 'all'}';

      // Check cache first (unless force refresh)
      if (!forceRefresh) {
        final cached = _cache.get<List<InsuranceProduct>>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('LifeInsuranceService: Returning cached data');
          }
          return ApiResponse(
            status: ApiStatus.success,
            data: cached,
            fromCache: true,
          );
        }
      }

      // Try to fetch from API
      if (ApiConfig.tsbApiKey.isNotEmpty) {
        try {
          final products = await _fetchFromApi(type);
          _cache.set(cacheKey, products, duration: ApiConfig.cacheDuration);

          return ApiResponse(
            status: ApiStatus.success,
            data: products,
            fromCache: false,
          );
        } catch (e) {
          if (kDebugMode) {
            print('LifeInsuranceService: API fetch failed: $e');
          }
          // Continue to fallback
        }
      }

      // Fallback to mock data
      if (ApiConfig.useMockFallback) {
        if (kDebugMode) {
          print('LifeInsuranceService: Using mock data fallback');
        }

        await Future.delayed(const Duration(milliseconds: 500));
        final products = _getMockProducts(type);

        // Cache mock data too
        _cache.set(cacheKey, products, duration: ApiConfig.cacheDuration);

        return ApiResponse(
          status: ApiStatus.fallback,
          data: products,
          fromCache: false,
        );
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: 'No API key configured and mock fallback disabled',
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('LifeInsuranceService: Error in getProducts: $e');
        print('Stack trace: $stackTrace');
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Get single insurance product by ID
  static Future<ApiResponse<InsuranceProduct>> getProductById(String id) async {
    try {
      final response = await getProducts();

      if (response.isSuccess && response.data != null) {
        final product = response.data!.firstWhere(
          (InsuranceProduct p) => p.name.hashCode.toString() == id,
          orElse: () => throw Exception('Product not found'),
        );

        return ApiResponse(
          status: response.status,
          data: product,
          fromCache: response.fromCache,
        );
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: response.error ?? 'Failed to fetch product',
      );
    } catch (e) {
      if (kDebugMode) {
        print('LifeInsuranceService: Error in getProductById: $e');
      }

      return ApiResponse(
        status: ApiStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Calculate monthly premium for term insurance
  static double calculatePremium({
    required int age,
    required double coverage,
    required int term,
    required bool isSmoker,
  }) {
    var basePremium = (coverage / 1000) * 0.8;

    var ageFactor = 1.0;
    if (age < 30) {
      ageFactor = 0.7;
    } else if (age < 40) {
      ageFactor = 1.0;
    } else if (age < 50) {
      ageFactor = 1.5;
    } else if (age < 60) {
      ageFactor = 2.2;
    } else {
      ageFactor = 3.5;
    }

    var termFactor = 1.0 + (term / 100);
    var smokerFactor = isSmoker ? 1.8 : 1.0;

    return basePremium * ageFactor * termFactor * smokerFactor;
  }

  /// Clear cache for insurance products
  static void clearCache() {
    _cache.clear('insurance_products_all');
    _cache.clear('insurance_products_savings');
    _cache.clear('insurance_products_term');
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Fetch insurance products from real API
  /// Currently a placeholder - will be implemented when API is available
  static Future<List<InsuranceProduct>> _fetchFromApi(String? type) async {
    final uri = Uri.parse('${ApiConfig.tsbBaseUrl}/api/products');

    final response = await http.get(
      uri.replace(queryParameters: type != null ? {'type': type} : null),
      headers: {
        ...ApiConfig.getDefaultHeaders(),
        if (ApiConfig.tsbApiKey.isNotEmpty) 'Authorization': 'Bearer ${ApiConfig.tsbApiKey}',
      },
    ).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => _parseProduct(item)).toList();
    } else {
      throw Exception('API request failed with status ${response.statusCode}');
    }
  }

  /// Parse API response to InsuranceProduct object
  static InsuranceProduct _parseProduct(Map<String, dynamic> json) {
    return InsuranceProduct(
      name: json['name'] as String,
      company: json['company'] as String,
      type: json['type'] as String,
      minAge: json['min_age'] as int,
      maxAge: json['max_age'] as int,
      minTerm: json['min_term'] as int,
      maxTerm: json['max_term'] as int,
      expectedReturn: json['expected_return'] != null
          ? (json['expected_return'] as num).toDouble()
          : null,
      features: (json['features'] as List).cast<String>(),
    );
  }

  /// Get mock insurance products data
  static List<InsuranceProduct> _getMockProducts(String? type) {
    final allProducts = [
      ..._getSavingsProducts(),
      ..._getTermProducts(),
    ];

    if (type != null) {
      return allProducts.where((p) => p.type == type).toList();
    }

    return allProducts;
  }

  static List<InsuranceProduct> _getSavingsProducts() {
    return [
      InsuranceProduct(
        name: 'Anadolu Hayat Gold Birikim',
        company: 'Anadolu Hayat',
        type: 'savings',
        minAge: 18,
        maxAge: 65,
        minTerm: 10,
        maxTerm: 30,
        expectedReturn: 8.5,
        features: [
          'Yıllık %8-9 beklenen getiri',
          'Ölüm ve maluliyet güvencesi',
          'Vergi avantajı',
          'Erken çıkış imkanı',
        ],
      ),
      InsuranceProduct(
        name: 'Allianz Gelecek Planı',
        company: 'Allianz Yaşam',
        type: 'savings',
        minAge: 18,
        maxAge: 60,
        minTerm: 10,
        maxTerm: 25,
        expectedReturn: 8.2,
        features: [
          'Esnek prim ödeme seçenekleri',
          'Kritik hastalık teminatı',
          'Fon yönetimi imkanı',
          'Bonus ve ikramiye',
        ],
      ),
      InsuranceProduct(
        name: 'Garanti Birikim Plus',
        company: 'Garanti Emeklilik',
        type: 'savings',
        minAge: 20,
        maxAge: 65,
        minTerm: 10,
        maxTerm: 35,
        expectedReturn: 7.9,
        features: [
          'Garantili asgari getiri',
          'Ölüm + Maluliyet teminatı',
          'Otomatik prim artışı',
          'Online yönetim',
        ],
      ),
    ];
  }

  static List<InsuranceProduct> _getTermProducts() {
    return [
      InsuranceProduct(
        name: 'Anadolu Hayat Tam Koruma',
        company: 'Anadolu Hayat',
        type: 'term',
        minAge: 18,
        maxAge: 70,
        minTerm: 1,
        maxTerm: 30,
        features: [
          'Uygun primler',
          'Esnek teminat tutarları',
          'Online işlem kolaylığı',
          'Kritik hastalık ek teminatı',
        ],
      ),
      InsuranceProduct(
        name: 'Allianz Yaşam Koruma',
        company: 'Allianz Yaşam',
        type: 'term',
        minAge: 18,
        maxAge: 65,
        minTerm: 5,
        maxTerm: 30,
        features: [
          'Kaza sonucu ölüm 2x ödeme',
          'Maluliyet teminatı',
          'Prim iadeli seçenek',
          '24/7 müşteri desteği',
          'Ücretsiz check-up',
        ],
      ),
      InsuranceProduct(
        name: 'AvivaSA Ailem Güvende',
        company: 'AvivaSA',
        type: 'term',
        minAge: 20,
        maxAge: 65,
        minTerm: 5,
        maxTerm: 25,
        features: [
          'Aile için toplu indirim',
          'Kritik hastalık teminatı',
          'Hastane günlüğü',
          'Online başvuru',
        ],
      ),
    ];
  }
}
