import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense,
}

enum RecurrenceType {
  none,
  monthly,
  yearly,
}

class TransactionCategory {
  final String id;
  final String name;
  final TransactionType type;
  final IconData icon;
  final String? parentId;
  final bool isBES; // Bireysel Emeklilik Sistemi
  final bool isSaving; // Tasarruf/Yatırım mı?

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.parentId,
    this.isBES = false,
    this.isSaving = false,
  });

  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
        id: 'salary',
        name: 'Maaş',
        type: TransactionType.income,
        icon: Icons.payments),
    TransactionCategory(
        id: 'freelance',
        name: 'Serbest Çalışma',
        type: TransactionType.income,
        icon: Icons.computer),
    TransactionCategory(
        id: 'investment',
        name: 'Yatırım Geliri',
        type: TransactionType.income,
        icon: Icons.trending_up),
    TransactionCategory(
        id: 'rental',
        name: 'Kira Geliri',
        type: TransactionType.income,
        icon: Icons.home),
    TransactionCategory(
        id: 'bonus',
        name: 'Bonus',
        type: TransactionType.income,
        icon: Icons.card_giftcard),
    TransactionCategory(
        id: 'other_income',
        name: 'Diğer Gelir',
        type: TransactionType.income,
        icon: Icons.add_circle_outline),
  ];

  static const List<TransactionCategory> expenseCategories = [
    // Banka (Ana Kategori)
    TransactionCategory(
        id: 'bank',
        name: 'Banka',
        type: TransactionType.expense,
        icon: Icons.account_balance),
    TransactionCategory(
        id: 'bank_credit_card',
        name: 'Kredi Kartı',
        type: TransactionType.expense,
        icon: Icons.credit_card,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_loan',
        name: 'Kredi',
        type: TransactionType.expense,
        icon: Icons.real_estate_agent,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_flexible',
        name: 'Esnek Hesap / Artı Para',
        type: TransactionType.expense,
        icon: Icons.account_balance_wallet,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_interest',
        name: 'Faiz Gideri',
        type: TransactionType.expense,
        icon: Icons.percent,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_tax',
        name: 'Vergi Gideri (BSMV/KKDF)',
        type: TransactionType.expense,
        icon: Icons.gavel,
        parentId: 'bank'),

    // Kira
    TransactionCategory(
        id: 'rent',
        name: 'Kira',
        type: TransactionType.expense,
        icon: Icons.house),

    // Fatura
    TransactionCategory(
        id: 'bills',
        name: 'Fatura',
        type: TransactionType.expense,
        icon: Icons.receipt_long),
    TransactionCategory(
        id: 'bills_electric',
        name: 'Elektrik',
        type: TransactionType.expense,
        icon: Icons.electric_bolt,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_water',
        name: 'Su',
        type: TransactionType.expense,
        icon: Icons.water_drop,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_gas',
        name: 'Doğalgaz',
        type: TransactionType.expense,
        icon: Icons.gas_meter,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_internet',
        name: 'İnternet',
        type: TransactionType.expense,
        icon: Icons.wifi,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_phone',
        name: 'Telefon',
        type: TransactionType.expense,
        icon: Icons.smartphone,
        parentId: 'bills'),

    // BES (Bireysel Emeklilik Sistemi)
    TransactionCategory(
        id: 'bes',
        name: 'BES',
        type: TransactionType.expense,
        icon: Icons.savings,
        isBES: true,
        isSaving: true),

    // Sağlık
    TransactionCategory(
        id: 'health',
        name: 'Sağlık',
        type: TransactionType.expense,
        icon: Icons.medical_services),
    TransactionCategory(
        id: 'health_doctor',
        name: 'Doktor',
        type: TransactionType.expense,
        icon: Icons.person,
        parentId: 'health'),
    TransactionCategory(
        id: 'health_medicine',
        name: 'İlaç',
        type: TransactionType.expense,
        icon: Icons.medication,
        parentId: 'health'),
    TransactionCategory(
        id: 'health_insurance',
        name: 'Sağlık Sigortası',
        type: TransactionType.expense,
        icon: Icons.health_and_safety,
        parentId: 'health'),

    // Ulaşım
    TransactionCategory(
        id: 'transportation',
        name: 'Ulaşım',
        type: TransactionType.expense,
        icon: Icons.directions_bus),
    TransactionCategory(
        id: 'transportation_public',
        name: 'Toplu Taşıma',
        type: TransactionType.expense,
        icon: Icons.train,
        parentId: 'transportation'),
    TransactionCategory(
        id: 'transportation_fuel',
        name: 'Yakıt',
        type: TransactionType.expense,
        icon: Icons.local_gas_station,
        parentId: 'transportation'),
    TransactionCategory(
        id: 'transportation_taxi',
        name: 'Taksi',
        type: TransactionType.expense,
        icon: Icons.local_taxi,
        parentId: 'transportation'),

    // Araç
    TransactionCategory(
        id: 'vehicle',
        name: 'Araç',
        type: TransactionType.expense,
        icon: Icons.directions_car),
    TransactionCategory(
        id: 'vehicle_car',
        name: 'Otomobil',
        type: TransactionType.expense,
        icon: Icons.car_rental,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_motorcycle',
        name: 'Motor',
        type: TransactionType.expense,
        icon: Icons.motorcycle,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_maintenance',
        name: 'Bakım/Onarım',
        type: TransactionType.expense,
        icon: Icons.build,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_insurance',
        name: 'Araç Sigortası',
        type: TransactionType.expense,
        icon: Icons.minor_crash,
        parentId: 'vehicle'),

    // Eğlence
    TransactionCategory(
        id: 'entertainment',
        name: 'Eğlence',
        type: TransactionType.expense,
        icon: Icons.movie),
    TransactionCategory(
        id: 'entertainment_cinema',
        name: 'Sinema',
        type: TransactionType.expense,
        icon: Icons.movie_filter,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_concert',
        name: 'Konser',
        type: TransactionType.expense,
        icon: Icons.music_note,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_sport',
        name: 'Spor',
        type: TransactionType.expense,
        icon: Icons.sports_soccer,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_hobby',
        name: 'Hobi',
        type: TransactionType.expense,
        icon: Icons.palette,
        parentId: 'entertainment'),

    // Yemek/Market
    TransactionCategory(
        id: 'food_market',
        name: 'Yemek/Market',
        type: TransactionType.expense,
        icon: Icons.shopping_basket),
    TransactionCategory(
        id: 'food_grocery',
        name: 'Market Alışverişi',
        type: TransactionType.expense,
        icon: Icons.shopping_cart,
        parentId: 'food_market'),
    TransactionCategory(
        id: 'food_restaurant',
        name: 'Restoran',
        type: TransactionType.expense,
        icon: Icons.restaurant,
        parentId: 'food_market'),
    TransactionCategory(
        id: 'food_cafe',
        name: 'Kafe',
        type: TransactionType.expense,
        icon: Icons.coffee,
        parentId: 'food_market'),

    // Sigorta
    TransactionCategory(
        id: 'insurance',
        name: 'Sigorta',
        type: TransactionType.expense,
        icon: Icons.verified_user),
    TransactionCategory(
        id: 'insurance_life',
        name: 'Hayat Sigortası',
        type: TransactionType.expense,
        icon: Icons.favorite,
        parentId: 'insurance'),
    TransactionCategory(
        id: 'insurance_health',
        name: 'Sağlık Sigortası',
        type: TransactionType.expense,
        icon: Icons.medical_information,
        parentId: 'insurance'),

    // Diğer
    TransactionCategory(
        id: 'savings',
        name: 'Yatırım/Birikim',
        type: TransactionType.expense,
        icon: Icons.account_balance_wallet,
        isSaving: true),
    TransactionCategory(
        id: 'other_expense',
        name: 'Diğer Giderler',
        type: TransactionType.expense,
        icon: Icons.more_horiz),
  ];

  static List<TransactionCategory> get allCategories => [
        ...incomeCategories,
        ...expenseCategories,
      ];

  static TransactionCategory? findById(String id) {
    try {
      return allCategories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<TransactionCategory> getMainCategories(TransactionType type) {
    final categories =
        type == TransactionType.income ? incomeCategories : expenseCategories;
    return categories.where((cat) => cat.parentId == null).toList();
  }

  static List<TransactionCategory> getSubCategories(String parentId) {
    return expenseCategories.where((cat) => cat.parentId == parentId).toList();
  }

  bool get hasSubCategories {
    return expenseCategories.any((cat) => cat.parentId == id);
  }
}
