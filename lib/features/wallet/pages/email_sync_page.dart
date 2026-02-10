import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/gmail/v1.dart' show MessagePartHeader;
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/colors.dart';
import '../models/transaction_category.dart';
import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';
import '../providers/email_integration_provider.dart';
import '../services/gmail_sync_service.dart';
import '../services/ai_processing_service.dart';
import '../providers/bank_account_provider.dart';
import '../models/bank_account.dart';

class EmailSyncPage extends ConsumerStatefulWidget {
  const EmailSyncPage({super.key});

  @override
  ConsumerState<EmailSyncPage> createState() => _EmailSyncPageState();
}

class _EmailSyncPageState extends ConsumerState<EmailSyncPage>
    with SingleTickerProviderStateMixin {
  GoogleSignInAccount? _currentUser;
  bool _isOutlookConnected = false;
  bool _autoSync = true;
  bool _isScanning = false;
  bool _isAnalyzing = false;
  DateTime _scanStartDate = DateTime.now().subtract(const Duration(days: 30));
  late TabController _tabController;

  final List<String> _keywords = [
    'BES',
    'emeklilik',
    'ekstre',
    'dekont',
    'fatura',
    'sigorta',
    'hesap özeti',
    'Ekpara',
    'KMH'
  ];

  final List<String> _excludeKeywords = [
    'teslim edildi',
    'kargoya verildi',
    'siparişiniz alındı',
    'iade talebi',
    'mobil şube'
  ];

  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();
  List<Map<String, dynamic>> _foundEmails = [];
  List<Map<String, dynamic>> _processedHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initConnection();
    _loadHistory();
    _loadKeywords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  Future<void> _initConnection() async {
    final user = await GmailSyncService.signInSilently();
    if (mounted && user != null) {
      setState(() {
        _currentUser = user;
      });
      // Sync with integration provider
      await ref.read(emailIntegrationProvider.notifier).setGmailConnected(true);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final box = await Hive.openBox('email_sync_history');
      final items = box.get('history', defaultValue: []);
      if (mounted) {
        setState(() {
          _processedHistory = List<Map<String, dynamic>>.from(
            items.map((e) => Map<String, dynamic>.from(e)),
          );
        });
      }
    } catch (e) {
      debugPrint('History Load Error: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final box = await Hive.openBox('email_sync_history');
      await box.put('history', _processedHistory);
    } catch (e) {
      debugPrint('History Save Error: $e');
    }
  }

  Future<void> _loadKeywords() async {
    try {
      final box = await Hive.openBox('email_sync_settings');
      final savedKeywords = box.get('keywords');
      final savedExclude = box.get('excludeKeywords');

      if (mounted) {
        setState(() {
          if (savedKeywords != null) {
            _keywords.clear();
            _keywords.addAll(List<String>.from(savedKeywords));
          }
          if (savedExclude != null) {
            _excludeKeywords.clear();
            _excludeKeywords.addAll(List<String>.from(savedExclude));
          }
        });
      }
    } catch (e) {
      debugPrint('Keywords Load Error: $e');
    }
  }

  Future<void> _saveKeywords() async {
    try {
      final box = await Hive.openBox('email_sync_settings');
      await box.put('keywords', _keywords);
      await box.put('excludeKeywords', _excludeKeywords);
    } catch (e) {
      debugPrint('Keywords Save Error: $e');
    }
  }

  Future<void> _clearHistory() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text(
            'Tüm tarama geçmişi silinecektir. Bu işlemden sonra daha önce işlediğiniz mailler tekrar tarama listesinde görünebilir. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('VAZGEÇ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('TEMİZLE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final box = await Hive.openBox('email_sync_history');
        await box.clear();
        setState(() {
          _processedHistory = [];
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Tarama geçmişi temizlendi.')),
        );
      } catch (e) {
        debugPrint('Clear History Error: $e');
      }
    }
  }

  Future<void> _handleGmailSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = await GmailSyncService.signIn();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
    });
    if (user != null) {
      // Sync with integration provider
      await ref.read(emailIntegrationProvider.notifier).setGmailConnected(true);

      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Hoş geldin ${user.displayName}! Gmail bağlantısı başarılı.')),
      );
    }
  }

  Future<void> _handleGmailSignOut() async {
    await GmailSyncService.signOut();
    setState(() {
      _currentUser = null;
      _foundEmails = [];
    });
    // Sync with integration provider
    await ref.read(emailIntegrationProvider.notifier).setGmailConnected(false);
  }

  Future<void> _startScan() async {
    if (_currentUser == null) return;

    setState(() => _isScanning = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      final messages = await GmailSyncService.searchFinancialEmails(
        startDate: _scanStartDate,
        customKeywords: _keywords,
        excludeKeywords: _excludeKeywords,
      );

      final details = <Map<String, dynamic>>[];
      final processedIds = _processedHistory.map((e) => e['id']).toSet();

      for (var msg in messages.take(50)) {
        // Skip already processed emails
        if (processedIds.contains(msg.id)) continue;

        final fullMsg = await GmailSyncService.getMessageDetails(msg.id!);
        if (fullMsg != null) {
          final headers = fullMsg.payload?.headers;
          String findHeader(String name) {
            final header = headers?.firstWhere(
              (h) => h.name == name,
              orElse: () => MessagePartHeader()..value = 'Yok',
            );
            return header?.value ?? 'Yok';
          }

          details.add({
            'id': msg.id,
            'subject': findHeader('Subject'),
            'from': findHeader('From'),
            'approved': null,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _foundEmails = details;
      });

      messenger.showSnackBar(
        SnackBar(
            content: Text(
                '${messages.length} ileti bulundu. ${_foundEmails.length} tanesi listelendi.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _processSelected() async {
    final messenger = ScaffoldMessenger.of(context);
    final approvedList =
        _foundEmails.where((e) => e['approved'] == true).toList();
    if (approvedList.isEmpty) return;

    setState(() => _isAnalyzing = true);

    try {
      final processedResults = <ProcessedDocument>[];
      var failCount = 0;

      for (var mail in approvedList) {
        final messageId = mail['id'];
        final fullMsg = await GmailSyncService.getMessageDetails(messageId);

        if (fullMsg == null) {
          failCount++;
          continue;
        }

        final bodyText = GmailSyncService.getPlainText(fullMsg);

        // Attachment text extraction
        String? attachmentText;
        final pdfParts = GmailSyncService.getPdfAttachments(fullMsg);
        if (pdfParts.isNotEmpty) {
          debugPrint('Found ${pdfParts.length} PDF attachments. Processing...');
          for (var part in pdfParts) {
            final attachmentId = part.body!.attachmentId!;
            final attachment =
                await GmailSyncService.getAttachment(messageId, attachmentId);
            if (attachment?.data != null) {
              final bytes = base64.decode(
                  attachment!.data!.replaceAll('-', '+').replaceAll('_', '/'));
              attachmentText = (attachmentText ?? '') +
                  GmailSyncService.extractTextFromPdf(bytes);
            }
          }
        }

        debugPrint(
            'Processing: ${mail['subject']} | Body length: ${bodyText.length} | Attachment text: ${attachmentText?.length ?? 0}');

        final processed = await AIProcessingService.processEmailContent(
          subject: mail['subject'],
          body: bodyText,
          attachmentText: attachmentText,
          messageId: messageId,
        );
        if (processed == null) {
          debugPrint('AI failed to extract info from: ${mail['subject']}');
          failCount++;
        } else {
          processedResults.add(processed);
        }
      }

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (processedResults.isEmpty) {
        _showSummaryDialog(0, failCount, 0);
        return;
      }

      // Show Bulk Review Dialog
      final finalResults = await _showBulkReviewDialog(processedResults);

      if (finalResults != null && finalResults.isNotEmpty) {
        var successCount = 0;
        final now = DateTime.now();

        for (var confirmed in finalResults) {
          if (confirmed.hasData) {
            final isCreditCard = confirmed.categoryId == 'bank_credit_card' ||
                (confirmed.bankId?.endsWith('_cc') ?? false);

            final transaction = WalletTransaction(
              id: const Uuid().v4(),
              categoryId: confirmed.categoryId,
              amount: confirmed.amount,
              currencyCode: confirmed.currencyCode,
              date: confirmed.date,
              dueDate: confirmed.dueDate,
              note: '${confirmed.description} (E-posta)',
              type: TransactionType.expense,
              isPaid:
                  !isCreditCard, // Kredi kartı ekstreleri ödendi işaretlenmez
              bankAccountId: confirmed.bankId,
              paymentMethod: isCreditCard
                  ? PaymentMethod.creditCard
                  : PaymentMethod.bankTransfer,
              recurrence: RecurrenceType.none,
              applyMonthly: false,
            );

            await ref.read(walletProvider.notifier).addTransaction(transaction);
            successCount++;
          }

          // Add to history
          _processedHistory.insert(0, {
            'id': confirmed.originalMessageId ?? const Uuid().v4(),
            'subject': confirmed.description,
            'amount': confirmed.amount,
            'currency': confirmed.currencyCode,
            'date': confirmed.date.toIso8601String(),
            'processedAt': now.toIso8601String(),
          });
        }

        await _saveHistory();
        _showSummaryDialog(successCount, failCount,
            processedResults.length - finalResults.length);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showSummaryDialog(int success, int fail, int skip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlem Özeti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Başarıyla eklenen: $success'),
            if (fail > 0)
              Text('❌ İşlenemeyen: $fail',
                  style: const TextStyle(color: Colors.red)),
            if (skip > 0)
              Text('⏭️ Atlanan: $skip',
                  style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _foundEmails.removeWhere((e) => e['approved'] == true);
              });
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<List<ProcessedDocument>?> _showBulkReviewDialog(
      List<ProcessedDocument> results) async {
    final editableResults = List<ProcessedDocument>.from(results);

    return showDialog<List<ProcessedDocument>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.checklist_rtl, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Toplu Veri Doğrulama'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Verileri düzenlemek için üzerlerine tıklayın:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: editableResults.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = editableResults[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(item.description,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle:
                            Text(DateFormat('dd.MM.yyyy').format(item.date)),
                        trailing: !item.hasData
                            ? const Tooltip(
                                message:
                                    'Veri bulunamadı (Bilgilendirme maili)',
                                child: Icon(Icons.warning_amber,
                                    color: Colors.orange, size: 20),
                              )
                            : Text(
                                '${item.amount.toStringAsFixed(2)} ${item.currencyCode}',
                                style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                        onTap: () async {
                          final edited = await _showReviewDialog(item);
                          if (edited != null) {
                            setDialogState(() {
                              editableResults[index] = edited;
                            });
                          }
                        },
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: item.hasData
                              ? Colors.indigo.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          child: Icon(
                              !item.hasData
                                  ? Icons.notifications_paused
                                  : (item.isBes
                                      ? Icons.savings
                                      : Icons.receipt_long),
                              size: 16,
                              color:
                                  item.hasData ? Colors.indigo : Colors.orange),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İPTAL'),
            ),
            ElevatedButton(
              onPressed: () {
                // Filter out notification only items from being added to wallet,
                // but they will be marked as "processed" in history
                Navigator.pop(ctx, editableResults);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white),
              child: const Text('ONAYLA VE EKLE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ProcessedDocument?> _showReviewDialog(ProcessedDocument data) async {
    final amountController =
        TextEditingController(text: data.amount.toString());
    final descController = TextEditingController(text: data.description);
    var selectedDate = data.date;
    var selectedCatId = data.categoryId;
    var selectedBankId = data.bankId;

    return showDialog<ProcessedDocument>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('Veri Doğrulama'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AI tarafından çıkartılan verileri kontrol edin:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                      labelText: 'Tutar', suffixText: data.currencyCode),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ref
                                .watch(bankAccountProvider)
                                .any((a) => a.id == selectedBankId)
                            ? selectedBankId
                            : (ref
                                    .watch(bankAccountProvider)
                                    .any((a) => a.id == data.bankId)
                                ? data.bankId
                                : null),
                        decoration: const InputDecoration(
                          labelText: 'Banka Hesabı (Opsiyonel)',
                          prefixIcon: Icon(Icons.account_balance, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Seçilmedi')),
                          ...ref.watch(bankAccountProvider).map((bank) =>
                              DropdownMenuItem(
                                  value: bank.id, child: Text(bank.name))),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedBankId = val),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _showAddAccountDialog(ctx, selectedBankId),
                      icon: const Icon(Icons.add_circle, color: Colors.indigo),
                      tooltip: 'Yeni Hesap Ekle',
                    ),
                  ],
                ),
                if (selectedBankId != null &&
                    !ref
                        .read(bankAccountProvider)
                        .any((a) => a.id == selectedBankId))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Bu banka hesabı henüz tanımlanmamış!',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCatId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: TransactionCategory.expenseCategories
                      .where((c) => c.parentId != null || c.id == 'bes')
                      .map((cat) => DropdownMenuItem(
                          value: cat.id, child: Text(cat.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCatId = val);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tarih', style: TextStyle(fontSize: 13)),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                if (data.dueDate != null || selectedCatId == 'bank_credit_card')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Son Ödeme Tarihi',
                        style: TextStyle(fontSize: 13, color: Colors.red)),
                    subtitle: Text(data.dueDate != null
                        ? DateFormat('dd.MM.yyyy').format(data.dueDate!)
                        : 'Seçilmedi'),
                    trailing: const Icon(Icons.event_busy,
                        size: 18, color: Colors.red),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: data.dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          data = data.copyWith(dueDate: picked);
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('VAZGEÇ')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                Navigator.pop(
                    ctx,
                    ProcessedDocument(
                      amount: amount,
                      currencyCode: data.currencyCode,
                      date: selectedDate,
                      description: descController.text,
                      categoryId: selectedCatId,
                      isBes: data.isBes,
                      bankId: selectedBankId,
                      hasData: data.hasData,
                      dueDate: data.dueDate,
                    ));
              },
              child: const Text('ONAYLA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAccountDialog(BuildContext context, String? suggestedId,
      {String currencyCode = 'TRY'}) async {
    final nameController = TextEditingController(
        text: suggestedId
            ?.replaceAll('_cc', '')
            .replaceAll('_', ' ')
            .toUpperCase());
    final limitController = TextEditingController(text: '0');
    final dayController = TextEditingController(text: '15');
    final dueDayController = TextEditingController(text: '25');
    final initialBalanceController = TextEditingController(text: '0');

    var typeValue =
        suggestedId?.endsWith('_cc') == true ? 'Kredi Kartı' : 'Vadesiz Hesap';

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Hesap Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeValue,
                  decoration: const InputDecoration(labelText: 'Hesap Türü'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Vadesiz Hesap', child: Text('Vadesiz Hesap')),
                    DropdownMenuItem(
                        value: 'Kredi Kartı', child: Text('Kredi Kartı')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => typeValue = val);
                  },
                ),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Banka / Kart Adı'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: initialBalanceController,
                  decoration: InputDecoration(
                    labelText: typeValue == 'Kredi Kartı'
                        ? 'Mevcut Borç (Ekstreden)'
                        : 'Mevcut Bakiye',
                    hintText: typeValue == 'Kredi Kartı' ? '35000' : '10000',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  decoration: InputDecoration(
                      labelText:
                          typeValue == 'Kredi Kartı' ? 'Limit' : 'KMH Limiti'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: dayController,
                  decoration: InputDecoration(
                      labelText: typeValue == 'Kredi Kartı'
                          ? 'Hesap Kesim Günü'
                          : 'Vade Günü'),
                  keyboardType: TextInputType.number,
                ),
                if (typeValue == 'Kredi Kartı')
                  TextField(
                    controller: dueDayController,
                    decoration:
                        const InputDecoration(labelText: 'Son Ödeme Günü'),
                    keyboardType: TextInputType.number,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İPTAL')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;

                final newAccount = BankAccount(
                  id: suggestedId ?? const Uuid().v4(),
                  name: nameController.text.trim(),
                  accountType: typeValue,
                  currencyCode: currencyCode,
                  overdraftLimit: double.tryParse(limitController.text) ?? 0,
                  paymentDay: int.tryParse(dayController.text) ?? 15,
                  dueDay: int.tryParse(dueDayController.text) ?? 25,
                  initialBalance:
                      double.tryParse(initialBalanceController.text) ?? 0,
                );

                ref.read(bankAccountProvider.notifier).addAccount(newAccount);
                Navigator.pop(ctx);
              },
              child: const Text('KAYDET'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TARAMA AYARLARI',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 16),
                    _buildDateSelector(setSheetState),
                    const SizedBox(height: 24),
                    _buildKeywordManager(
                      title: 'ARANACAK KELİMELER',
                      subtitle: 'Bu kelimeleri içeren mailler taranır',
                      keywords: _keywords,
                      controller: _keywordController,
                      color: AppColors.primary,
                      onUpdate: () {
                        setSheetState(() {});
                        _saveKeywords();
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildKeywordManager(
                      title: 'İHNAL EDİLECEK KELİMELER',
                      subtitle:
                          'Bu kelimeleri içerenler taramaya dahil edilmez',
                      keywords: _excludeKeywords,
                      controller: _excludeController,
                      color: Colors.red,
                      onUpdate: () {
                        setSheetState(() {});
                        _saveKeywords();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('AYARLARI KAYDET'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Widget _buildDateSelector(StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BAŞLANGIÇ TARİHİ',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _scanStartDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setSheetState(() => _scanStartDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(_scanStartDate)),
                const Icon(Icons.calendar_today,
                    size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordManager({
    required String title,
    required String subtitle,
    required List<String> keywords,
    required TextEditingController controller,
    required Color color,
    required VoidCallback onUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: keywords
              .map((k) => Chip(
                    label: Text(k, style: const TextStyle(fontSize: 12)),
                    onDeleted: () {
                      keywords.remove(k);
                      onUpdate();
                    },
                    backgroundColor: color.withValues(alpha: 0.1),
                    deleteIconColor: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'TASLAK',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Yeni kelime yazın ve + ile ekleyin...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      keywords.add(val);
                      controller.clear();
                      onUpdate();
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: color, size: 28),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    keywords.add(controller.text);
                    controller.clear();
                    onUpdate();
                  }
                },
                tooltip: 'Ekle',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'E-posta Otomasyonu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TARAMA', icon: Icon(Icons.search)),
            Tab(text: 'GEÇMİŞ', icon: Icon(Icons.history)),
          ],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScanTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          const Text(
            'BAĞLI HESAPLAR',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildGmailProviderCard(),
          const SizedBox(height: 12),
          _buildProviderCard(
            name: 'Outlook / Hotmail',
            isConnected: _isOutlookConnected,
            onToggle: (val) => setState(() => _isOutlookConnected = val),
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          if (_currentUser != null) ...[
            _buildScanControlSection(),
            const SizedBox(height: 24),
            if (_foundEmails.isNotEmpty) ...[
              _buildResultsSection(),
              if (_foundEmails.any((e) => e['approved'] == true)) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _processSelected,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_fix_high),
                    label:
                        Text(_isAnalyzing ? 'İŞLENİYOR...' : 'İŞLE VE KAYDET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ] else if (!_isScanning)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.email_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('Taramaya başlamak için butona basın',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
          const Text(
            'AYARLAR',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Otomatik Senkronizasyon'),
                  subtitle: const Text('Yeni dekontlar geldiğinde haber ver'),
                  activeThumbColor: AppColors.primary,
                  value: _autoSync,
                  onChanged: (val) => setState(() => _autoSync = val),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security, size: 20),
                  title: const Text('Veri Gizliliği'),
                  subtitle:
                      const Text('Sadece finansal içerikli e-postalar taranır'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildAISection(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_processedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text('Henüz işlenmiş bir e-posta yok',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Onayladığınız ekstreler burada listelenir.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_processedHistory.length} İşlem Kaydedildi',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Tümünü Temizle',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _processedHistory.length,
            itemBuilder: (context, index) {
              final item = _processedHistory[index];
              final processedAt = DateTime.parse(item['processedAt']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child:
                        const Icon(Icons.check, color: Colors.green, size: 20),
                  ),
                  title: Text(item['subject'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                          'Tutar: ${item['amount']} ${item['currency'] ?? 'TL'}',
                          style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      Text(
                          'İşlem: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(item['date']))}',
                          style: const TextStyle(fontSize: 10)),
                      Text(
                          'Aktarılma: ${DateFormat('dd.MM.yyyy HH:mm').format(processedAt)}',
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanControlSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.history_toggle_off,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TARAMA MERKEZİ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Mailleri taramaya hazırsınız',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showSettingsSheet,
                icon: const Icon(Icons.tune, color: AppColors.primary),
                tooltip: 'Tarama Ayarları',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_isScanning ? 'TARANIYOR...' : 'ŞİMDİ TARA'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TARAMA SONUÇLARI (ONAYINIZA SUNULANLAR)',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        ..._foundEmails.map((mail) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mail['subject'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(mail['from'],
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (mail['approved'] == null) ...[
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => mail['approved'] = false),
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.red),
                            label: const Text('Reddet',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => mail['approved'] = true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Onayla',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white),
                          ),
                        ] else ...[
                          Icon(
                            mail['approved']
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: mail['approved'] ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mail['approved'] ? 'Onaylandı' : 'Reddedildi',
                            style: TextStyle(
                                color: mail['approved']
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => mail['approved'] = null),
                            child: const Text('Geri Al',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildGmailProviderCard() {
    final isConnected = _currentUser != null;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email, color: Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gmail',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    isConnected ? _currentUser!.email : 'Bağlı değil',
                    style: TextStyle(
                        color: isConnected ? Colors.green : Colors.grey,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isConnected ? _handleGmailSignOut : _handleGmailSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isConnected ? Colors.grey.shade200 : AppColors.primary,
                foregroundColor: isConnected ? Colors.black87 : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isConnected ? 'Çıkış Yap' : 'Bağla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required String name,
    required bool isConnected,
    required Function(bool) onToggle,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    isConnected ? 'Bağlı' : 'Bağlı değil',
                    style: TextStyle(
                        color: isConnected ? Colors.green : Colors.grey,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => onToggle(!isConnected),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isConnected ? Colors.grey.shade200 : AppColors.primary,
                foregroundColor: isConnected ? Colors.black87 : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isConnected ? 'Bağlantıyı Kes' : 'Bağla'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akıllı Takip',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Bankalardan gelen ekstre ve dekontları AI ile otomatik cüzdanınıza işleyin.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blueAccent),
              SizedBox(width: 12),
              Text('AI Analizi Nasıl Çalışır?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '1. Sistem periyodik olarak e-postalarınızı tarar.\n'
            '2. "Ekstre", "Dekont", "BES" gibi anahtar kelimeleri arar.\n'
            '3. Bulunan dökümanları otomatik analiz eder.\n'
            '4. Harcamaları gerçek tarihlerine göre cüzdanınıza işler.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}
