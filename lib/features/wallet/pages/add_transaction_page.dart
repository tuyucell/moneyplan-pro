import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/models/transaction_category.dart';
import 'package:moneyplan_pro/features/wallet/models/wallet_transaction.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/core/utils/currency_input_formatter.dart';
import 'package:uuid/uuid.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/wallet/providers/email_integration_provider.dart';
import 'package:moneyplan_pro/features/wallet/pages/email_sync_page.dart';
import 'package:moneyplan_pro/services/analytics/analytics_service.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final WalletTransaction? transaction;
  final DateTime? initialDate;

  const AddTransactionPage({super.key, this.transaction, this.initialDate});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory? _selectedMainCategory;
  TransactionCategory? _selectedSubCategory;
  DateTime _selectedDate = DateTime.now();
  RecurrenceType _recurrence = RecurrenceType.none;
  BankAccount? _selectedBankAccount;
  DateTime? _dueDate;
  DateTime? _recurrenceEndDate;
  bool _isPaidThisMonth = true; // Varsayılan olarak ödendi
  bool _isSubscription = false;
  bool _isPaidByCard = false; // Kredi kartından otomatik ödeniyor mu?

  String _selectedCurrencyCode = 'TRY';

  @override
  void initState() {
    super.initState();

    // Use initialDate if provided
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }

    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _selectedType = tx.type;
      _selectedDate = tx.date;
      _recurrence = tx.recurrence;
      _dueDate = tx.dueDate;
      _recurrenceEndDate = tx.recurrenceEndDate;
      _isPaidThisMonth = tx.isPaid;
      _isSubscription = tx.isSubscription;
      _selectedCurrencyCode = tx.currencyCode;

      final cat = TransactionCategory.findById(tx.categoryId);
      if (cat != null) {
        if (cat.parentId == null) {
          _selectedMainCategory = cat;
        } else {
          _selectedMainCategory = TransactionCategory.findById(cat.parentId!);
          _selectedSubCategory = cat;
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = ref.watch(currencyServiceProvider);
    final mainCategories = TransactionCategory.getMainCategories(_selectedType);
    final subCategories = _selectedMainCategory != null
        ? TransactionCategory.getSubCategories(_selectedMainCategory!.id)
        : <TransactionCategory>[];

    final showBankSelection = _selectedMainCategory?.id == 'bank' ||
        _selectedSubCategory?.parentId == 'bank';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title:
            Text(widget.transaction != null ? 'İŞLEMİ DÜZENLE' : 'YENİ İŞLEM'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector (Segmented Control Style)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            _buildTypeSegment('GELİR', TransactionType.income)),
                    Expanded(
                        child: _buildTypeSegment(
                            'GİDER', TransactionType.expense)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Currency & Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrencyCode,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedCurrencyCode = newValue);
                          }
                        },
                        items: currencyService
                            .getAvailableCurrencies()
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: _selectedType == TransactionType.income
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                      decoration: InputDecoration(
                        labelText: 'Tutar',
                        hintText: '0',
                        suffixText:
                            currencyService.getSymbol(_selectedCurrencyCode),
                        filled: true,
                        fillColor: AppColors.surface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: AppColors.border(context)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen tutar girin';
                        }
                        final cleanValue =
                            value.replaceAll('.', '').replaceAll(',', '');
                        if (int.tryParse(cleanValue) == null ||
                            int.parse(cleanValue) <= 0) {
                          return 'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories Section
              Text('KATEGORİ', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),

              _buildSelectableCard(
                label: 'Ana Kategori',
                value: _selectedMainCategory?.name,
                icon: Icons.category,
                onTap: () =>
                    _showCategoryPicker(mainCategories, 'Ana Kategori', true),
              ),

              if (subCategories.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSelectableCard(
                  label: 'Alt Kategori',
                  value: _selectedSubCategory?.name,
                  icon: Icons.subdirectory_arrow_right,
                  onTap: () =>
                      _showCategoryPicker(subCategories, 'Alt Kategori', false),
                ),
              ],

              if (showBankSelection) ...[
                const SizedBox(height: 12),
                _buildSelectableCard(
                  label: 'Banka Hesabı',
                  value: _selectedBankAccount?.name,
                  icon: Icons.account_balance,
                  onTap: () => _showBankPicker(ref.read(bankAccountProvider)),
                ),
              ],

              if (_selectedMainCategory?.isBES == true ||
                  _selectedSubCategory?.isBES == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.indigo),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proaktif İpucu',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'BES ödemelerini manuel girmek yerine döküman yükleyerek fon dağılımınızı otomatik güncelleyebilirsiniz.',
                              style: TextStyle(fontSize: 12),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close add page
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('BES Sayfasına Git →',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text('DETAYLAR', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildSelectableCard(
                      label: _selectedType == TransactionType.expense
                          ? 'Ödeme Tarihi'
                          : 'İşlem Tarihi',
                      value:
                          '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                      icon: Icons.calendar_today,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (_selectedType == TransactionType.expense)
                      SwitchListTile(
                        title: const Text('Ödendi'),
                        subtitle: const Text('Bakiyeye yansıt'),
                        value: _isPaidThisMonth,
                        activeTrackColor:
                            AppColors.success.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.success,
                        onChanged: (val) =>
                            setState(() => _isPaidThisMonth = val),
                      ),
                    if (_selectedType == TransactionType.expense)
                      const Divider(height: 1),
                    SwitchListTile(
                      title: Text(_selectedType == TransactionType.income
                          ? 'Düzenli Gelir'
                          : 'Abonelik / Düzenli Gider'),
                      subtitle: const Text('Her ay otomatik tekrarla'),
                      value: _isSubscription,
                      activeTrackColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isSubscription = val;
                          if (val && _recurrenceEndDate == null) {
                            final now = DateTime.now();
                            _recurrenceEndDate = DateTime(now.year, 12, 31);
                          }
                        });
                      },
                    ),
                    // Kredi kartından otomatik ödeme checkbox'ı (sadece düzenli gider ise)
                    if (_isSubscription &&
                        _selectedType == TransactionType.expense)
                      Consumer(
                        builder: (context, ref, _) {
                          final hasEmailIntegration =
                              ref.watch(emailIntegrationProvider.select(
                            (state) =>
                                state.isGmailConnected ||
                                state.isOutlookConnected,
                          ));

                          return Column(
                            children: [
                              const Divider(height: 1),
                              SwitchListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Kredi Kartından Otomatik Ödeniyor',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Duplicate Önleme'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Kredi kartından otomatik ödenen giderler (fatura, abonelik) mail ekstresinde zaten görünür.',
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      hasEmailIntegration
                                                          ? '✅ Mail bağlantınız aktif. Bu gider bakiyeye dahil edilmeyecek.'
                                                          : '⚠️ Mail bağlantınız yok. Bu gider bakiyeye dahil edilecek.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            hasEmailIntegration
                                                                ? AppColors
                                                                    .success
                                                                : AppColors
                                                                    .warning,
                                                      ),
                                                    ),
                                                    if (!hasEmailIntegration) ...[
                                                      const SizedBox(
                                                          height: 16),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed: () async {
                                                            Navigator.pop(
                                                                context); // Dialog'u kapat
                                                            await Navigator
                                                                .push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const EmailSyncPage(),
                                                              ),
                                                            );
                                                            // Kullanıcı geri döndüğünde form state korunur
                                                          },
                                                          icon: const Icon(
                                                              Icons.settings,
                                                              size: 18),
                                                          label: const Text(
                                                              'Mail Bağlantısı Ayarla'),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                AppColors
                                                                    .primary,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Tamam'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _isPaidByCard
                                        ? (hasEmailIntegration
                                            ? 'Bakiyeye dahil edilmez'
                                            : 'Mail bağlı değil, bakiyeye dahil edilir')
                                        : 'Manuel eklenir, bakiyeye dahil edilir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          _isPaidByCard && hasEmailIntegration
                                              ? AppColors.success
                                              : AppColors.textTertiary(context),
                                    ),
                                  ),
                                ),
                                value: _isPaidByCard,
                                activeTrackColor:
                                    AppColors.warning.withValues(alpha: 0.5),
                                activeThumbColor: AppColors.warning,
                                onChanged: (val) =>
                                    setState(() => _isPaidByCard = val),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),

              if (_isSubscription) ...[
                const SizedBox(height: 12),
                _buildSelectableCard(
                  label: 'Tekrar Bitiş Tarihi (Opsiyonel)',
                  value: _recurrenceEndDate != null
                      ? '${_recurrenceEndDate!.day}.${_recurrenceEndDate!.month}.${_recurrenceEndDate!.year}'
                      : 'Süresiz (Hiç Bitmesin)',
                  icon: Icons.event_note,
                  onTap: _showRecurrenceEndDatePicker,
                ),
                if (_recurrenceEndDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _recurrenceEndDate = null),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Bitiş Tarihini Kaldır (Süresiz Yap)',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  ),
              ],

              const SizedBox(height: 12),
              // Note Input
              TextFormField(
                controller: _noteController,
                keyboardType: TextInputType.text,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Not (Opsiyonel)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child:
                      Text(widget.transaction != null ? 'GÜNCELLE' : 'KAYDET'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String label, TransactionType type) {
    final isSelected = _selectedType == type;
    final color =
        type == TransactionType.income ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedMainCategory = null;
        _selectedSubCategory = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? AppColors.shadowSm(context) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? color : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableCard({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary(context), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Seçiniz',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: value != null
                              ? AppColors.textPrimary(context)
                              : AppColors.textTertiary(context),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: AppColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isTransactionDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isTransactionDate ? _selectedDate : (_recurrenceEndDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isTransactionDate) {
          _selectedDate = picked;
          if (_selectedType == TransactionType.expense) {
            _dueDate = picked;
          }
        } else {
          _recurrenceEndDate = picked;
        }
      });
    }
  }

  void _showRecurrenceEndDatePicker() {
    _pickDate(false);
  }

  void _showCategoryPicker(
      List<TransactionCategory> categories, String label, bool isMain) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(label, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (!isMain) // Only for sub-categories or optional fields
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.grey),
                title: const Text('Seçme / Temizle'),
                onTap: () {
                  setState(() => _selectedSubCategory = null);
                  Navigator.pop(context);
                },
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = isMain
                      ? _selectedMainCategory?.id == cat.id
                      : _selectedSubCategory?.id == cat.id;

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (isMain) {
                          _selectedMainCategory = cat;
                          _selectedSubCategory = null;
                        } else {
                          _selectedSubCategory = cat;
                        }
                      });
                      Navigator.pop(context);

                      // Proactive Flow:
                      if (isMain && cat.hasSubCategories) {
                        // 1. If main category has subcategories, open sub-picker
                        final subs =
                            TransactionCategory.getSubCategories(cat.id);
                        _showCategoryPicker(subs, 'Alt Kategori', false);
                      } else {
                        // 2. If no sub-picker OR after selecting sub-category, check for bank account
                        final finalCat =
                            _selectedSubCategory ?? _selectedMainCategory;
                        if (finalCat != null) {
                          final isBankRelated = finalCat.id == 'bank' ||
                              finalCat.parentId == 'bank' ||
                              finalCat.id == 'bes';

                          if (isBankRelated) {
                            String? filter;
                            if (finalCat.id == 'bank_credit_card') {
                              filter = 'Kredi Kartı';
                            } else if (finalCat.id == 'bank_loan' ||
                                finalCat.id == 'bank_interest') {
                              // Maybe show checking accounts or specific types?
                              // For now, just open general if not CC.
                            }

                            // Delayed call to ensure the keyboard or previous bottom sheet is cleared
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              _showBankPicker(ref.read(bankAccountProvider),
                                  filterType: filter);
                            });
                          }
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border(context),
                      ),
                    ),
                    tileColor: isSelected
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : null,
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary(context),
                    ),
                    title: Text(
                      cat.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary(context),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankPicker(List<BankAccount> accounts, {String? filterType}) {
    final filteredAccounts = filterType != null
        ? accounts.where((a) => a.accountType == filterType).toList()
        : accounts;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(filterType ?? 'Banka Hesabı',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Seçim Yapma'),
              onTap: () {
                setState(() => _selectedBankAccount = null);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredAccounts.length,
                itemBuilder: (context, index) {
                  final bank = filteredAccounts[index];
                  final isSelected = _selectedBankAccount?.id == bank.id;

                  return ListTile(
                    onTap: () {
                      setState(() => _selectedBankAccount = bank);
                      Navigator.pop(context);
                    },
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    leading: Icon(Icons.account_balance,
                        color: isSelected ? AppColors.primary : null),
                    title: Text(bank.name),
                    subtitle: Text(bank.accountType == 'Kredi Kartı'
                        ? 'Limit: ${bank.overdraftLimit}₺ | Kesim: ${bank.paymentDay} / Son: ${bank.dueDay}'
                        : 'KMH Limit: ${bank.overdraftLimit}₺ | Vade: ${bank.paymentDay}. gün'),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMainCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ana kategori seçin')),
      );
      return;
    }

    final finalCategory = _selectedSubCategory ?? _selectedMainCategory!;

    // Temiz tutar değerini al (bindelik ayracı kaldır)
    final cleanAmount =
        _amountController.text.replaceAll('.', '').replaceAll(',', '');

    final transaction = WalletTransaction(
      id: widget.transaction?.id ?? const Uuid().v4(),
      categoryId: finalCategory.id,
      amount: double.parse(cleanAmount),
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      type: _selectedType,
      recurrence: _isSubscription ? RecurrenceType.monthly : _recurrence,
      applyMonthly: _isSubscription,
      bankAccountId: _selectedBankAccount?.id,
      dueDate: _selectedType == TransactionType.expense ? _dueDate : null,
      recurrenceEndDate: _recurrenceEndDate,
      isPaid: _isPaidThisMonth,
      isSubscription: _isSubscription,
      currencyCode: _selectedCurrencyCode,
      // Ödeme yöntemi ve bakiye hesaplama
      paymentMethod:
          _isPaidByCard ? PaymentMethod.autoPayment : PaymentMethod.cash,
      excludeFromBalance: _isPaidByCard &&
          (ref.read(emailIntegrationProvider).isGmailConnected ||
              ref.read(emailIntegrationProvider).isOutlookConnected),
    );

    final notifier = ref.read(walletProvider.notifier);

    if (widget.transaction != null) {
      await notifier.updateTransaction(transaction);
    } else {
      await notifier.addTransaction(transaction);

      // Analytics: Track new transaction
      await ref.read(analyticsServiceProvider).logEvent(
            name: 'add_transaction',
            category: 'engagement',
            properties: {
              'type': transaction.type.name,
              'category_id': transaction.categoryId,
              'amount': transaction.amount,
              'currency': transaction.currencyCode,
              'is_subscription': transaction.isSubscription,
            },
            screenName: 'AddTransactionPage',
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
