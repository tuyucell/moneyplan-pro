import 'bank_account.dart';

class LimitUsageBucket {
  final double limit;
  final double used;

  const LimitUsageBucket({
    required this.limit,
    required this.used,
  });

  double get remaining => (limit - used).clamp(0, double.infinity).toDouble();

  double get utilizationRate {
    if (limit <= 0) return used > 0 ? 1 : 0;
    return used / limit;
  }

  bool get isOverLimit => used > limit;
}

class LimitUsageSummary {
  final LimitUsageBucket creditCards;
  final LimitUsageBucket overdrafts;

  const LimitUsageSummary({
    required this.creditCards,
    required this.overdrafts,
  });

  LimitUsageBucket get total => LimitUsageBucket(
        limit: creditCards.limit + overdrafts.limit,
        used: creditCards.used + overdrafts.used,
      );

  bool get hasData => total.limit > 0 || total.used > 0;

  factory LimitUsageSummary.fromAccounts({
    required List<BankAccount> accounts,
    required Map<String, double> balancesInBaseCurrency,
    required Map<String, double> pendingInstallmentsInBaseCurrency,
    required double Function(double amount, String currencyCode)
        convertToBaseCurrency,
  }) {
    var creditCardLimit = 0.0;
    var creditCardUsed = 0.0;
    var overdraftLimit = 0.0;
    var overdraftUsed = 0.0;

    for (final account in accounts.where((account) => account.isActive)) {
      final convertedLimit = convertToBaseCurrency(
        account.overdraftLimit > 0 ? account.overdraftLimit : 0,
        account.currencyCode,
      );
      final balance = balancesInBaseCurrency[account.id] ?? 0;
      final currentDebt = balance < 0 ? -balance : 0.0;

      if (account.accountType == 'Kredi Kartı') {
        creditCardLimit += convertedLimit;
        creditCardUsed +=
            currentDebt + (pendingInstallmentsInBaseCurrency[account.id] ?? 0);
      } else {
        overdraftLimit += convertedLimit;
        overdraftUsed += currentDebt;
      }
    }

    return LimitUsageSummary(
      creditCards: LimitUsageBucket(
        limit: creditCardLimit,
        used: creditCardUsed,
      ),
      overdrafts: LimitUsageBucket(
        limit: overdraftLimit,
        used: overdraftUsed,
      ),
    );
  }
}
