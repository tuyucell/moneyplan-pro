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
import '../services/gmail_sync_service.dart';
import '../services/ai_processing_service.dart';
import '../providers/bank_account_provider.dart';

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
    'hesap özeti'
  ];

  final List<String> _excludeKeywords = [
    'teslim edildi',
    'kargoya verildi',
    'siparişiniz alındı',
    'iade talebi'
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

  Future<void> _handleGmailSignIn() async {
    final user = await GmailSyncService.signIn();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
    });
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
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
  }

  Future<void> _startScan() async {
    if (_currentUser == null) return;

    setState(() => _isScanning = true);

    try {
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

      ScaffoldMessenger.of(context).showSnackBar(
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
        debugPrint(
            'Processing: ${mail['subject']} | Body length: ${bodyText.length}');

        final processed = await AIProcessingService.processEmailContent(
          subject: mail['subject'],
          body: bodyText,
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
          final transaction = WalletTransaction(
            id: const Uuid().v4(),
            categoryId: confirmed.categoryId,
            amount: confirmed.amount,
            date: confirmed.date,
            note: '${confirmed.description} (E-posta)',
            type: TransactionType.expense,
            isPaid: true,
            bankAccountId: confirmed.bankId,
          );

          await ref.read(walletProvider.notifier).addTransaction(transaction);
          successCount++;

          // Add to history
          _processedHistory.insert(0, {
            'id': approvedList.firstWhere((m) =>
                m['subject'] == confirmed.description ||
                confirmed.description.contains(m['subject']))['id'],
            'subject': confirmed.description,
            'amount': confirmed.amount,
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
        ScaffoldMessenger.of(context).showSnackBar(
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
                        trailing: Text('${item.amount.toStringAsFixed(2)} TL',
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
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          child: Icon(
                              item.isBes ? Icons.savings : Icons.receipt_long,
                              size: 16,
                              color: Colors.indigo),
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
              onPressed: () => Navigator.pop(ctx, editableResults),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white),
              child: const Text('HEPSİNİ CÜZDANA EKLE'),
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
                  decoration: const InputDecoration(
                      labelText: 'Tutar', suffixText: 'TL'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: ref
                          .read(bankAccountProvider)
                          .any((a) => a.id == selectedBankId)
                      ? selectedBankId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Banka Hesabı (Opsiyonel)',
                    prefixIcon: Icon(Icons.account_balance, size: 20),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Seçilmedi')),
                    ...ref.read(bankAccountProvider).map((bank) =>
                        DropdownMenuItem(
                            value: bank.id, child: Text(bank.name))),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedBankId = val),
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
                      date: selectedDate,
                      description: descController.text,
                      categoryId: selectedCatId,
                      isBes: data.isBes,
                      bankId: selectedBankId,
                    ));
              },
              child: const Text('ONAYLA'),
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
                      onUpdate: () => setSheetState(() {}),
                    ),
                    const SizedBox(height: 24),
                    _buildKeywordManager(
                      title: 'İHNAL EDİLECEK KELİMELER',
                      subtitle:
                          'Bu kelimeleri içerenler taramaya dahil edilmez',
                      keywords: _excludeKeywords,
                      controller: _excludeController,
                      color: Colors.red,
                      onUpdate: () => setSheetState(() {}),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Yeni ekle...',
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
              icon: Icon(Icons.add_circle, color: color),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  keywords.add(controller.text);
                  controller.clear();
                  onUpdate();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-POSTA OTOMASYONU'),
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

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _processedHistory.length,
      itemBuilder: (context, index) {
        final item = _processedHistory[index];
        final processedAt = DateTime.parse(item['processedAt']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              child: const Icon(Icons.check, color: Colors.green, size: 20),
            ),
            title: Text(item['subject'],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Tutar: ${item['amount']} TL',
                    style: const TextStyle(
                        color: Colors.indigo, fontWeight: FontWeight.w600)),
                Text(
                    'İşlem Tarihi: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(item['date']))}',
                    style: const TextStyle(fontSize: 11)),
                Text(
                    'Aktarılma: ${DateFormat('dd.MM.yyyy HH:mm').format(processedAt)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
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
