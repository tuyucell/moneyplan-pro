import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
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
        asOf: DateTime(2026, 8, 15),
      );

      expect(charges, hasLength(2));
      expect(charges[0].id, 'statement_interest_card-2_202608');
      expect(charges[0].amount, 48); // 1,200 x 4%
      expect(charges[1].id, 'statement_tax_card-2_202608');
      expect(charges[1].amount, 14.4); // 48 x (15% + 15%)
      expect(charges[0].dueDate, DateTime(2026, 8, 20));
    });

    test('does not create the same statement charge twice', () {
      final existing = WalletTransaction(
        id: 'statement_interest_card-2_202608',
        categoryId: 'bank_interest',
        amount: 40,
        date: DateTime(2026, 8, 10),
        type: TransactionType.expense,
        bankAccountId: account.id,
      );

      final charges = StatementChargeService.createDueCharges(
        account: account,
        transactions: [existing],
        asOf: DateTime(2026, 8, 15),
      );

      expect(charges, isEmpty);
    });

    test('an account opened on statement day starts next month', () {
      final justOpened = account.copyWith(createdAt: DateTime(2026, 8, 10));

      expect(
        StatementChargeService.createDueCharges(
          account: justOpened,
          transactions: const [],
          asOf: DateTime(2026, 8, 15),
        ),
        isEmpty,
      );

      final septemberCharges = StatementChargeService.createDueCharges(
        account: justOpened,
        transactions: const [],
        asOf: DateTime(2026, 9, 10),
      );
      expect(septemberCharges, hasLength(2));
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
}
