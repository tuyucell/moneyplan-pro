import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/monthly_summary.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/services/installment_schedule_service.dart';
import 'package:moneyplan_pro/features/wallet/services/payment_service.dart';
import 'package:moneyplan_pro/features/wallet/services/statement_charge_service.dart';
import 'package:moneyplan_pro/features/wallet/widgets/bank_account_editor_dialog.dart';

void main() {
  group('Statement charge calculation', () {
    const account = BankAccount(
      id: 'card-1',
      name: 'Test Kart',
      accountType: 'Kredi Kartı',
      initialBalance: -1000,
      overdraftInterestRate: 4,
      bsmvRate: 15,
      kkdfRate: 15,
      paymentDay: 10,
      dueDay: 20,
    );

    test('negative balance produces monthly interest, BSMV and KKDF', () {
      final result = account.calculateStatementCharges(-1000);

      expect(result.debt, 1000);
      expect(result.interest, 40);
      expect(result.bsmv, 6);
      expect(result.kkdf, 6);
      expect(result.total, 52);
    });

    test('positive balance does not produce a charge', () {
      expect(account.calculateStatementCharges(100).total, 0);
    });

    test('daily overdue calculation derives from the monthly rate', () {
      expect(account.calculateInterest(3000, 10), closeTo(40, 0.001));
    });
  });

  group('StatementChargeService', () {
    final account = BankAccount(
      id: 'card-2',
      name: 'Borç Kartı',
      accountType: 'Kredi Kartı',
      initialBalance: -1000,
      overdraftInterestRate: 4,
      bsmvRate: 15,
      kkdfRate: 15,
      paymentDay: 10,
      dueDay: 20,
      dueDaysAfterStatement: 10,
      createdAt: DateTime(2026, 8, 1),
    );

    test('uses the balance at statement date and creates two ledger entries',
        () {
      final charges = StatementChargeService.createDueCharges(
        account: account,
        transactions: [
          WalletTransaction(
            id: 'purchase',
            categoryId: 'bank_credit_card',
            amount: 500,
            date: DateTime(2026, 8, 5),
            type: TransactionType.expense,
            bankAccountId: account.id,
          ),
          WalletTransaction(
            id: 'payment',
            categoryId: 'transfer_deposit',
            amount: 300,
            date: DateTime(2026, 8, 8),
            type: TransactionType.income,
            bankAccountId: account.id,
          ),
          WalletTransaction(
            id: 'after-statement',
            categoryId: 'bank_credit_card',
            amount: 900,
            date: DateTime(2026, 8, 12),
            type: TransactionType.expense,
            bankAccountId: account.id,
          ),
        ],
        asOf: DateTime(2026, 8, 21),
      );

      expect(charges, hasLength(2));
      expect(charges[0].id, 'statement_interest_card-2_202608');
      expect(charges[0].amount, 48); // 1,200 x 4%
      expect(charges[1].id, 'statement_tax_card-2_202608');
      expect(charges[1].amount, 14.4); // 48 x (15% + 15%)
      expect(charges[0].dueDate, DateTime(2026, 8, 20));
      expect(charges[0].date, DateTime(2026, 8, 21));
    });

    test('does not create the same statement charge twice', () {
      final existing = StatementChargeService.createDueCharges(
        account: account,
        transactions: const [],
        asOf: DateTime(2026, 8, 21),
      );

      final charges = StatementChargeService.createDueCharges(
        account: account,
        transactions: existing,
        asOf: DateTime(2026, 8, 21),
      );

      expect(charges, isEmpty);
    });

    test('an account opened on statement day starts next month', () {
      final justOpened = account.copyWith(createdAt: DateTime(2026, 8, 10));

      expect(
        StatementChargeService.createDueCharges(
          account: justOpened,
          transactions: const [],
          asOf: DateTime(2026, 8, 31),
        ),
        isEmpty,
      );

      final septemberCharges = StatementChargeService.createDueCharges(
        account: justOpened,
        transactions: const [],
        asOf: DateTime(2026, 9, 21),
      );
      expect(septemberCharges, hasLength(2));
    });

    test('uses a day offset so month length changes the calendar due day', () {
      final dynamicCard = account.copyWith(
        paymentDay: 25,
        dueDaysAfterStatement: 10,
      );

      expect(
        dynamicCard.dueDateForStatement(DateTime(2026, 8, 25)),
        DateTime(2026, 9, 4),
      );
      expect(
        dynamicCard.dueDateForStatement(DateTime(2026, 9, 25)),
        DateTime(2026, 10, 5),
      );
    });

    test('a balance entered on the 15th gets no interest before its due date',
        () {
      final newSnapshot = account.copyWith(
        initialBalance: -10000,
        paymentDay: 25,
        dueDaysAfterStatement: 10,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );

      for (final asOf in [
        DateTime(2026, 8, 15),
        DateTime(2026, 8, 25),
        DateTime(2026, 9, 4),
      ]) {
        expect(
          StatementChargeService.createDueCharges(
            account: newSnapshot,
            transactions: const [],
            asOf: asOf,
          ),
          isEmpty,
        );
      }

      final afterDue = StatementChargeService.createDueCharges(
        account: newSnapshot,
        transactions: const [],
        asOf: DateTime(2026, 9, 5),
      );
      expect(afterDue, hasLength(2));
      expect(afterDue.first.date, DateTime(2026, 9, 5));
    });

    test('payment by the due date prevents interest', () {
      final newSnapshot = account.copyWith(
        initialBalance: -10000,
        paymentDay: 25,
        dueDaysAfterStatement: 10,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );
      final payment = WalletTransaction(
        id: 'full-payment',
        categoryId: 'transfer_deposit',
        amount: 10000,
        date: DateTime(2026, 9, 4),
        type: TransactionType.income,
        bankAccountId: newSnapshot.id,
      );

      expect(
        StatementChargeService.createDueCharges(
          account: newSnapshot,
          transactions: [payment],
          asOf: DateTime(2026, 9, 5),
        ),
        isEmpty,
      );
    });

    test('reconciliation removes stale automatic interest after a reset', () {
      final resetSnapshot = account.copyWith(
        initialBalance: 0,
        paymentDay: 25,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );
      final stale = WalletTransaction(
        id: 'statement_interest_card-2_202608',
        categoryId: 'bank_interest',
        amount: 224,
        date: DateTime(2026, 8, 10),
        type: TransactionType.expense,
        bankAccountId: resetSnapshot.id,
      );

      final plan = StatementChargeService.buildPlan(
        account: resetSnapshot,
        transactions: [stale],
        asOf: DateTime(2026, 8, 20),
      );

      expect(plan.upserts, isEmpty);
      expect(plan.removals, [stale.id]);
    });
  });

  group('Credit card installment schedule', () {
    final account = BankAccount(
      id: 'installment-card',
      name: 'Taksit Kartı',
      accountType: 'Kredi Kartı',
      initialBalance: -10000,
      overdraftLimit: 75000,
      overdraftInterestRate: 4,
      paymentDay: 10,
      dueDay: 20,
      dueDaysAfterStatement: 10,
      createdAt: DateTime(2026, 8, 10),
      installmentPlan: [
        for (var month = 9; month <= 12; month++)
          CreditCardInstallmentEntry(
            id: 'installment-$month',
            statementMonth: DateTime(2026, month),
            amount: 10000,
          ),
      ],
    );

    test('stores current debt separately from future installment commitment',
        () {
      final restored = BankAccount.fromJson(account.toJson());

      expect(restored.initialBalance, -10000);
      expect(restored.installmentPlan, hasLength(4));
      expect(restored.installmentPlanTotal, 40000);
      expect(-restored.initialBalance + restored.installmentPlanTotal, 50000);
    });

    test('opening debt is an expense in its opening month without double count',
        () {
      final transactions = InstallmentScheduleService.createDueTransactions(
        account: account,
        transactions: const [],
        asOf: DateTime(2026, 8, 15),
      );

      expect(transactions, hasLength(1));
      expect(transactions.single.amount, 10000);
      expect(transactions.single.excludeFromBalance, isTrue);
      expect(transactions.single.isPaid, isTrue);

      final summary = MonthlySummary.fromTransactions(
        transactions,
        2026,
        8,
        bankAccountList: [account],
      );
      expect(summary.totalExpense, 10000);
      expect(summary.cashExpense, 0);
    });

    test('each installment becomes debt only in its own statement month', () {
      final augustTransactions =
          InstallmentScheduleService.createDueTransactions(
        account: account,
        transactions: const [],
        asOf: DateTime(2026, 8, 31),
      );
      expect(augustTransactions, hasLength(1));
      expect(
        InstallmentScheduleService.pendingTotal(
          account: account,
          transactions: augustTransactions,
        ),
        40000,
      );

      final septemberTransactions =
          InstallmentScheduleService.createDueTransactions(
        account: account,
        transactions: augustTransactions,
        asOf: DateTime(2026, 9, 10),
      );
      expect(septemberTransactions, hasLength(1));
      expect(septemberTransactions.single.amount, 10000);
      expect(septemberTransactions.single.date, DateTime(2026, 9, 10));
      expect(septemberTransactions.single.dueDate, DateTime(2026, 9, 20));
      expect(septemberTransactions.single.isPaid, isFalse);
      expect(
        InstallmentScheduleService.pendingTotal(
          account: account,
          transactions: [
            ...augustTransactions,
            ...septemberTransactions,
          ],
        ),
        30000,
      );
    });

    test('statement interest includes the installment that became due', () {
      final scheduled = InstallmentScheduleService.createDueTransactions(
        account: account,
        transactions: const [],
        asOf: DateTime(2026, 9, 10),
      );
      final charges = StatementChargeService.createDueCharges(
        account: account,
        transactions: scheduled,
        asOf: DateTime(2026, 9, 21),
      );

      expect(charges, hasLength(2));
      expect(charges.first.amount, 800); // 20.000 x %4
    });
  });

  group('Account snapshot persistence', () {
    test('transactions before a new balance snapshot do not change it', () {
      final account = BankAccount(
        id: 'snapshot-card',
        name: 'Güncel Kart',
        accountType: 'Kredi Kartı',
        initialBalance: -10000,
        balanceEffectiveDate: DateTime(2026, 8, 15),
      );
      final staleInterest = WalletTransaction(
        id: 'old-interest',
        categoryId: 'bank_interest',
        amount: 224,
        date: DateTime(2026, 8, 10),
        type: TransactionType.expense,
        bankAccountId: account.id,
      );

      final result = PaymentService.calculateAccountBalance(
        account,
        [staleInterest],
      );
      expect(result.balance, -10000);
    });

    test('legacy local customizations win over an older remote default row',
        () {
      const local = BankAccount(
        id: 'card',
        name: 'Benim Kartım',
        accountType: 'Kredi Kartı',
        overdraftLimit: 98765,
      );
      final remote = local.copyWith(
        name: 'Varsayılan Kart',
        overdraftLimit: 1000,
        updatedAt: DateTime(2026, 8, 15),
      );

      final merged = mergeBankAccountSnapshots(
        local: const [local],
        remote: [remote],
        hasLocalSnapshot: true,
        defaults: DefaultBankAccounts.accounts,
      );

      expect(merged.single.name, 'Benim Kartım');
      expect(merged.single.overdraftLimit, 98765);
    });

    test('deleted default accounts are not recreated', () {
      final merged = mergeBankAccountSnapshots(
        local: const [],
        remote: const [],
        hasLocalSnapshot: false,
        defaults: DefaultBankAccounts.accounts,
        deletedIds: const {'isbank_cc'},
      );

      expect(merged.any((account) => account.id == 'isbank_cc'), isFalse);
    });
  });

  testWidgets('card editor accepts a signed negative starting balance',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BankAccountEditorDialog(defaultType: 'Kredi Kartı'),
          ),
        ),
      ),
    );

    expect(find.text('Aylık Kart Faizi (%)'), findsOneWidget);
    expect(find.text('BSMV (%)'), findsOneWidget);
    expect(find.text('KKDF (%)'), findsOneWidget);

    final balanceFinder =
        find.byKey(const ValueKey('bank_account_initial_balance'));
    await tester.ensureVisible(balanceFinder);
    await tester.enterText(balanceFinder, '-12500');

    final field = tester.widget<TextFormField>(balanceFinder);
    expect(field.controller!.text, '-12500');
    final editable = tester.widget<EditableText>(
      find.descendant(of: balanceFinder, matching: find.byType(EditableText)),
    );
    expect(editable.keyboardType.signed, isTrue);
  });

  testWidgets('card editor exposes future installments and ignores barrier tap',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showBankAccountEditorDialog(
                  context,
                  defaultType: 'Kredi Kartı',
                ),
                child: const Text('AÇ'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('AÇ'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Kart Ekle'), findsOneWidget);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Kart Ekle'), findsOneWidget);

    final toggle = find.byKey(
      const ValueKey('credit_card_has_installments'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add_installment_month')), findsOneWidget);
    expect(find.text('Gelecek: 0 ₺'), findsOneWidget);
  });
}
