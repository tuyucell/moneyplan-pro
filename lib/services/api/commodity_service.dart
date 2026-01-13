import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CommodityService {
  // Free API: Commodities-API
  // Sign up at: https://commodities-api.com/
  // Free tier: 100 requests/month
  static const String _apiKey =
      'YOUR_API_KEY_HERE'; // Replace with your API key
  static const String _baseUrl = 'https://www.commodities-api.com/api';

  // Alternative: Use demo mode for testing
  static const bool _useDemoMode = true; // Set to false when you have API key

  static Future<Map<String, CommodityData>> getCommodityPrices() async {
    if (_useDemoMode || _apiKey == 'YOUR_API_KEY_HERE') {
      // Demo mode: return realistic static data
      return _getDemoData();
    }

    try {
      // Real API call
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/latest?access_key=$_apiKey&base=USD&symbols=XAU,XAG,XCU,XPT,XPD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCommodityData(data);
      } else {
        debugPrint('API Error: ${response.statusCode}');
        return _getDemoData();
      }
    } catch (e) {
      debugPrint('Commodity API Error: $e');
      return _getDemoData();
    }
  }

  static Map<String, CommodityData> _parseCommodityData(
      Map<String, dynamic> apiData) {
    // Parse API response and convert to our format
    final rates = apiData['rates'] as Map<String, dynamic>;

    return {
      'XAU': CommodityData(
        symbol: 'XAU',
        name: 'Altın',
        nameEn: 'Gold',
        price: (rates['XAU'] as num?)?.toDouble() ?? 2042.30,
        change24h: 0.67, // API doesn't provide 24h change in free tier
        unit: 'oz',
        category: 'Kıymetli Metal',
      ),
      // Add more commodities...
    };
  }

  static Future<Map<String, CommodityData>> _getDemoData() async {
    // No delay - load immediately
    // await Future.delayed(const Duration(milliseconds: 300));

    // Real-ish commodity prices (as of Dec 2025)
    // These would come from API in production
    return {
      'XAU': CommodityData(
        symbol: 'XAU',
        name: 'Altın',
        nameEn: 'Gold',
        price: 2042.30,
        change24h: 0.67,
        unit: 'oz',
        category: 'Kıymetli Metal',
      ),
      'XAG': CommodityData(
        symbol: 'XAG',
        name: 'Gümüş',
        nameEn: 'Silver',
        price: 24.85,
        change24h: -0.32,
        unit: 'oz',
        category: 'Kıymetli Metal',
      ),
      'WTI': CommodityData(
        symbol: 'WTI',
        name: 'Petrol (WTI)',
        nameEn: 'Crude Oil (WTI)',
        price: 77.45,
        change24h: -1.23,
        unit: 'barrel',
        category: 'Enerji',
      ),
      'BRENT': CommodityData(
        symbol: 'BRENT',
        name: 'Petrol (Brent)',
        nameEn: 'Crude Oil (Brent)',
        price: 82.15,
        change24h: -0.98,
        unit: 'barrel',
        category: 'Enerji',
      ),
      'XCU': CommodityData(
        symbol: 'XCU',
        name: 'Bakır',
        nameEn: 'Copper',
        price: 3.87,
        change24h: 0.92,
        unit: 'lb',
        category: 'Metaller',
      ),
      'NATGAS': CommodityData(
        symbol: 'NATGAS',
        name: 'Doğal Gaz',
        nameEn: 'Natural Gas',
        price: 3.25,
        change24h: 1.45,
        unit: 'MMBtu',
        category: 'Enerji',
      ),
      'XPT': CommodityData(
        symbol: 'XPT',
        name: 'Platin',
        nameEn: 'Platinum',
        price: 945.20,
        change24h: 0.15,
        unit: 'oz',
        category: 'Kıymetli Metal',
      ),
      'XPD': CommodityData(
        symbol: 'XPD',
        name: 'Paladyum',
        nameEn: 'Palladium',
        price: 1028.50,
        change24h: -1.05,
        unit: 'oz',
        category: 'Kıymetli Metal',
      ),
      'ZW': CommodityData(
        symbol: 'ZW',
        name: 'Buğday',
        nameEn: 'Wheat',
        price: 625.75,
        change24h: -0.15,
        unit: 'bushel',
        category: 'Tarım',
      ),
      'ZC': CommodityData(
        symbol: 'ZC',
        name: 'Mısır',
        nameEn: 'Corn',
        price: 485.25,
        change24h: 0.42,
        unit: 'bushel',
        category: 'Tarım',
      ),
      'ZS': CommodityData(
        symbol: 'ZS',
        name: 'Soya Fasulyesi',
        nameEn: 'Soybeans',
        price: 1245.80,
        change24h: -0.28,
        unit: 'bushel',
        category: 'Tarım',
      ),
      'COTTON': CommodityData(
        symbol: 'COTTON',
        name: 'Pamuk',
        nameEn: 'Cotton',
        price: 82.45,
        change24h: 0.18,
        unit: 'lb',
        category: 'Tarım',
      ),
      'COFFEE': CommodityData(
        symbol: 'COFFEE',
        name: 'Kahve',
        nameEn: 'Coffee',
        price: 185.30,
        change24h: 1.25,
        unit: 'lb',
        category: 'Tarım',
      ),
      'SUGAR': CommodityData(
        symbol: 'SUGAR',
        name: 'Şeker',
        nameEn: 'Sugar',
        price: 21.45,
        change24h: -0.65,
        unit: 'lb',
        category: 'Tarım',
      ),
      'COCOA': CommodityData(
        symbol: 'COCOA',
        name: 'Kakao',
        nameEn: 'Cocoa',
        price: 4250.00,
        change24h: 0.85,
        unit: 'ton',
        category: 'Tarım',
      ),
    };
  }

  // Future implementation with real API
  static Future<Map<String, CommodityData>> fetchFromAPI() async {
    // Example: Alpha Vantage (requires API key)
    // const apiKey = 'YOUR_API_KEY';
    // final url = 'https://www.alphavantage.co/query?function=COMMODITY&symbol=WTI&interval=daily&apikey=$apiKey';

    // Example: Metals-API (requires API key)
    // const apiKey = 'YOUR_API_KEY';
    // final url = 'https://metals-api.com/api/latest?access_key=$apiKey&base=USD&symbols=XAU,XAG,XPT,XPD';

    // For now, return mock data
    return getCommodityPrices();
  }
}

class CommodityData {
  final String symbol;
  final String name;
  final String nameEn;
  final double price;
  final double change24h;
  final String unit;
  final String category;

  CommodityData({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.change24h,
    required this.unit,
    required this.category,
  });

  factory CommodityData.fromJson(Map<String, dynamic> json) {
    return CommodityData(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      price: (json['price'] as num).toDouble(),
      change24h: (json['change_24h'] as num).toDouble(),
      unit: json['unit'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'name_en': nameEn,
      'price': price,
      'change_24h': change24h,
      'unit': unit,
      'category': category,
    };
  }
}
