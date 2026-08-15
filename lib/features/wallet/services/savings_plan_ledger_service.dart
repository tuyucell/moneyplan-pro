import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';

class SavingsPlanLedgerService {
  const SavingsPlanLedgerService._();

  static Future<void> sync({
    required SavingsGoal plan,
    required WalletNotifier wallet,
    required List<WalletTransaction> transactions,
    required List<BankAccount> accounts,
  }) async {
    WalletTransaction? existingSource;
    for (final transaction in transactions) {
      if (transaction.id == plan.ledgerSourceId) {
        existingSource = transaction;
        break;
      }
    }
    final hasSource = existingSource != null;
    final now = DateTime.now();
    final end = plan.contractEndDate;
    final contractActive = end == null ||
        !DateTime(end.year, end.month).isBefore(DateTime(now.year, now.month));
    final shouldCreate = contractActive &&
        plan.automaticPayment &&
        plan.createWalletExpense &&
        plan.periodicContribution > 0;

    if (!shouldCreate) {
      if (hasSource) await wallet.deleteTransaction(plan.ledgerSourceId);
      return;
    }

    BankAccount? account;
    for (final candidate in accounts) {
      if (candidate.id == plan.paymentAccountId) {
        account = candidate;
        break;
      }
    }

    final start = plan.contractStartDate ?? DateTime.now();
    final sourceMonth = existingSource?.date ??
        (DateTime(start.year, start.month)
                .isBefore(DateTime(now.year, now.month))
            ? now
            : start);
    final firstPayment = DateTime(
      sourceMonth.year,
      sourceMonth.month,
      plan.paymentDay.clamp(1, 28),
    );

    final transaction = WalletTransaction(
      id: plan.ledgerSourceId,
      categoryId: switch (plan.planType) {
        SavingsPlanType.bes => 'bes',
        SavingsPlanType.lifeInsurance => 'insurance_life',
        SavingsPlanType.savings => 'savings',
        SavingsPlanType.savingsFinance => 'savings_finance_principal',
      },
      // Keep the contract nominal (for example 100 USD) instead of freezing
      // today's TRY equivalent. Monthly summaries convert it using the rate
      // service for the viewed period.
      amount: plan.periodicContribution,
      date: firstPayment,
      dueDate: firstPayment,
      note: '${plan.name} düzenli ödeme',
      type: TransactionType.expense,
      recurrence: switch (plan.contributionPeriod) {
        ContributionPeriod.monthly => RecurrenceType.monthly,
        ContributionPeriod.quarterly => RecurrenceType.quarterly,
        ContributionPeriod.semiAnnual => RecurrenceType.semiAnnual,
        ContributionPeriod.yearly => RecurrenceType.yearly,
      },
      recurrenceEndDate: plan.contractEndDate,
      bankAccountId: account?.id,
      currencyCode: plan.currencyCode,
      paymentMethod: switch (plan.fundingMethod) {
        SavingsFundingMethod.creditCard => PaymentMethod.creditCard,
        SavingsFundingMethod.cash =>
          account == null ? PaymentMethod.cash : PaymentMethod.bankTransfer,
      },
      linkedTransactionId: 'savings-plan:${plan.id}',
    );

    if (hasSource) {
      await wallet.updateTransaction(transaction);
    } else {
      await wallet.addTransaction(transaction);
    }
  }
}
