import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moneyplan_pro/core/config/env_config.dart';
import 'package:moneyplan_pro/features/search/data/models/asset.dart';
import 'package:moneyplan_pro/features/exchanges/data/models/exchange.dart';
import 'package:moneyplan_pro/features/exchanges/data/models/asset_exchange.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    EnvConfig.validate();

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // =====================================================
  // ASSETS
  // =====================================================

  /// Tüm varlıkları getir
  static Future<List<Asset>> getAssets({
    int? categoryId,
    bool? isPopular,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = client.from('assets').select('''
      *,
      category:asset_categories(*)
    ''');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (isPopular != null) {
      query = query.eq('is_popular', isPopular);
    }

    final response = await query
        .eq('is_active', true)
        .order('is_popular', ascending: false)
        .order('volume_24h_usd', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Asset.fromJson(json)).toList();
  }

  /// Varlık ara
  static Future<List<Asset>> searchAssets(String query) async {
    if (query.isEmpty) return [];

    final response = await client.rpc('search_assets', params: {
      'search_term': query,
      'limit_count': 20,
    });

    return (response as List).map((json) => Asset.fromJson(json)).toList();
  }

  /// Tek bir varlık getir
  static Future<Asset?> getAsset(String id) async {
    final response = await client
        .from('assets')
        .select('''
          *,
          category:asset_categories(*)
        ''')
        .eq('id', id)
        .single();

    return Asset.fromJson(response);
  }

  // =====================================================
  // EXCHANGES
  // =====================================================

  /// Bir varlığın işlem gördüğü borsaları getir
  static Future<List<AssetExchange>> getAssetExchanges(String assetId) async {
    final response = await client
        .from('asset_exchanges')
        .select('''
          *,
          exchange:exchanges(*),
          asset:assets(*)
        ''')
        .eq('asset_id', assetId)
        .eq('is_active', true)
        .order('volume_24h_usd', ascending: false);

    return (response as List)
        .map((json) => AssetExchange.fromJson(json))
        .toList();
  }

  /// Borsa detaylarını getir
  static Future<Exchange?> getExchange(String exchangeId) async {
    final response = await client
        .from('exchanges')
        .select('*')
        .eq('id', exchangeId)
        .single();

    return Exchange.fromJson(response);
  }

  /// Borsa detay bilgilerini getir
  static Future<Map<String, dynamic>?> getExchangeDetails(
      String exchangeId) async {
    final response = await client
        .from('exchange_details')
        .select('*')
        .eq('exchange_id', exchangeId)
        .maybeSingle();

    return response;
  }

  /// Borsa yorumlarını getir
  static Future<List<Map<String, dynamic>>> getExchangeReviews(
    String exchangeId, {
    int limit = 10,
  }) async {
    final response = await client
        .from('exchange_reviews')
        .select('*')
        .eq('exchange_id', exchangeId)
        .eq('is_approved', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  // =====================================================
  // USER DATA
  // =====================================================

  /// Kullanıcı favorilerini getir
  static Future<List<Asset>> getUserFavorites(String userId) async {
    final response = await client
        .from('user_favorites')
        .select('''
          *,
          asset:assets(
            *,
            category:asset_categories(*)
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Asset.fromJson(json['asset']))
        .toList();
  }

  /// Favorilere ekle
  static Future<void> addToFavorites(String userId, String assetId) async {
    await client.from('user_favorites').insert({
      'user_id': userId,
      'asset_id': assetId,
    });
  }

  /// Favorilerden çıkar
  static Future<void> removeFromFavorites(String userId, String assetId) async {
    await client
        .from('user_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('asset_id', assetId);
  }

  /// Arama geçmişi kaydet
  static Future<void> saveSearchHistory(
    String userId,
    String query, {
    String? assetId,
  }) async {
    await client.from('search_history').insert({
      'user_id': userId,
      'search_query': query,
      'asset_id': assetId,
    });
  }

  /// Arama geçmişini getir
  static Future<List<String>> getSearchHistory(String userId,
      {int limit = 10}) async {
    final response = await client
        .from('search_history')
        .select('search_query')
        .eq('user_id', userId)
        .order('searched_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => json['search_query'] as String)
        .toSet()
        .toList();
  }

  /// Popüler aramaları getir
  static Future<List<Asset>> getPopularSearches({int limit = 10}) async {
    final response = await client
        .from('popular_searches')
        .select('''
          *,
          asset:assets(
            *,
            category:asset_categories(*)
          )
        ''')
        .eq('period', 'daily')
        .order('search_count', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => Asset.fromJson(json['asset']))
        .toList();
  }

  // =====================================================
  // USER PORTFOLIO (Optional)
  // =====================================================

  /// Kullanıcı portföyünü getir
  static Future<List<Map<String, dynamic>>> getUserPortfolio(
      String userId) async {
    final response = await client
        .from('user_portfolio')
        .select('''
          *,
          asset:assets(*),
          exchange:exchanges(*)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Portföye ekle
  static Future<void> addToPortfolio({
    required String userId,
    required String assetId,
    String? exchangeId,
    required double quantity,
    double? averageBuyPrice,
    String currency = 'USD',
    String? notes,
  }) async {
    await client.from('user_portfolio').insert({
      'user_id': userId,
      'asset_id': assetId,
      'exchange_id': exchangeId,
      'quantity': quantity,
      'average_buy_price': averageBuyPrice,
      'currency': currency,
      'notes': notes,
    });
  }
}
