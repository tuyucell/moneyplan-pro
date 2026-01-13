import 'package:flutter/foundation.dart';

class ETFService {
  // Alternative: Use demo mode for testing
  static const bool _useDemoMode = true;

  static Future<Map<String, ETFData>> getETFPrices() async {
    if (_useDemoMode) {
      return _getDemoData();
    }

    try {
      // Real API call would go here
      return _getDemoData();
    } catch (e) {
      debugPrint('ETF API Error: $e');
      return _getDemoData();
    }
  }

  static Future<Map<String, ETFData>> _getDemoData() async {
    // Real-ish ETF prices (as of Dec 2025)
    return {
      'SPY': ETFData(
        symbol: 'SPY',
        name: 'S&P 500 ETF',
        nameEn: 'SPDR S&P 500 ETF Trust',
        price: 565.00,
        change24h: 0.85,
        category: 'Index ETF',
        expenseRatio: 0.09,
      ),
      'QQQ': ETFData(
        symbol: 'QQQ',
        name: 'Nasdaq 100 ETF',
        nameEn: 'Invesco QQQ Trust',
        price: 485.00,
        change24h: 1.25,
        category: 'Index ETF',
        expenseRatio: 0.20,
      ),
      'VOO': ETFData(
        symbol: 'VOO',
        name: 'Vanguard S&P 500',
        nameEn: 'Vanguard S&P 500 ETF',
        price: 520.00,
        change24h: 0.82,
        category: 'Index ETF',
        expenseRatio: 0.03,
      ),
      'VTI': ETFData(
        symbol: 'VTI',
        name: 'Vanguard Total Market',
        nameEn: 'Vanguard Total Stock Market ETF',
        price: 265.00,
        change24h: 0.95,
        category: 'Index ETF',
        expenseRatio: 0.03,
      ),
      'IWM': ETFData(
        symbol: 'IWM',
        name: 'Russell 2000 ETF',
        nameEn: 'iShares Russell 2000 ETF',
        price: 205.00,
        change24h: 1.15,
        category: 'Small Cap ETF',
        expenseRatio: 0.19,
      ),
      'DIA': ETFData(
        symbol: 'DIA',
        name: 'Dow Jones ETF',
        nameEn: 'SPDR Dow Jones Industrial Average ETF',
        price: 385.00,
        change24h: 0.65,
        category: 'Index ETF',
        expenseRatio: 0.16,
      ),
      'EEM': ETFData(
        symbol: 'EEM',
        name: 'Emerging Markets ETF',
        nameEn: 'iShares MSCI Emerging Markets ETF',
        price: 42.50,
        change24h: 0.75,
        category: 'International ETF',
        expenseRatio: 0.68,
      ),
      'VWO': ETFData(
        symbol: 'VWO',
        name: 'Vanguard Emerging',
        nameEn: 'Vanguard FTSE Emerging Markets ETF',
        price: 45.00,
        change24h: 0.85,
        category: 'International ETF',
        expenseRatio: 0.08,
      ),
      'GLD': ETFData(
        symbol: 'GLD',
        name: 'Gold ETF',
        nameEn: 'SPDR Gold Shares',
        price: 195.00,
        change24h: 0.45,
        category: 'Commodity ETF',
        expenseRatio: 0.40,
      ),
      'SLV': ETFData(
        symbol: 'SLV',
        name: 'Silver ETF',
        nameEn: 'iShares Silver Trust',
        price: 23.50,
        change24h: -0.25,
        category: 'Commodity ETF',
        expenseRatio: 0.50,
      ),
      'USO': ETFData(
        symbol: 'USO',
        name: 'Oil ETF',
        nameEn: 'United States Oil Fund',
        price: 78.00,
        change24h: -0.85,
        category: 'Commodity ETF',
        expenseRatio: 0.79,
      ),
      'TLT': ETFData(
        symbol: 'TLT',
        name: 'Treasury Bond ETF',
        nameEn: 'iShares 20+ Year Treasury Bond ETF',
        price: 92.50,
        change24h: 0.35,
        category: 'Bond ETF',
        expenseRatio: 0.15,
      ),
      'XLF': ETFData(
        symbol: 'XLF',
        name: 'Financial Sector ETF',
        nameEn: 'Financial Select Sector SPDR Fund',
        price: 42.00,
        change24h: 0.55,
        category: 'Sector ETF',
        expenseRatio: 0.10,
      ),
      'XLK': ETFData(
        symbol: 'XLK',
        name: 'Technology Sector ETF',
        nameEn: 'Technology Select Sector SPDR Fund',
        price: 210.00,
        change24h: 1.15,
        category: 'Sector ETF',
        expenseRatio: 0.10,
      ),
      'XLE': ETFData(
        symbol: 'XLE',
        name: 'Energy Sector ETF',
        nameEn: 'Energy Select Sector SPDR Fund',
        price: 88.50,
        change24h: -0.45,
        category: 'Sector ETF',
        expenseRatio: 0.10,
      ),
      'XLV': ETFData(
        symbol: 'XLV',
        name: 'Healthcare Sector ETF',
        nameEn: 'Health Care Select Sector SPDR Fund',
        price: 145.00,
        change24h: 0.65,
        category: 'Sector ETF',
        expenseRatio: 0.10,
      ),
      'VNQ': ETFData(
        symbol: 'VNQ',
        name: 'Real Estate ETF',
        nameEn: 'Vanguard Real Estate ETF',
        price: 85.00,
        change24h: 0.75,
        category: 'Real Estate ETF',
        expenseRatio: 0.12,
      ),
      'ARKK': ETFData(
        symbol: 'ARKK',
        name: 'ARK Innovation ETF',
        nameEn: 'ARK Innovation ETF',
        price: 52.00,
        change24h: 2.15,
        category: 'Growth ETF',
        expenseRatio: 0.75,
      ),
      'IEMG': ETFData(
        symbol: 'IEMG',
        name: 'iShares Emerging Markets',
        nameEn: 'iShares Core MSCI Emerging Markets ETF',
        price: 52.50,
        change24h: 0.85,
        category: 'International ETF',
        expenseRatio: 0.09,
      ),
      'SCHD': ETFData(
        symbol: 'SCHD',
        name: 'Schwab Dividend ETF',
        nameEn: 'Schwab US Dividend Equity ETF',
        price: 78.00,
        change24h: 0.45,
        category: 'Dividend ETF',
        expenseRatio: 0.06,
      ),
    };
  }
}

class ETFData {
  final String symbol;
  final String name;
  final String nameEn;
  final double price;
  final double change24h;
  final String category;
  final double expenseRatio; // Expense ratio in percentage

  ETFData({
    required this.symbol,
    required this.name,
    required this.nameEn,
    required this.price,
    required this.change24h,
    required this.category,
    required this.expenseRatio,
  });

  factory ETFData.fromJson(Map<String, dynamic> json) {
    return ETFData(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] as String,
      price: (json['price'] as num).toDouble(),
      change24h: (json['change_24h'] as num).toDouble(),
      category: json['category'] as String,
      expenseRatio: (json['expense_ratio'] as num).toDouble(),
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
      'expense_ratio': expenseRatio,
    };
  }
}
