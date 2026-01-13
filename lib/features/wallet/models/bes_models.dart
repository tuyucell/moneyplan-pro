class BesFund {
  final String code;
  final String name;
  final double currentPrice;
  final double? dailyChange;

  BesFund({
    required this.code,
    required this.name,
    required this.currentPrice,
    this.dailyChange,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'currentPrice': currentPrice,
        'dailyChange': dailyChange,
      };

  factory BesFund.fromJson(Map<String, dynamic> json) => BesFund(
        code: json['code'],
        name: json['name'],
        currentPrice: (json['currentPrice'] as num).toDouble(),
        dailyChange: (json['dailyChange'] as num?)?.toDouble(),
      );
}

class BesAsset {
  final String fundCode;
  final double units;
  final double averageCost;
  final DateTime lastUpdated;

  BesAsset({
    required this.fundCode,
    required this.units,
    required this.averageCost,
    required this.lastUpdated,
  });

  double getCurrentValue(double currentPrice) => units * currentPrice;
  double getProfit(double currentPrice) =>
      getCurrentValue(currentPrice) - (units * averageCost);
  double getProfitPercentage(double currentPrice) =>
      averageCost > 0 ? (currentPrice - averageCost) / averageCost * 100 : 0;

  Map<String, dynamic> toJson() => {
        'fundCode': fundCode,
        'units': units,
        'averageCost': averageCost,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory BesAsset.fromJson(Map<String, dynamic> json) => BesAsset(
        fundCode: json['fundCode'],
        units: (json['units'] as num).toDouble(),
        averageCost: (json['averageCost'] as num).toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
      );
}

class BesTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'contribution', 'withdrawal', 'distribution'
  final String? fundCode;
  final String? description;

  BesTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    this.fundCode,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type,
        'fundCode': fundCode,
        'description': description,
      };

  factory BesTransaction.fromJson(Map<String, dynamic> json) => BesTransaction(
        id: json['id'],
        date: DateTime.parse(json['date']),
        amount: (json['amount'] as num).toDouble(),
        type: json['type'],
        fundCode: json['fundCode'],
        description: json['description'],
      );
}

class BesAccount {
  final List<BesAsset> assets;
  final List<BesTransaction> transactions;
  final double governmentContribution; // Current balance of state contribution
  final DateTime lastDataUpdate;

  BesAccount({
    required this.assets,
    required this.transactions,
    required this.governmentContribution,
    required this.lastDataUpdate,
  });

  double getTotalValue([Map<String, double> fundPrices = const {}]) {
    var total = assets.fold(0.0, (sum, asset) {
      final price = fundPrices[asset.fundCode] ?? asset.averageCost;
      return sum + asset.getCurrentValue(price);
    });
    return total + governmentContribution;
  }

  Map<String, dynamic> toJson() => {
        'assets': assets.map((a) => a.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'governmentContribution': governmentContribution,
        'lastDataUpdate': lastDataUpdate.toIso8601String(),
      };

  factory BesAccount.fromJson(Map<String, dynamic> json) => BesAccount(
        assets: (json['assets'] as List)
            .map((a) => BesAsset.fromJson(Map<String, dynamic>.from(a)))
            .toList(),
        transactions: (json['transactions'] as List)
            .map((t) => BesTransaction.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        governmentContribution:
            (json['governmentContribution'] as num).toDouble(),
        lastDataUpdate: DateTime.parse(json['lastDataUpdate']),
      );
}
