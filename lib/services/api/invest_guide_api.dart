import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

class InvestGuideApi {
  // Emulator için localhost: 10.0.2.2, Gerçek cihaz/iOS simulator için: localhost veya LAN IP
  // Sunucuya attığınızda buraya sunucu IP'sini yazacağız.
  static const String _baseUrl = '${ApiConstants.baseUrl}/api/v1';

  static const Duration _timeout =
      Duration(seconds: 60); // Increased from 30 seconds

  /// Tüm piyasa özetini getirir (Ana sayfa ticker için)
  static Future<Map<String, dynamic>> getMarketSummary() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/summary'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint('API Error (Summary): $e');
      return {};
    }
  }

  /// Kripto para listesini getirir
  static Future<List<dynamic>> getCryptoMarkets({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/crypto?limit=$limit'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Crypto): $e');
      return [];
    }
  }

  /// Kripto Korku ve Açgözlülük Endeksini getirir
  static Future<Map<String, dynamic>?> getCryptoFearGreed() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/crypto/fear-greed'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('API Error (FearGreed): $e');
      return null;
    }
  }

  /// TCMB Döviz kurlarını getirir
  static Future<List<dynamic>> getCurrencies() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/currencies/tcmb'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Currencies): $e');
      return [];
    }
  }

  /// En çok kazandıran fonları getirir
  static Future<List<dynamic>> getTopFunds() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/funds/top')).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Top Funds): $e');
      return [];
    }
  }

  /// BES (Bireysel Emeklilik) fonlarını getirir
  static Future<List<dynamic>> getPensionFunds() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/funds/bes/top'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Pension Funds): $e');
      return [];
    }
  }

  /// Hisse Senetlerini getirir
  static Future<List<dynamic>> getStocks() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/stocks'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Stocks): $e');
      return [];
    }
  }

  /// Emtia verilerini getirir
  static Future<List<dynamic>> getCommodities() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/commodities'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Commodities): $e');
      return [];
    }
  }

  /// ETF verilerini getirir
  static Future<List<dynamic>> getETFs() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/market/etfs')).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (ETFs): $e');
      return [];
    }
  }

  /// Tahvil verilerini getirir
  static Future<List<dynamic>> getBonds() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/market/bonds')).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Bonds): $e');
      return [];
    }
  }

  /// Detaylı varlık verilerini (F/K, Piyasa Değeri vb.) getirir
  static Future<Map<String, dynamic>?> getAssetDetail(String symbol) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/detail/$symbol'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('API Error (Asset Detail): $e');
      return null;
    }
  }

  /// Geçmiş fiyat verilerini getirir (Grafik için)
  static Future<List<dynamic>> getMarketHistory(String symbol,
      {String period = '1mo'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/history/$symbol?period=$period'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (History): $e');
      return [];
    }
  }

  /// Yatırım Fonu detayını getirir
  static Future<Map<String, dynamic>?> getFundDetail(String code) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/funds/$code')).timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('API Error (Fund): $e');
      return null;
    }
  }

  /// En güncel finans haberlerini getirir
  static Future<List<dynamic>> getNews({int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/news?limit=$limit'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (News): $e');
      return [];
    }
  }

  /// Ekonomik takvim verilerini getirir
  static Future<List<dynamic>> getEconomicCalendar() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/market/calendar'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('API Error (Calendar): $e');
      return [];
    }
  }
}
