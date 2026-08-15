class BankAccount {
  final String id;
  final String name; // Örn: "İş Bankası", "Akbank"
  final String accountType; // Örn: "Kredi Kartı", "Vadesiz Hesap", "Kredi"
  final double overdraftInterestRate; // Aylık kredi/KMH faiz oranı
  final double bsmvRate; // Faiz üzerinden alınan BSMV oranı
  final double kkdfRate; // Faiz üzerinden alınan KKDF oranı
  final double overdraftLimit; // KMH veya Kredi Kartı Limiti
  final int paymentDay; // Hesap kesim / Vade günü (1-31)
  final int dueDay; // Son ödeme günü (Kredi kartı için)
  final bool isActive;

  final String currencyCode; // Para birimi (TRY, USD, EUR vb.)
  final double initialBalance; // Başlangıç bakiyesi
  final DateTime? createdAt; // İlk faiz dönemini belirlemek için

  const BankAccount({
    required this.id,
    required this.name,
    required this.accountType,
    this.overdraftInterestRate = 4.5,
    this.bsmvRate = 15,
    this.kkdfRate = 15,
    this.overdraftLimit = 0,
    this.paymentDay = 1,
    this.dueDay = 10,
    this.isActive = true,
    this.currencyCode = 'TRY',
    this.initialBalance = 0,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountType': accountType,
      'overdraftInterestRate': overdraftInterestRate,
      'bsmvRate': bsmvRate,
      'kkdfRate': kkdfRate,
      'overdraftLimit': overdraftLimit,
      'paymentDay': paymentDay,
      'dueDay': dueDay,
      'isActive': isActive,
      'currencyCode': currencyCode,
      'initialBalance': initialBalance,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] as String,
      overdraftInterestRate:
          (json['overdraftInterestRate'] as num?)?.toDouble() ?? 4.5,
      bsmvRate: (json['bsmvRate'] as num?)?.toDouble() ?? 15,
      kkdfRate: (json['kkdfRate'] as num?)?.toDouble() ?? 15,
      overdraftLimit: (json['overdraftLimit'] as num?)?.toDouble() ?? 0,
      paymentDay: json['paymentDay'] as int? ?? 1,
      dueDay: json['dueDay'] as int? ?? 10,
      isActive: json['isActive'] as bool? ?? true,
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  BankAccount copyWith({
    String? id,
    String? name,
    String? accountType,
    double? overdraftInterestRate,
    double? bsmvRate,
    double? kkdfRate,
    double? overdraftLimit,
    int? paymentDay,
    int? dueDay,
    bool? isActive,
    String? currencyCode,
    double? initialBalance,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      overdraftInterestRate:
          overdraftInterestRate ?? this.overdraftInterestRate,
      bsmvRate: bsmvRate ?? this.bsmvRate,
      kkdfRate: kkdfRate ?? this.kkdfRate,
      overdraftLimit: overdraftLimit ?? this.overdraftLimit,
      paymentDay: paymentDay ?? this.paymentDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      currencyCode: currencyCode ?? this.currencyCode,
      initialBalance: initialBalance ?? this.initialBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Gecikme faizi hesapla
  /// [amount] Borç tutarı
  /// [days] Gecikme gün sayısı
  /// Returns: Faiz tutarı
  double calculateInterest(double amount, int days) {
    if (days <= 0 || amount <= 0) return 0;

    // Saklanan oran aylıktır; gecikme hesabında 30 güne bölünür.
    final dailyRate = overdraftInterestRate / 100 / 30;
    return amount * dailyRate * days;
  }

  /// Hesap kesiminde negatif güncel bakiye için faiz ve vergileri hesaplar.
  StatementChargeBreakdown calculateStatementCharges(double currentBalance) {
    final debt = currentBalance < 0 ? -currentBalance : 0.0;
    if (debt <= 0 || overdraftInterestRate <= 0) {
      return const StatementChargeBreakdown();
    }

    final interest = debt * overdraftInterestRate / 100;
    final bsmv = interest * bsmvRate / 100;
    final kkdf = interest * kkdfRate / 100;
    return StatementChargeBreakdown(
      debt: debt,
      interest: interest,
      bsmv: bsmv,
      kkdf: kkdf,
    );
  }

  /// Toplam ödenmesi gereken tutar (ana para + faiz)
  double calculateTotalAmount(double amount, int days) {
    return amount + calculateInterest(amount, days);
  }
}

class StatementChargeBreakdown {
  final double debt;
  final double interest;
  final double bsmv;
  final double kkdf;

  const StatementChargeBreakdown({
    this.debt = 0,
    this.interest = 0,
    this.bsmv = 0,
    this.kkdf = 0,
  });

  double get tax => bsmv + kkdf;
  double get total => interest + tax;
}

// Varsayılan banka hesapları
class DefaultBankAccounts {
  static const List<BankAccount> accounts = [
    // Vadesiz Hesaplar
    BankAccount(
        id: 'isbank',
        name: 'İş Bankası',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 25000,
        paymentDay: 15),
    BankAccount(
        id: 'akbank',
        name: 'Akbank',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 15000,
        paymentDay: 1),
    BankAccount(
        id: 'garanti',
        name: 'Garanti BBVA',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 20000,
        paymentDay: 20),
    BankAccount(
        id: 'yapi_kredi',
        name: 'Yapı Kredi',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 10000,
        paymentDay: 10),
    BankAccount(
        id: 'ziraat',
        name: 'Ziraat Bankası',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 30000,
        paymentDay: 5),

    // Kredi Kartları
    BankAccount(
        id: 'isbank_cc',
        name: 'Maximum Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 150000,
        paymentDay: 15,
        dueDay: 25),
    BankAccount(
        id: 'akbank_cc',
        name: 'Wings Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 80000,
        paymentDay: 1,
        dueDay: 11),
    BankAccount(
        id: 'garanti_cc',
        name: 'Bonus Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 60000,
        paymentDay: 20,
        dueDay: 30),
    BankAccount(
        id: 'yapi_kredi_cc',
        name: 'World Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 120000,
        paymentDay: 10,
        dueDay: 20),
    BankAccount(
        id: 'ziraat_cc',
        name: 'Bankkart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 40000,
        paymentDay: 5,
        dueDay: 15),
  ];
}
