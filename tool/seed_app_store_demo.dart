import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

Map<String, dynamic> transaction({
  required String id,
  required String categoryId,
  required double amount,
  required String type,
  required DateTime date,
  required String note,
}) {
  return {
    'id': id,
    'categoryId': categoryId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'type': type,
    'recurrence': 'none',
    'applyMonthly': false,
    'bankAccountId': null,
    'dueDate': null,
    'isPaid': true,
    'recurrenceEndDate': null,
    'isSubscription': false,
    'currencyCode': 'TRY',
    'paymentMethod': 'cash',
    'excludeFromBalance': false,
    'linkedTransactionId': null,
    'documentPath': null,
  };
}

Future<void> main(List<String> args) async {
  if (args.length != 2 || args.first != '--documents') {
    stderr.writeln(
      'Usage: dart run tool/seed_app_store_demo.dart '
      '--documents <Simulator app Documents path>',
    );
    exitCode = 64;
    return;
  }

  final documents = Directory(args[1]).absolute;
  final normalizedPath = documents.path;
  if (!normalizedPath.contains('/CoreSimulator/Devices/') ||
      !normalizedPath.endsWith('/Documents') ||
      !documents.existsSync()) {
    stderr.writeln('Refusing to seed a non-Simulator Documents directory.');
    exitCode = 65;
    return;
  }

  Hive.init(normalizedPath);
  final box = await Hive.openBox<Map>('wallet_transactions_guest');
  await box.clear();

  final date = DateTime(2026, 7, 20, 9);
  final entries = <String, Map<String, dynamic>>{
    'store-demo-salary': transaction(
      id: 'store-demo-salary',
      categoryId: 'salary',
      amount: 75000,
      type: 'income',
      date: date,
      note: 'Aylık gelir',
    ),
    'store-demo-rent': transaction(
      id: 'store-demo-rent',
      categoryId: 'rent',
      amount: 25000,
      type: 'expense',
      date: date,
      note: 'Kira',
    ),
    'store-demo-bills': transaction(
      id: 'store-demo-bills',
      categoryId: 'bills',
      amount: 4500,
      type: 'expense',
      date: date,
      note: 'Aylık faturalar',
    ),
    'store-demo-transport': transaction(
      id: 'store-demo-transport',
      categoryId: 'transportation',
      amount: 3500,
      type: 'expense',
      date: date,
      note: 'Ulaşım',
    ),
    'store-demo-entertainment': transaction(
      id: 'store-demo-entertainment',
      categoryId: 'entertainment',
      amount: 3000,
      type: 'expense',
      date: date,
      note: 'Sosyal yaşam',
    ),
  };

  await box.putAll(entries);
  await box.close();
  await Hive.close();
  stdout.writeln('Seeded ${entries.length} fictional guest transactions.');
}
