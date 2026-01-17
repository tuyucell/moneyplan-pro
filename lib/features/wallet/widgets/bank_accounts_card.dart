import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import '../models/transaction_category.dart';
import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';
import '../providers/bank_account_provider.dart';
import '../../../../core/providers/balance_visibility_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../services/payment_service.dart';

import 'package:uuid/uuid.dart';

class BankAccountsCard extends ConsumerWidget {
  const BankAccountsCard({super.key});

  void _showAccountActions(
      BuildContext context, WidgetRef ref, BankAccount bank) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              bank.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              bank.accountType,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment, color: Colors.green),
              ),
              title: const Text('Borç Öde / Ödeme Yap',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Bekleyen ekstreleri veya borçları kapat'),
              onTap: () {
                Navigator.pop(context);
                _showPaymentDialog(context, ref, bank);
              },
            ),
            const Divider(height: 16, indent: 56),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.settings_outlined, color: Colors.indigo),
              ),
              title: const Text('Hesap Ayarları / Düzenle',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Limit, tarih ve isim ayarlarını güncelleyin'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, bank: bank);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, BankAccount bank) {
    debugPrint('🎬 _showPaymentDialog started');
    final allTransactions = ref.read(walletProvider);
    final unpaid = allTransactions
        .where((t) => t.bankAccountId == bank.id && !t.isPaid)
        .toList();

    unpaid.sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${bank.name} - Bekleyen Ödemeler'),
        content: unpaid.isEmpty
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 48),
                  SizedBox(height: 16),
                  Text('Bu hesap için bekleyen bir borç kaydı bulunamadı.',
                      textAlign: TextAlign.center),
                ],
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: unpaid.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final tx = unpaid[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tx.note ?? tx.category?.name ?? 'İşlem',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(tx.date),
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '${tx.amount.toStringAsFixed(2)} ${tx.currencyCode}',
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      onTap: () async {
                        // Capture the scaffold context before popping the bottom sheet
                        final scaffoldContext = context;
                        Navigator.pop(ctx);
                        // Use the scaffoldContext that remains mounted
                        await _showPaymentSourceDialog(
                            scaffoldContext, ref, tx, bank);
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('KAPAT')),
        ],
      ),
    );
  }

  Future<void> _showPaymentSourceDialog(BuildContext context, WidgetRef ref,
      WalletTransaction debtTransaction, BankAccount debtAccount) async {
    final allAccounts = ref.read(bankAccountProvider);
    final allTransactions = ref.read(walletProvider);

    // Use PaymentService to find suitable accounts
    final accountBalances = PaymentService.findPayableAccounts(
      debtAccount,
      allAccounts,
      allTransactions,
      debtTransaction.currencyCode,
    );

    if (accountBalances.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ödeme yapılabilecek ${debtTransaction.currencyCode} hesabı bulunamadı.\n\n'
              'Lütfen ${debtTransaction.currencyCode} vadesiz hesap ekleyin.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Track selection outside of builder to persist across rebuilds
    final selectedBalanceNotifier = ValueNotifier<AccountBalance?>(null);

    final result = await showDialog<AccountBalance>(
      context: context,
      builder: (ctx) => ValueListenableBuilder<AccountBalance?>(
        valueListenable: selectedBalanceNotifier,
        builder: (context, selectedBalance, _) {
          return AlertDialog(
            title: const Text('Hangi Hesaptan Ödeme Yapılacak?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ödenecek Tutar',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '${debtTransaction.amount.toStringAsFixed(2)} ${debtTransaction.currencyCode}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('HESAPLAR',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...accountBalances.map((balance) {
                    final canPay = balance.canPay(
                        debtTransaction.amount, debtTransaction.currencyCode);
                    final isBest = accountBalances.first == balance && canPay;
                    final isSelected = selectedBalance == balance;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 3 : (isBest ? 2 : 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blue
                              : isBest
                                  ? Colors.green
                                  : canPay
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                          width: isSelected ? 3 : (isBest ? 2 : 1),
                        ),
                      ),
                      color: isSelected ? Colors.blue.withOpacity(0.05) : null,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.grey,
                          size: 28,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(balance.account.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (isBest && !isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('ÖNERİLEN',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 9)),
                              ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('SEÇİLDİ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 9)),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(balance.account.accountType,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  canPay
                                      ? Icons.check_circle
                                      : Icons.warning_amber,
                                  size: 14,
                                  color: canPay ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Kullanılabilir: ${balance.availableBalance.toStringAsFixed(2)} ${balance.currency}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        canPay ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          selectedBalanceNotifier.value = balance;
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('İPTAL')),
              ElevatedButton(
                onPressed: selectedBalance == null
                    ? null
                    : () {
                        final currentSelection = selectedBalanceNotifier.value;
                        debugPrint(
                            '🟦 ONAYLA clicked with: ${currentSelection?.account.name}');
                        Navigator.of(ctx).pop(currentSelection);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('ONAYLA'),
              ),
            ],
          );
        },
      ),
    );

    debugPrint('🔍 Dialog closed. Result: $result');
    debugPrint('🔍 Context mounted after dialog: ${context.mounted}');

    if (result != null) {
      debugPrint(
          '🟢 Starting payment process for amount: ${debtTransaction.amount}');
      // We process the payment as long as we have a result.
      // The context check is mainly for showing snackbars, but the transaction logic should proceed.
      await _processPayment(context, ref, debtTransaction, debtAccount, result);
    } else {
      debugPrint('⚠️ Payment process skipped. Result is null.');
    }
  }

  Future<void> _processPayment(
    BuildContext context,
    WidgetRef ref,
    WalletTransaction debtTransaction,
    BankAccount debtAccount,
    AccountBalance selectedBalance,
  ) async {
    final allTransactions = ref.read(walletProvider);

    // Create payment request
    final paymentRequest = PaymentRequest(
      debtTransaction: debtTransaction,
      debtAccount: debtAccount,
      payingAccount: selectedBalance.account,
      paymentAmount: debtTransaction.amount,
    );

    // Validate through service
    final validationError =
        PaymentService.validatePayment(paymentRequest, allTransactions);

    if (validationError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validationError.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    try {
      // Create payment transaction through service
      final paymentTx = PaymentService.createPaymentTransaction(paymentRequest);

      debugPrint('🔵 Payment Transaction Created:');
      debugPrint('  - ID: ${paymentTx.id}');
      debugPrint('  - Amount: ${paymentTx.amount} ${paymentTx.currencyCode}');
      debugPrint(
          '  - From Account: ${selectedBalance.account.name} (${selectedBalance.account.id})');
      debugPrint('  - Linked to Debt: ${paymentTx.linkedTransactionId}');
      debugPrint('  - Category: ${paymentTx.categoryId}');
      debugPrint('  - isPaid: ${paymentTx.isPaid}');

      await ref.read(walletProvider.notifier).addTransaction(paymentTx);

      // Mark original debt as paid if full payment
      if (paymentRequest.isFullPayment) {
        debugPrint('🟢 Marking debt as paid: ${debtTransaction.id}');
        await ref
            .read(walletProvider.notifier)
            .markAsPaid(debtTransaction.id, true);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Ödeme Başarılı!\n\n'
              '${paymentRequest.paymentAmount.toStringAsFixed(2)} ${paymentRequest.currencyCode} '
              '${selectedBalance.account.name} hesabından ödendi.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, BankAccount bank) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: Text(
            '${bank.name} hesabını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
          TextButton(
            onPressed: () {
              ref.read(bankAccountProvider.notifier).deleteAccount(bank.id);
              Navigator.pop(ctx); // Close confirmation
              Navigator.pop(context); // Close edit dialog if open
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref,
      {BankAccount? bank, String? defaultType}) {
    final nameController = TextEditingController(text: bank?.name);
    final limitController = TextEditingController(
        text: bank?.overdraftLimit.toStringAsFixed(0) ?? '0');
    final dayController =
        TextEditingController(text: bank?.paymentDay.toString() ?? '1');
    final dueDayController =
        TextEditingController(text: bank?.dueDay.toString() ?? '10');
    final initialBalanceController = TextEditingController(
        text: bank?.initialBalance.toStringAsFixed(0) ?? '0');

    final type = bank?.accountType ?? defaultType ?? 'Vadesiz Hesap';
    final isCC = type == 'Kredi Kartı';
    var selectedCurrency = bank?.currencyCode ?? 'TRY';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(bank == null ? 'Yeni Hesap Ekle' : '${bank.name} Ayarları'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Banka / Hesap Adı',
                    hintText: 'Örn: Finansbank, Kuveyt Türk',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Para Birimi',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'TRY', child: Text('🇹🇷 TRY (Türk Lirası)')),
                    DropdownMenuItem(
                        value: 'USD', child: Text('🇺🇸 USD (Dolar)')),
                    DropdownMenuItem(
                        value: 'EUR', child: Text('🇪🇺 EUR (Euro)')),
                    DropdownMenuItem(
                        value: 'GBP', child: Text('🇬🇧 GBP (Sterlin)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCurrency = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                    labelText:
                        isCC ? 'Kredi Kartı Limiti' : 'KMH / Eksi Hesap Limiti',
                    suffixText: ref
                        .read(currencyServiceProvider)
                        .getSymbol(selectedCurrency),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dayController,
                  decoration: InputDecoration(
                    labelText: isCC
                        ? 'Hesap Kesim Günü (1-31)'
                        : 'Vade / Faiz Günü (1-31)',
                    hintText: 'Örn: 15',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (isCC) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: dueDayController,
                    decoration: const InputDecoration(
                      labelText: 'Son Ödeme Günü (1-31)',
                      hintText: 'Örn: 25',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: initialBalanceController,
                  decoration: InputDecoration(
                    labelText:
                        isCC ? 'Başlangıç Borcu (Ekstreden)' : 'Mevcut Bakiye',
                    hintText: isCC ? 'Örn: 35000' : 'Örn: 10000',
                    suffixText: ref
                        .read(currencyServiceProvider)
                        .getSymbol(selectedCurrency),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            if (bank != null)
              TextButton(
                onPressed: () => _showDeleteConfirmation(ctx, ref, bank),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('SİL'),
              ),
            const Spacer(),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İPTAL')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final limit = double.tryParse(limitController.text) ?? 0;
                final day = int.tryParse(dayController.text) ?? 1;
                final dueDay = int.tryParse(dueDayController.text) ?? 10;

                final notifier = ref.read(bankAccountProvider.notifier);

                if (bank != null) {
                  notifier.updateAccount(bank.copyWith(
                    name: name,
                    currencyCode: selectedCurrency,
                    overdraftLimit: limit,
                    paymentDay: day,
                    dueDay: dueDay,
                    initialBalance:
                        double.tryParse(initialBalanceController.text) ?? 0,
                  ));
                } else {
                  notifier.addAccount(BankAccount(
                    id: const Uuid().v4(),
                    name: name,
                    accountType: type,
                    currencyCode: selectedCurrency,
                    overdraftLimit: limit,
                    paymentDay: day,
                    dueDay: dueDay,
                    initialBalance:
                        double.tryParse(initialBalanceController.text) ?? 0,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: const Text('KAYDET'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(walletProvider);
    final accounts = ref.watch(bankAccountProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    // Calculate balances and costs per bank, grouped by currency
    final bankStats = <String, Map<String, dynamic>>{};

    // Initialize with initial balances
    for (final acc in accounts) {
      bankStats[acc.id] = {
        'balances': {
          acc.currencyCode: acc.initialBalance
        }, // Grouped by currency
        'interest': 0.0,
        'tax': 0.0
      };
    }

    for (final tx in transactions) {
      if (tx.bankAccountId != null) {
        final bankId = tx.bankAccountId!;
        if (!bankStats.containsKey(bankId)) {
          bankStats[bankId] = {
            'balances': <String, double>{},
            'interest': 0.0,
            'tax': 0.0
          };
        }

        final balances = bankStats[bankId]!['balances'] as Map<String, double>;
        final currency = tx.currencyCode.isEmpty ? 'TRY' : tx.currencyCode;

        if (!balances.containsKey(currency)) {
          balances[currency] = 0.0;
        }

        // Logic check:
        // isUnpaidDebt: A regular expense tagged with CC/KMH category that hasn't been paid yet.
        // isPaidDebt: The same expense, but now marked as paid (isPaid: true).
        // PaymentTx: A transaction with linkedTransactionId pointing to the original debt.

        final isUnpaidDebt = !tx.isPaid &&
            tx.type == TransactionType.expense &&
            tx.categoryId == 'bank_credit_card';

        final isPaidDebt = tx.isPaid &&
            tx.type == TransactionType.expense &&
            tx.categoryId == 'bank_credit_card' &&
            tx.linkedTransactionId == null; // Original debt record

        if (isUnpaidDebt) {
          // Reduces available balance (credit)
          balances[currency] = balances[currency]! - tx.amount;
          debugPrint(
              '🟢 Calc [Unpaid Debt]: ${tx.amount} $currency on $bankId -> New Bal: ${balances[currency]} (ID: ${tx.id})');
        } else if (!isPaidDebt) {
          // Regular transactions or PAYMENT transactions (linked)
          final amount =
              tx.type == TransactionType.income ? tx.amount : -tx.amount;
          balances[currency] = balances[currency]! + amount;
          if (tx.linkedTransactionId != null) {
            debugPrint(
                '🔵 Calc [Payment Tx]: ${tx.amount} $currency on $bankId -> New Bal: ${balances[currency]} (Linked: ${tx.linkedTransactionId})');
          } else {
            // debugPrint('⚪ Calc [Regular]: ${tx.amount} $currency on $bankId -> New Bal: ${balances[currency]}');
          }
        } else {
          // Paid original debts are skipped
          debugPrint(
              '� Calc [Skipped Paid Debt]: ${tx.amount} $currency on $bankId (ID: ${tx.id})');
        }

        if (tx.categoryId == 'bank_interest') {
          bankStats[bankId]!['interest'] =
              bankStats[bankId]!['interest']! + tx.amount;
        } else if (tx.categoryId == 'bank_tax') {
          bankStats[bankId]!['tax'] = bankStats[bankId]!['tax']! + tx.amount;
        }
      }
    }

    final checkingAccounts = accounts
        .where((a) => a.accountType == 'Vadesiz Hesap' && a.isActive)
        .toList();
    final creditCards = accounts
        .where((a) => a.accountType == 'Kredi Kartı' && a.isActive)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccordionGroup(
          context,
          ref,
          'VADESİZ HESAPLARIM',
          Icons.account_balance_wallet,
          checkingAccounts,
          bankStats,
          currencyService,
          isVisible,
        ),
        const SizedBox(height: 12),
        _buildAccordionGroup(
          context,
          ref,
          'KREDİ KARTLARIM',
          Icons.credit_card,
          creditCards,
          bankStats,
          currencyService,
          isVisible,
        ),
      ],
    );
  }

  Widget _buildAccordionGroup(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    List<BankAccount> accounts,
    Map<String, Map<String, dynamic>> bankStats,
    CurrencyService currencyService,
    bool isVisible,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          leading: Icon(icon, color: Colors.indigo),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.indigo,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.indigo, size: 22),
                onPressed: () => _showEditDialog(
                  context,
                  ref,
                  defaultType: title == 'VADESİZ HESAPLARIM'
                      ? 'Vadesiz Hesap'
                      : 'Kredi Kartı',
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.indigo),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: accounts.map((bank) {
                  return _buildBankItem(
                    context,
                    ref,
                    bank,
                    bankStats,
                    currencyService,
                    isVisible,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(
    BuildContext context,
    WidgetRef ref,
    BankAccount bank,
    Map<String, Map<String, dynamic>> bankStats,
    CurrencyService currencyService,
    bool isVisible,
  ) {
    final stats = bankStats[bank.id] ??
        {
          'balances': <String, double>{bank.currencyCode: 0.0},
          'interest': 0.0,
          'tax': 0.0
        };
    final balances = stats['balances'] as Map<String, double>;
    final interest = stats['interest'] as double;
    final tax = stats['tax'] as double;

    final isCC = bank.accountType == 'Kredi Kartı';
    final mainCurrencyFormat = NumberFormat.currency(
        locale: bank.currencyCode == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: currencyService.getSymbol(bank.currencyCode),
        decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAccountActions(context, ref, bank),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black.withValues(alpha: 0.03)
                    : Colors.transparent,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCC
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCC ? Icons.credit_card : Icons.account_balance,
                      color: isCC ? Colors.indigo : Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          bank.accountType,
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              // Multi-currency balances
              ...balances.entries.map((entry) {
                final currencyCode = entry.key;
                final balance = entry.value;
                final symbol = currencyService.getSymbol(currencyCode);
                final format = NumberFormat.currency(
                    locale: currencyCode == 'TRY' ? 'tr_TR' : 'en_US',
                    symbol: symbol,
                    decimalDigits: 2);

                final isNegative = balance < 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyCode == bank.currencyCode
                            ? 'Mevcut Bakiye'
                            : '$currencyCode Borç / Bakiye',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        isVisible ? format.format(balance) : '••••••',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (isCC && balance < 0) || (!isCC && isNegative)
                              ? Colors.red
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (bank.overdraftLimit > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isCC ? 'Kart' : 'KMH'} Limiti: ${mainCurrencyFormat.format(bank.overdraftLimit)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Builder(builder: (context) {
                      // Total balance converted to account's main currency
                      double totalBalanceInMainCurrency = 0.0;
                      debugPrint(
                          '📊 --- Calculating Total Limit for ${bank.name} ---');

                      balances.forEach((currency, amount) {
                        double amountInMain;
                        if (currency == bank.currencyCode) {
                          amountInMain = amount;
                        } else {
                          // Convert to TRY first, then to main currency if main is not TRY
                          final amountInTRY =
                              currencyService.convertToTRY(amount, currency);
                          if (bank.currencyCode == 'TRY') {
                            amountInMain = amountInTRY;
                          } else {
                            // Card is USD, amount is TRY/EUR etc.
                            amountInMain = currencyService.convertFromTRY(
                                amountInTRY, bank.currencyCode);
                          }
                        }
                        totalBalanceInMainCurrency += amountInMain;
                        if (amount != 0) {
                          debugPrint(
                              '   - $amount $currency -> $amountInMain ${bank.currencyCode}');
                        }
                      });

                      final remaining =
                          bank.overdraftLimit + totalBalanceInMainCurrency;
                      debugPrint(
                          '   = Result: Limit ${bank.overdraftLimit} + TotalBal $totalBalanceInMainCurrency = $remaining ${bank.currencyCode}');

                      return Text(
                        'Kalan: ${isVisible ? mainCurrencyFormat.format(remaining) : '••••'}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  // Re-calculate total balance for progress indicator
                  double totalBalanceInMainCurrency = 0.0;
                  balances.forEach((currency, amount) {
                    if (currency == bank.currencyCode) {
                      totalBalanceInMainCurrency += amount;
                    } else {
                      final amountInTRY =
                          currencyService.convertToTRY(amount, currency);
                      if (bank.currencyCode == 'TRY') {
                        totalBalanceInMainCurrency += amountInTRY;
                      } else {
                        totalBalanceInMainCurrency += currencyService
                            .convertFromTRY(amountInTRY, bank.currencyCode);
                      }
                    }
                  });

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalBalanceInMainCurrency < 0
                          ? (totalBalanceInMainCurrency.abs() /
                                  bank.overdraftLimit)
                              .clamp(0, 1)
                          : 0,
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalBalanceInMainCurrency < 0
                            ? (isCC ? Colors.indigo : Colors.orange)
                            : Colors.green,
                      ),
                      minHeight: 4,
                    ),
                  );
                }),
              ],
              if (interest > 0 || tax > 0) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostItem(context, 'Faiz Maliyeti', interest,
                        mainCurrencyFormat, isVisible),
                    _buildCostItem(context, 'Vergi (BSMV/KKDF)', tax,
                        mainCurrencyFormat, isVisible),
                    _buildCostItem(context, 'Toplam Masraf', interest + tax,
                        mainCurrencyFormat, isVisible,
                        isTotal: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostItem(BuildContext context, String label, double amount,
      NumberFormat format, bool isVisible,
      {bool isTotal = false}) {
    return Column(
      crossAxisAlignment:
          isTotal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          isVisible ? format.format(amount) : '••••••',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? Colors.red.shade700
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
