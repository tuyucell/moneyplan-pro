import 'package:invest_guide/features/wallet/models/transaction_category.dart';

class WalletTransaction {
  final String id;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String? note;
  final TransactionType type;
  final RecurrenceType recurrence;
  final bool applyMonthly; // Her ay otomatik eklensin mi?
  final String? bankAccountId; // Banka hesabı için
  final DateTime? dueDate; // Ödeme vadesi
  final bool isPaid; // Ödendi mi?
  final DateTime? recurrenceEndDate; // Tekrarlama bitiş tarihi
  final bool isSubscription; // Bir abonelik mi? (Netflix, Spotify vb.)

  final String currencyCode; // Para birimi (TRY, USD, EUR vb.)

  // Duplicate önleme için
  final PaymentMethod paymentMethod; // Nakit, Kart, Banka Transferi
  final bool
      excludeFromBalance; // Bakiye hesaplamalarından hariç tut (fatura/abonelik hatırlatıcıları için)
  final String?
      linkedTransactionId; // Banka ekstresinden gelen işlem ile eşleşme

  final String? documentPath; // Ek döküman/makbuz yolu

  WalletTransaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note,
    required this.type,
    this.recurrence = RecurrenceType.none,
    this.applyMonthly = false,
    this.bankAccountId,
    this.dueDate,
    this.isPaid = false,
    this.recurrenceEndDate,
    this.isSubscription = false,
    this.currencyCode = 'TRY',
    this.paymentMethod = PaymentMethod.cash,
    this.excludeFromBalance = false,
    this.linkedTransactionId,
    this.documentPath,
  });

  TransactionCategory? get category => TransactionCategory.findById(categoryId);

  bool get isOverdue {
    if (dueDate == null || isPaid) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int get overdueDays {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate!).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'type': type.name,
      'recurrence': recurrence.name,
      'applyMonthly': applyMonthly,
      'bankAccountId': bankAccountId,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'isSubscription': isSubscription,
      'currencyCode': currencyCode,
      'paymentMethod': paymentMethod.name,
      'excludeFromBalance': excludeFromBalance,
      'linkedTransactionId': linkedTransactionId,
      'documentPath': documentPath,
    };
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      recurrence: json['recurrence'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.name == json['recurrence'],
              orElse: () => RecurrenceType.none,
            )
          : RecurrenceType.none,
      applyMonthly: json['applyMonthly'] as bool? ?? false,
      bankAccountId: json['bankAccountId'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isPaid: json['isPaid'] as bool? ?? false,
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      isSubscription: json['isSubscription'] as bool? ?? false,
      currencyCode: json['currencyCode'] as String? ?? 'TRY',
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : PaymentMethod.cash,
      excludeFromBalance: json['excludeFromBalance'] as bool? ?? false,
      linkedTransactionId: json['linkedTransactionId'] as String?,
      documentPath: json['documentPath'] as String?,
    );
  }

  WalletTransaction copyWith({
    String? id,
    String? categoryId,
    double? amount,
    DateTime? date,
    String? note,
    TransactionType? type,
    RecurrenceType? recurrence,
    bool? applyMonthly,
    String? bankAccountId,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? recurrenceEndDate,
    bool? isSubscription,
    String? currencyCode,
    PaymentMethod? paymentMethod,
    bool? excludeFromBalance,
    String? linkedTransactionId,
    String? documentPath,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
      recurrence: recurrence ?? this.recurrence,
      applyMonthly: applyMonthly ?? this.applyMonthly,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      isSubscription: isSubscription ?? this.isSubscription,
      currencyCode: currencyCode ?? this.currencyCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      excludeFromBalance: excludeFromBalance ?? this.excludeFromBalance,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      documentPath: documentPath ?? this.documentPath,
    );
  }
}

enum PaymentMethod {
  cash, // Nakit - Manuel eklenir, hesaba dahil
  creditCard, // Kredi Kartı - Ekstreden gelir, hesaba dahil
  debitCard, // Banka Kartı - Ekstreden gelir, hesaba dahil
  bankTransfer, // Banka Transferi - Ekstreden gelir, hesaba dahil
  autoPayment, // Otomatik Ödeme (Fatura/Abonelik) - Hatırlatıcı, hesaba dahil DEĞİL
}
