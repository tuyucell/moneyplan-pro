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
  final String? parentId;
  final bool isBES; // Bireysel Emeklilik Sistemi
  final bool isSaving; // Tasarruf/Yatırım mı?

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.isBES = false,
    this.isSaving = false,
  });

  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
        id: 'salary', name: 'Maaş', type: TransactionType.income),
    TransactionCategory(
        id: 'freelance', name: 'Serbest Çalışma', type: TransactionType.income),
    TransactionCategory(
        id: 'investment', name: 'Yatırım Geliri', type: TransactionType.income),
    TransactionCategory(
        id: 'rental', name: 'Kira Geliri', type: TransactionType.income),
    TransactionCategory(
        id: 'bonus', name: 'Bonus', type: TransactionType.income),
    TransactionCategory(
        id: 'other_income', name: 'Diğer Gelir', type: TransactionType.income),
  ];

  static const List<TransactionCategory> expenseCategories = [
    // Banka (Ana Kategori)
    TransactionCategory(
        id: 'bank', name: 'Banka', type: TransactionType.expense),
    TransactionCategory(
        id: 'bank_credit_card',
        name: 'Kredi Kartı',
        type: TransactionType.expense,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_loan',
        name: 'Kredi',
        type: TransactionType.expense,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_flexible',
        name: 'Esnek Hesap / Artı Para',
        type: TransactionType.expense,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_interest',
        name: 'Faiz Gideri',
        type: TransactionType.expense,
        parentId: 'bank'),
    TransactionCategory(
        id: 'bank_tax',
        name: 'Vergi Gideri (BSMV/KKDF)',
        type: TransactionType.expense,
        parentId: 'bank'),

    // Kira
    TransactionCategory(
        id: 'rent', name: 'Kira', type: TransactionType.expense),

    // Fatura
    TransactionCategory(
        id: 'bills', name: 'Fatura', type: TransactionType.expense),
    TransactionCategory(
        id: 'bills_electric',
        name: 'Elektrik',
        type: TransactionType.expense,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_water',
        name: 'Su',
        type: TransactionType.expense,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_gas',
        name: 'Doğalgaz',
        type: TransactionType.expense,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_internet',
        name: 'İnternet',
        type: TransactionType.expense,
        parentId: 'bills'),
    TransactionCategory(
        id: 'bills_phone',
        name: 'Telefon',
        type: TransactionType.expense,
        parentId: 'bills'),

    // BES (Bireysel Emeklilik Sistemi)
    TransactionCategory(
        id: 'bes',
        name: 'BES',
        type: TransactionType.expense,
        isBES: true,
        isSaving: true),

    // Sağlık
    TransactionCategory(
        id: 'health', name: 'Sağlık', type: TransactionType.expense),
    TransactionCategory(
        id: 'health_doctor',
        name: 'Doktor',
        type: TransactionType.expense,
        parentId: 'health'),
    TransactionCategory(
        id: 'health_medicine',
        name: 'İlaç',
        type: TransactionType.expense,
        parentId: 'health'),
    TransactionCategory(
        id: 'health_insurance',
        name: 'Sağlık Sigortası',
        type: TransactionType.expense,
        parentId: 'health'),

    // Ulaşım
    TransactionCategory(
        id: 'transportation', name: 'Ulaşım', type: TransactionType.expense),
    TransactionCategory(
        id: 'transportation_public',
        name: 'Toplu Taşıma',
        type: TransactionType.expense,
        parentId: 'transportation'),
    TransactionCategory(
        id: 'transportation_fuel',
        name: 'Yakıt',
        type: TransactionType.expense,
        parentId: 'transportation'),
    TransactionCategory(
        id: 'transportation_taxi',
        name: 'Taksi',
        type: TransactionType.expense,
        parentId: 'transportation'),

    // Araç
    TransactionCategory(
        id: 'vehicle', name: 'Araç', type: TransactionType.expense),
    TransactionCategory(
        id: 'vehicle_car',
        name: 'Otomobil',
        type: TransactionType.expense,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_motorcycle',
        name: 'Motor',
        type: TransactionType.expense,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_maintenance',
        name: 'Bakım/Onarım',
        type: TransactionType.expense,
        parentId: 'vehicle'),
    TransactionCategory(
        id: 'vehicle_insurance',
        name: 'Araç Sigortası',
        type: TransactionType.expense,
        parentId: 'vehicle'),

    // Eğlence
    TransactionCategory(
        id: 'entertainment', name: 'Eğlence', type: TransactionType.expense),
    TransactionCategory(
        id: 'entertainment_cinema',
        name: 'Sinema',
        type: TransactionType.expense,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_concert',
        name: 'Konser',
        type: TransactionType.expense,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_sport',
        name: 'Spor',
        type: TransactionType.expense,
        parentId: 'entertainment'),
    TransactionCategory(
        id: 'entertainment_hobby',
        name: 'Hobi',
        type: TransactionType.expense,
        parentId: 'entertainment'),

    // Yemek/Market
    TransactionCategory(
        id: 'food_market', name: 'Yemek/Market', type: TransactionType.expense),
    TransactionCategory(
        id: 'food_grocery',
        name: 'Market Alışverişi',
        type: TransactionType.expense,
        parentId: 'food_market'),
    TransactionCategory(
        id: 'food_restaurant',
        name: 'Restoran',
        type: TransactionType.expense,
        parentId: 'food_market'),
    TransactionCategory(
        id: 'food_cafe',
        name: 'Kafe',
        type: TransactionType.expense,
        parentId: 'food_market'),

    // Sigorta
    TransactionCategory(
        id: 'insurance', name: 'Sigorta', type: TransactionType.expense),
    TransactionCategory(
        id: 'insurance_life',
        name: 'Hayat Sigortası',
        type: TransactionType.expense,
        parentId: 'insurance'),
    TransactionCategory(
        id: 'insurance_health',
        name: 'Sağlık Sigortası',
        type: TransactionType.expense,
        parentId: 'insurance'),

    // Diğer
    TransactionCategory(
        id: 'savings',
        name: 'Yatırım/Birikim',
        type: TransactionType.expense,
        isSaving: true),
    TransactionCategory(
        id: 'other_expense',
        name: 'Diğer Giderler',
        type: TransactionType.expense),
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
