import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/bank_account.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'package:invest_guide/core/utils/currency_input_formatter.dart';
import 'package:uuid/uuid.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({super.key});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  TransactionType _selectedType = TransactionType.expense;
  TransactionCategory? _selectedMainCategory;
  TransactionCategory? _selectedSubCategory;
  DateTime _selectedDate = DateTime.now();
  RecurrenceType _recurrence = RecurrenceType.none;
  BankAccount? _selectedBankAccount;
  DateTime? _dueDate;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainCategories = TransactionCategory.getMainCategories(_selectedType);
    final subCategories = _selectedMainCategory != null
        ? TransactionCategory.getSubCategories(_selectedMainCategory!.id)
        : <TransactionCategory>[];

    final showBankSelection = _selectedMainCategory?.id == 'bank' ||
        _selectedSubCategory?.parentId == 'bank';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTypeSelector(),
                        const SizedBox(height: 16),
                        _buildModernAmountInput(),
                        const SizedBox(height: 12),
                        _buildModernCategorySelector(
                            mainCategories, 'Ana Kategori', true),
                        if (subCategories.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildModernCategorySelector(
                              subCategories, 'Alt Kategori', false),
                        ],
                        if (showBankSelection) ...[
                          const SizedBox(height: 12),
                          _buildModernBankSelector(),
                        ],
                        if (_selectedType == TransactionType.expense) ...[
                          const SizedBox(height: 12),
                          _buildModernDatePicker('Vade Tarihi', _dueDate, false,
                              (date) {
                            setState(() => _dueDate = date);
                          }),
                        ],
                        const SizedBox(height: 12),
                        _buildModernRecurrenceSelector(),
                        const SizedBox(height: 12),
                        _buildModernDatePicker(
                            'Başlangıç Tarihi', _selectedDate, true, (date) {
                          setState(() => _selectedDate = date!);
                        }),
                        if (_recurrence != RecurrenceType.none) ...[
                          const SizedBox(height: 12),
                          _buildModernDatePicker('Tekrarlama Bitiş Tarihi',
                              _recurrenceEndDate, false, (date) {
                            setState(() => _recurrenceEndDate = date);
                          }),
                        ],
                        const SizedBox(height: 12),
                        _buildModernNoteInput(),
                        const SizedBox(height: 20),
                        _buildModernSaveButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Yeni İşlem',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildTypeOption('Gelir', TransactionType.income,
                  AppColors.success, Icons.add_circle_outline)),
          Container(width: 1, height: 50, color: AppColors.grey200),
          Expanded(
              child: _buildTypeOption('Gider', TransactionType.expense,
                  AppColors.error, Icons.remove_circle_outline)),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
      String label, TransactionType type, Color color, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _selectedMainCategory = null;
          _selectedSubCategory = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.grey400, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.grey600, size: 18),
              SizedBox(width: 8),
              Text(
                'Tutar',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: AppColors.grey300, fontSize: 24),
              suffixText: '₺',
              suffixStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Lütfen tutar girin';
              final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
              if (int.tryParse(cleanValue) == null ||
                  int.parse(cleanValue) <= 0) {
                return 'Geçerli bir tutar girin';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernCategorySelector(
      List<TransactionCategory> categories, String label, bool isMain) {
    final selectedValue = isMain ? _selectedMainCategory : _selectedSubCategory;

    return InkWell(
      onTap: () => _showCategoryPicker(categories, label, isMain),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedValue != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isMain ? Icons.category_outlined : Icons.subdirectory_arrow_right,
              color:
                  selectedValue != null ? AppColors.primary : AppColors.grey400,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedValue?.name ??
                        (isMain ? 'Seçiniz' : 'Seçiniz (Opsiyonel)'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selectedValue != null
                          ? AppColors.grey900
                          : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(
      List<TransactionCategory> categories, String label, bool isMain) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = isMain
                    ? _selectedMainCategory?.id == cat.id
                    : _selectedSubCategory?.id == cat.id;

                return InkWell(
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
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.grey900,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBankSelector() {
    return InkWell(
      onTap: _showBankPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedBankAccount != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_outlined,
              color: _selectedBankAccount != null
                  ? AppColors.primary
                  : AppColors.grey400,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Banka Hesabı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedBankAccount != null
                        ? '${_selectedBankAccount!.name} • %${_selectedBankAccount!.overdraftInterestRate}'
                        : 'Seçiniz (Opsiyonel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedBankAccount != null
                          ? AppColors.grey900
                          : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Banka Hesabı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // "None" option
                InkWell(
                  onTap: () {
                    setState(() => _selectedBankAccount = null);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedBankAccount == null
                          ? AppColors.grey100
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedBankAccount == null
                            ? AppColors.grey400
                            : AppColors.grey200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Seçim Yapma',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedBankAccount == null
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.grey700,
                      ),
                    ),
                  ),
                ),
                // Bank options
                ...DefaultBankAccounts.accounts.map((bank) {
                  final isSelected = _selectedBankAccount?.id == bank.id;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedBankAccount = bank);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bank.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color:
                                  isSelected ? Colors.white : AppColors.grey900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '%${bank.overdraftInterestRate}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRecurrenceSelector() {
    final recurrenceLabel = _recurrence == RecurrenceType.none
        ? 'Tekrarlamaz'
        : _recurrence == RecurrenceType.monthly
            ? 'Aylık'
            : 'Yıllık';

    return InkWell(
      onTap: _showRecurrencePicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _recurrence != RecurrenceType.none
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.repeat_outlined,
              color: _recurrence != RecurrenceType.none
                  ? AppColors.primary
                  : AppColors.grey400,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tekrarlama',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recurrenceLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showRecurrencePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tekrarlama',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRecurrenceChip('Tekrarlamaz', RecurrenceType.none),
                _buildRecurrenceChip('Aylık', RecurrenceType.monthly),
                _buildRecurrenceChip('Yıllık', RecurrenceType.yearly),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceChip(String label, RecurrenceType type) {
    final isSelected = _recurrence == type;

    return InkWell(
      onTap: () {
        setState(() {
          _recurrence = type;
          if (type != RecurrenceType.none && _recurrenceEndDate == null) {
            final now = DateTime.now();
            _recurrenceEndDate = DateTime(now.year, 12, 31);
          }
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey900,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDatePicker(String label, DateTime? date, bool isRequired,
      Function(DateTime?) onSelect) {
    // İşlem tarihi için: geçmiş - bugün arası
    // Vade/bitiş tarihi için: bugün - gelecek arası
    final isTransactionDate =
        label.contains('İşlem') || label.contains('Başlangıç');

    return InkWell(
      onTap: () async {
        // Normal tarih seçici
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: isTransactionDate ? DateTime(2020) : DateTime.now(),
          lastDate: isTransactionDate
              ? DateTime.now()
              : DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.grey600, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day} ${_getMonthName(date.month)} ${date.year}'
                        : isRequired
                            ? 'Seçiniz'
                            : 'Seçiniz (Opsiyonel)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          date != null ? AppColors.grey900 : AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_outlined, color: AppColors.grey600, size: 18),
              SizedBox(width: 8),
              Text(
                'Not (Opsiyonel)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.grey900),
            decoration: const InputDecoration(
              hintText: 'İşlemle ilgili notlarınızı ekleyin...',
              hintStyle: TextStyle(color: AppColors.grey400, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'İşlemi Kaydet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final finalCategory = _selectedSubCategory ?? _selectedMainCategory!;

    // Temiz tutar değerini al (bindelik ayracı kaldır)
    final cleanAmount =
        _amountController.text.replaceAll('.', '').replaceAll(',', '');

    final transaction = WalletTransaction(
      id: const Uuid().v4(),
      categoryId: finalCategory.id,
      amount: double.parse(cleanAmount),
      date: _selectedDate,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      type: _selectedType,
      recurrence: _recurrence,
      applyMonthly: false, // Artık kullanılmıyor, her zaman false
      bankAccountId: _selectedBankAccount?.id,
      dueDate: _dueDate,
      recurrenceEndDate: _recurrenceEndDate,
    );

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(walletProvider.notifier).addTransaction(transaction);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('İşlem başarıyla kaydedildi'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
