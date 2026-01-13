import 'package:flutter/foundation.dart';

class BondService {
  // Alternative: Use demo mode for testing
  static const bool _useDemoMode = true;

  static Future<Map<String, BondData>> getBondPrices() async {
    if (_useDemoMode) {
      return _getDemoData();
    }

    try {
      // Real API call would go here (e.g., FRED API)
      return _getDemoData();
    } catch (e) {
      debugPrint('Bond API Error: $e');
      return _getDemoData();
    }
  }

  static Future<Map<String, BondData>> _getDemoData() async {
    // Real-ish Bond yields (as of Dec 2025)
    return {
      'US10Y': BondData(
        symbol: 'US10Y',
        name: 'ABD 10 Yıllık Tahvil',
        nameEn: 'US 10-Year Treasury',
        price: 4.25,
        change24h: 0.05,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'ABD',
      ),
      'US2Y': BondData(
        symbol: 'US2Y',
        name: 'ABD 2 Yıllık Tahvil',
        nameEn: 'US 2-Year Treasury',
        price: 4.50,
        change24h: 0.08,
        category: 'Government Bond',
        maturity: '2 Yıl',
        country: 'ABD',
      ),
      'US30Y': BondData(
        symbol: 'US30Y',
        name: 'ABD 30 Yıllık Tahvil',
        nameEn: 'US 30-Year Treasury',
        price: 4.45,
        change24h: 0.03,
        category: 'Government Bond',
        maturity: '30 Yıl',
        country: 'ABD',
      ),
      'TR10Y': BondData(
        symbol: 'TR10Y',
        name: 'Türkiye 10 Yıllık',
        nameEn: 'Turkey 10-Year Bond',
        price: 27.50,
        change24h: 0.15,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Türkiye',
      ),
      'TR2Y': BondData(
        symbol: 'TR2Y',
        name: 'Türkiye 2 Yıllık',
        nameEn: 'Turkey 2-Year Bond',
        price: 28.00,
        change24h: 0.12,
        category: 'Government Bond',
        maturity: '2 Yıl',
        country: 'Türkiye',
      ),
      'DE10Y': BondData(
        symbol: 'DE10Y',
        name: 'Almanya 10 Yıllık',
        nameEn: 'Germany 10-Year Bund',
        price: 2.35,
        change24h: 0.02,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Almanya',
      ),
      'GB10Y': BondData(
        symbol: 'GB10Y',
        name: 'İngiltere 10 Yıllık',
        nameEn: 'UK 10-Year Gilt',
        price: 4.15,
        change24h: 0.04,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'İngiltere',
      ),
      'CN10Y': BondData(
        symbol: 'CN10Y',
        name: 'Çin 10 Yıllık',
        nameEn: 'China 10-Year Bond',
        price: 2.65,
        change24h: 0.02,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Çin',
      ),
      'AU10Y': BondData(
        symbol: 'AU10Y',
        name: 'Avustralya 10 Yıllık',
        nameEn: 'Australia 10-Year Bond',
        price: 4.35,
        change24h: 0.05,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Avustralya',
      ),
      'CA10Y': BondData(
        symbol: 'CA10Y',
        name: 'Kanada 10 Yıllık',
        nameEn: 'Canada 10-Year Bond',
        price: 3.55,
        change24h: 0.03,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Kanada',
      ),
      'JP10Y': BondData(
        symbol: 'JP10Y',
        name: 'Japonya 10 Yıllık',
        nameEn: 'Japan 10-Year JGB',
        price: 0.85,
        change24h: 0.01,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Japonya',
      ),
      'FR10Y': BondData(
        symbol: 'FR10Y',
        name: 'Fransa 10 Yıllık',
        nameEn: 'France 10-Year OAT',
        price: 2.85,
        change24h: 0.03,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'Fransa',
      ),
      'IT10Y': BondData(
        symbol: 'IT10Y',
        name: 'İtalya 10 Yıllık',
        nameEn: 'Italy 10-Year BTP',
        price: 3.95,
        change24h: 0.06,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'İtalya',
      ),
      'ES10Y': BondData(
        symbol: 'ES10Y',
        name: 'İspanya 10 Yıllık',
        nameEn: 'Spain 10-Year Bond',
        price: 3.25,
        change24h: 0.04,
        category: 'Government Bond',
        maturity: '10 Yıl',
        country: 'İspanya',
      ),
      'BR10Y': BondData(
        symbol: 'BR10Y',
        name: 'Brezilya 10 Yıllık',
        nameEn: 'Brazil 10-Year Bond',
        price: 12.50,
        change24h: 0.18,
        category: 'Emerging Market Bond',
        maturity: '10 Yıl',
        country: 'Brezilya',
      ),
      'IN10Y': BondData(
        symbol: 'IN10Y',
        name: 'Hindistan 10 Yıllık',
        nameEn: 'India 10-Year Bond',
        price: 7.15,
        change24h: 0.08,
        category: 'Emerging Market Bond',
        maturity: '10 Yıl',
        country: 'Hindistan',
      ),
      'MX10Y': BondData(
        symbol: 'MX10Y',
        name: 'Meksika 10 Yıllık',
        nameEn: 'Mexico 10-Year Bond',
        price: 9.75,
        change24h: 0.12,
        category: 'Emerging Market Bond',
        maturity: '10 Yıl',
        country: 'Meksika',
      ),
      'ZA10Y': BondData(
        symbol: 'ZA10Y',
        name: 'Güney Afrika 10 Yıllık',
        nameEn: 'South Africa 10-Year Bond',
        price: 10.50,
        change24h: 0.15,
        category: 'Emerging Market Bond',
        maturity: '10 Yıl',
        country: 'Güney Afrika',
      ),
    };
  }
}

class BondData {
  final String symbol;
  final String name;
  final String nameEn;
  final double price; // Yield in percentage
  final double change24h;
  final String category;
  final String maturity;
  final String country;

  BondData({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.change24h,
    required this.category,
    required this.maturity,
    required this.country,
  });

  factory BondData.fromJson(Map<String, dynamic> json) {
    return BondData(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      price: (json['price'] as num).toDouble(),
      change24h: (json['change_24h'] as num).toDouble(),
      category: json['category'] as String,
      maturity: json['maturity'] as String,
      country: json['country'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'name_en': nameEn,
      'price': price,
      'change_24h': change24h,
      'category': category,
      'maturity': maturity,
      'country': country,
    };
  }
}
