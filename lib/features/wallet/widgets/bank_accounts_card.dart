import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import '../models/transaction_category.dart';
import '../providers/wallet_provider.dart';
import '../providers/bank_account_provider.dart';
import '../../../../core/providers/balance_visibility_provider.dart';
import '../../../../core/services/currency_service.dart';

import 'package:uuid/uuid.dart';

class BankAccountsCard extends ConsumerWidget {
  const BankAccountsCard({super.key});

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

    final type = bank?.accountType ?? defaultType ?? 'Vadesiz Hesap';
    final isCC = type == 'Kredi Kartı';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(bank == null ? 'Yeni Hesap Ekle' : '${bank.name} Ayarları'),
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
              TextField(
                controller: limitController,
                decoration: InputDecoration(
                  labelText:
                      isCC ? 'Kredi Kartı Limiti' : 'KMH / Eksi Hesap Limiti',
                  suffixText: ref
                      .read(currencyServiceProvider)
                      .getSymbol(bank?.currencyCode ?? 'TRY'),
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
              onPressed: () => Navigator.pop(ctx), child: const Text('İPTAL')),
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
                    overdraftLimit: limit,
                    paymentDay: day,
                    dueDay: dueDay));
              } else {
                notifier.addAccount(BankAccount(
                  id: const Uuid().v4(),
                  name: name,
                  accountType: type,
                  overdraftLimit: limit,
                  paymentDay: day,
                  dueDay: dueDay,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('KAYDET'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(walletProvider);
    final accounts = ref.watch(bankAccountProvider);
    final isVisible = ref.watch(balanceVisibilityProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    // Calculate balances and costs per bank
    final bankStats = <String, Map<String, double>>{};
    for (final tx in transactions) {
      if (tx.bankAccountId != null) {
        final bankId = tx.bankAccountId!;
        if (!bankStats.containsKey(bankId)) {
          bankStats[bankId] = {'balance': 0.0, 'interest': 0.0, 'tax': 0.0};
        }

        final amount =
            tx.type == TransactionType.income ? tx.amount : -tx.amount;
        bankStats[bankId]!['balance'] = bankStats[bankId]!['balance']! + amount;

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
        if (checkingAccounts.isNotEmpty)
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
        if (creditCards.isNotEmpty)
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
    Map<String, Map<String, double>> bankStats,
    CurrencyService currencyService,
    bool isVisible,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          leading: Icon(icon, color: Colors.indigo, size: 22),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.indigo, size: 20),
            onPressed: () => _showEditDialog(context, ref,
                defaultType:
                    title.contains('KREDİ') ? 'Kredi Kartı' : 'Vadesiz Hesap'),
          ),
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                letterSpacing: 0.5),
          ),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: accounts
              .map((bank) => _buildBankItem(
                  context, ref, bank, bankStats, currencyService, isVisible))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildBankItem(
    BuildContext context,
    WidgetRef ref,
    BankAccount bank,
    Map<String, Map<String, double>> bankStats,
    CurrencyService currencyService,
    bool isVisible,
  ) {
    final stats =
        bankStats[bank.id] ?? {'balance': 0.0, 'interest': 0.0, 'tax': 0.0};
    final balance = stats['balance']!;
    final interest = stats['interest']!;
    final tax = stats['tax']!;
    final isNegative = balance < 0;
    final isCC = bank.accountType == 'Kredi Kartı';
    final sign = currencyService.getSymbol(bank.currencyCode);
    final format = NumberFormat.currency(
        locale: bank.currencyCode == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: sign,
        decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditDialog(context, ref, bank: bank),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bank.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          isCC
                              ? 'Hesap Kesim: ${bank.paymentDay} / Son Ödeme: ${bank.dueDay}'
                              : 'Vade Günü: Ayın ${bank.paymentDay}. Günü',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.format(balance).mask(isVisible),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCC
                              ? (balance < 0 ? Colors.red : Colors.green)
                              : (isNegative ? Colors.red : Colors.green),
                        ),
                      ),
                      Text(
                        isCC
                            ? 'Güncel Borç'
                            : (isNegative
                                ? 'Artı Para Kullanımı'
                                : 'Vadesiz Bakiye'),
                        style: TextStyle(
                          fontSize: 9,
                          color: (isCC && balance < 0) || (!isCC && isNegative)
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bank.overdraftLimit > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${isCC ? 'Kart' : 'KMH'} Limiti: ${format.format(bank.overdraftLimit)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      'Kalan: ${format.format(bank.overdraftLimit + balance)}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: balance < 0
                        ? (balance.abs() / bank.overdraftLimit).clamp(0, 1)
                        : 0,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      balance < 0
                          ? (isCC ? Colors.indigo : Colors.orange)
                          : Colors.green,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
              if (interest > 0 || tax > 0) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCostItem(
                        'Faiz Maliyeti', interest, format, isVisible),
                    _buildCostItem('Vergi (BSMV/KKDF)', tax, format, isVisible),
                    _buildCostItem(
                        'Toplam Masraf', interest + tax, format, isVisible,
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

  Widget _buildCostItem(
      String label, double amount, NumberFormat format, bool isVisible,
      {bool isTotal = false}) {
    return Column(
      crossAxisAlignment:
          isTotal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          format.format(amount).mask(isVisible),
          style: TextStyle(
            fontSize: 11,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.red.shade700 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
