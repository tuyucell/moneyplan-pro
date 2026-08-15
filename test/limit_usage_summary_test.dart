import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/limit_usage_summary.dart';

void main() {
  double identity(double amount, String _) => amount;

  test('separates credit-card and overdraft limits and usage', () {
    final accounts = [
      const BankAccount(
        id: 'cash',
        name: 'KMH',
        accountType: 'Vadesiz Hesap',
        overdraftLimit: 100000,
      ),
      const BankAccount(
        id: 'card',
        name: 'Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 80000,
      ),
    ];

    final summary = LimitUsageSummary.fromAccounts(
      accounts: accounts,
      balancesInBaseCurrency: const {
        'cash': -64000,
        'card': -10000,
      },
      pendingInstallmentsInBaseCurrency: const {'card': 40000},
      convertToBaseCurrency: identity,
    );

    expect(summary.overdrafts.limit, 100000);
    expect(summary.overdrafts.used, 64000);
    expect(summary.overdrafts.remaining, 36000);
    expect(summary.creditCards.limit, 80000);
    expect(summary.creditCards.used, 50000);
    expect(summary.creditCards.remaining, 30000);
    expect(summary.total.limit, 180000);
    expect(summary.total.used, 114000);
  });

  test('keeps configured limits while reset balances show zero usage', () {
    const accounts = DefaultBankAccounts.accounts;
    final summary = LimitUsageSummary.fromAccounts(
      accounts: accounts,
      balancesInBaseCurrency: {
        for (final account in accounts) account.id: 0,
      },
      pendingInstallmentsInBaseCurrency: const {},
      convertToBaseCurrency: identity,
    );

    expect(summary.overdrafts.limit, 100000);
    expect(summary.creditCards.limit, 450000);
    expect(summary.total.used, 0);
    expect(summary.total.remaining, 550000);
  });

  test('ignores inactive accounts and reports over-limit usage safely', () {
    final accounts = [
      const BankAccount(
        id: 'active',
        name: 'Aktif Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 10000,
      ),
      const BankAccount(
        id: 'inactive',
        name: 'Kapalı Kart',
        accountType: 'Kredi Kartı',
        overdraftLimit: 50000,
        isActive: false,
      ),
    ];

    final summary = LimitUsageSummary.fromAccounts(
      accounts: accounts,
      balancesInBaseCurrency: const {
        'active': -12000,
        'inactive': -50000,
      },
      pendingInstallmentsInBaseCurrency: const {},
      convertToBaseCurrency: identity,
    );

    expect(summary.creditCards.limit, 10000);
    expect(summary.creditCards.used, 12000);
    expect(summary.creditCards.remaining, 0);
    expect(summary.creditCards.isOverLimit, isTrue);
    expect(summary.creditCards.utilizationRate, 1.2);
  });
}
