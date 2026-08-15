import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/currency_service.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';
import '../providers/wallet_provider.dart';

Future<BankAccount?> showBankAccountEditorDialog(
  BuildContext context, {
  BankAccount? bank,
  String defaultType = 'Vadesiz Hesap',
}) {
  return showDialog<BankAccount>(
    context: context,
    useSafeArea: true,
    barrierDismissible: false,
    builder: (_) => BankAccountEditorDialog(
      bank: bank,
      defaultType: defaultType,
    ),
  );
}

class BankAccountEditorDialog extends ConsumerStatefulWidget {
  final BankAccount? bank;
  final String defaultType;

  const BankAccountEditorDialog({
    super.key,
    this.bank,
    this.defaultType = 'Vadesiz Hesap',
  });

  @override
  ConsumerState<BankAccountEditorDialog> createState() =>
      _BankAccountEditorDialogState();
}

class _BankAccountEditorDialogState
    extends ConsumerState<BankAccountEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _statementDayController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _initialBalanceController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _bsmvRateController;
  late final TextEditingController _kkdfRateController;
  final List<_InstallmentDraft> _installmentDrafts = [];
  late String _selectedCurrency;
  bool _hasFutureInstallments = false;
  bool _isSaving = false;
  String? _errorMessage;

  BankAccount? get _bank => widget.bank;
  String get _accountType => _bank?.accountType ?? widget.defaultType;
  bool get _isCreditCard => _accountType == 'Kredi Kartı';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _bank?.name ?? '');
    _limitController = TextEditingController(
      text: CurrencyInputFormatter.formatNumber(
        _bank?.overdraftLimit ?? 0,
        decimalDigits: 2,
      ),
    );
    _statementDayController = TextEditingController(
      text: _bank?.paymentDay.toString() ?? '1',
    );
    _dueDayController = TextEditingController(
      text: _bank?.dueDaysAfterStatement.toString() ?? '10',
    );
    _initialBalanceController = TextEditingController(
      text: CurrencyInputFormatter.formatNumber(
        _bank?.initialBalance ?? 0,
        decimalDigits: 2,
      ),
    );
    _interestRateController = TextEditingController(
      text: _formatNumber(_bank?.overdraftInterestRate ?? 4.5),
    );
    _bsmvRateController = TextEditingController(
      text: _formatNumber(_bank?.bsmvRate ?? 15),
    );
    _kkdfRateController = TextEditingController(
      text: _formatNumber(_bank?.kkdfRate ?? 15),
    );
    for (final entry in _bank?.installmentPlan ?? const []) {
      _installmentDrafts.add(_InstallmentDraft.fromEntry(entry));
    }
    _installmentDrafts.sort(
      (a, b) => a.statementMonth.compareTo(b.statementMonth),
    );
    _hasFutureInstallments = _installmentDrafts.isNotEmpty;
    _selectedCurrency = _bank?.currencyCode ?? 'TRY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    _initialBalanceController.dispose();
    _interestRateController.dispose();
    _bsmvRateController.dispose();
    _kkdfRateController.dispose();
    for (final draft in _installmentDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  double _parseAmount(String value) {
    return CurrencyInputFormatter.parse(value) ?? 0;
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  String? _validateRate(String? value) {
    final rate = _parseAmount(value ?? '');
    if (rate < 0 || rate > 100) return '0 ile 100 arasında bir oran girin';
    return null;
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value ?? '');
    if (day == null || day < 1 || day > 31) {
      return '1 ile 31 arasında bir gün girin';
    }
    return null;
  }

  String? _validateDueOffset(String? value) {
    final dayCount = int.tryParse(value ?? '');
    if (dayCount == null || dayCount < 1 || dayCount > 45) {
      return '1 ile 45 gün arasında girin';
    }
    return null;
  }

  DateTime? get _previewStatementDate {
    final statementDay = int.tryParse(_statementDayController.text);
    if (statementDay == null || statementDay < 1 || statementDay > 31) {
      return null;
    }
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    var statementDate = DateTime(
      now.year,
      now.month,
      statementDay.clamp(1, lastDay),
    );
    final today = DateTime(now.year, now.month, now.day);
    if (statementDate.isBefore(today)) {
      final nextMonthLastDay = DateTime(now.year, now.month + 2, 0).day;
      statementDate = DateTime(
        now.year,
        now.month + 1,
        statementDay.clamp(1, nextMonthLastDay),
      );
    }
    return statementDate;
  }

  DateTime? get _previewDueDate {
    final statementDate = _previewStatementDate;
    final offset = int.tryParse(_dueDayController.text);
    if (statementDate == null || offset == null || offset < 1 || offset > 45) {
      return null;
    }
    return statementDate.add(Duration(days: offset));
  }

  void _addInstallment() {
    var nextMonth = DateTime(DateTime.now().year, DateTime.now().month + 1);
    if (_installmentDrafts.isNotEmpty) {
      final latest = _installmentDrafts
          .map((draft) => draft.statementMonth)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (!latest.isBefore(nextMonth)) {
        nextMonth = DateTime(latest.year, latest.month + 1);
      }
    }
    setState(() {
      _installmentDrafts.add(
        _InstallmentDraft(
          id: const Uuid().v4(),
          statementMonth: nextMonth,
        ),
      );
    });
  }

  Future<void> _pickInstallmentMonth(_InstallmentDraft draft) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.statementMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 20),
      helpText: 'TAKSİDİN EKSTREYE YANSIYACAĞI AY',
    );
    if (picked == null || !mounted) return;
    setState(() {
      draft.statementMonth = DateTime(picked.year, picked.month);
    });
  }

  void _removeInstallment(_InstallmentDraft draft) {
    setState(() => _installmentDrafts.remove(draft));
    draft.dispose();
  }

  double get _futureInstallmentTotal => _installmentDrafts.fold<double>(
        0,
        (total, draft) => total + _parseAmount(draft.amountController.text),
      );

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final initialBalance = _parseAmount(_initialBalanceController.text);
    final balanceChanged =
        _bank == null || (initialBalance - _bank!.initialBalance).abs() > 0.005;
    final dueOffset = _isCreditCard
        ? int.parse(_dueDayController.text)
        : _bank?.dueDaysAfterStatement ?? 10;
    final savedAccount = BankAccount(
      id: _bank?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      accountType: _accountType,
      overdraftInterestRate: _parseAmount(_interestRateController.text),
      bsmvRate: _parseAmount(_bsmvRateController.text),
      kkdfRate: _parseAmount(_kkdfRateController.text),
      overdraftLimit: _parseAmount(_limitController.text),
      paymentDay: int.parse(_statementDayController.text),
      dueDay: _isCreditCard ? (_previewDueDate?.day ?? 10) : 10,
      dueDaysAfterStatement: dueOffset,
      isActive: _bank?.isActive ?? true,
      currencyCode: _selectedCurrency,
      initialBalance: initialBalance,
      createdAt: _bank?.createdAt ?? now,
      balanceEffectiveDate: balanceChanged
          ? now
          : _bank?.balanceEffectiveDate ?? _bank?.createdAt,
      updatedAt: now,
      installmentPlan: _hasFutureInstallments
          ? (_installmentDrafts
              .map(
                (draft) => CreditCardInstallmentEntry(
                  id: draft.id,
                  statementMonth: draft.statementMonth,
                  amount: _parseAmount(draft.amountController.text),
                  note: draft.noteController.text.trim().isEmpty
                      ? null
                      : draft.noteController.text.trim(),
                ),
              )
              .toList()
            ..sort(
              (a, b) => a.statementMonth.compareTo(b.statementMonth),
            ))
          : const [],
    );

    try {
      final notifier = ref.read(bankAccountProvider.notifier);
      if (_bank == null) {
        await notifier.addAccount(savedAccount);
      } else {
        await notifier.updateAccount(savedAccount);
      }
      if (mounted) Navigator.of(context).pop(savedAccount);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Kart kaydedilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _delete() async {
    final bank = _bank;
    if (bank == null || _isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmationContext) => AlertDialog(
        title: Text(_isCreditCard ? 'Kartı Sil' : 'Hesabı Sil'),
        content: Text(
          '${bank.name} ${_isCreditCard ? 'kartını' : 'hesabını'} silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmationContext).pop(false),
            child: const Text('İPTAL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(confirmationContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SİL'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(walletProvider.notifier)
          .deleteGeneratedTransactionsForAccount(bank.id);
      await ref.read(bankAccountProvider.notifier).deleteAccount(bank.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Kart silinemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol =
        ref.watch(currencyServiceProvider).getSymbol(_selectedCurrency);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        _bank == null
            ? (_isCreditCard ? 'Yeni Kart Ekle' : 'Yeni Hesap Ekle')
            : '${_bank!.name} Ayarları',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: _bank == null,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _isCreditCard
                        ? 'Banka / Kart Adı'
                        : 'Banka / Hesap Adı',
                    hintText:
                        _isCreditCard ? 'Örn: Bonus Kart' : 'Örn: Maaş Hesabı',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Bir ad girin'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
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
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limitController,
                  decoration: InputDecoration(
                    labelText: _isCreditCard
                        ? 'Kredi Kartı Limiti'
                        : 'KMH / Eksi Hesap Limiti',
                    suffixText: currencySymbol,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [
                    CurrencyInputFormatter(decimalDigits: 2),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('bank_account_interest_rate'),
                  controller: _interestRateController,
                  decoration: InputDecoration(
                    labelText: _isCreditCard
                        ? 'Aylık Kart Faizi (%)'
                        : 'Aylık KMH / Eksi Bakiye Faizi (%)',
                    helperText: _isCreditCard
                        ? 'Yalnız son ödeme tarihinde ödenmemiş ekstre borcuna uygulanır.'
                        : 'Negatif bakiye varsa vade gününde uygulanır.',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateRate,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('bank_account_bsmv_rate'),
                        controller: _bsmvRateController,
                        decoration: const InputDecoration(
                          labelText: 'BSMV (%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateRate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('bank_account_kkdf_rate'),
                        controller: _kkdfRateController,
                        decoration: const InputDecoration(
                          labelText: 'KKDF (%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateRate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _statementDayController,
                  decoration: InputDecoration(
                    labelText: _isCreditCard
                        ? 'Hesap Kesim Günü (1-31)'
                        : 'Vade / Faiz Günü (1-31)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateDay,
                  onChanged: (_) => setState(() {}),
                ),
                if (_isCreditCard) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDayController,
                    decoration: const InputDecoration(
                      labelText: 'Hesap Kesiminden Sonra Ödeme Süresi',
                      suffixText: 'gün',
                      helperText:
                          'Ayın gün sayısına göre son ödeme tarihi otomatik değişir.',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateDueOffset,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_previewStatementDate != null &&
                      _previewDueDate != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Yaklaşan ekstre: ${DateFormat('dd.MM.yyyy').format(_previewStatementDate!)}  •  '
                        'Son ödeme: ${DateFormat('dd.MM.yyyy').format(_previewDueDate!)}',
                        key: const ValueKey('credit_card_due_date_preview'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('bank_account_initial_balance'),
                  controller: _initialBalanceController,
                  decoration: InputDecoration(
                    labelText: _isCreditCard
                        ? 'Güncel Ekstre / Başlangıç Borcu'
                        : 'Başlangıç Bakiyesi',
                    helperText: _isCreditCard
                        ? 'Bugünkü toplam kart borcunu eksi girin. Faiz, ekstre kesilip son ödeme tarihi geçmeden oluşmaz.'
                        : 'Eksi hesap borcunu negatif girin. Örn: -5000',
                    suffixText: currencySymbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: const [
                    CurrencyInputFormatter(
                      allowNegative: true,
                      decimalDigits: 2,
                    ),
                  ],
                ),
                if (_isCreditCard) ...[
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    key: const ValueKey('credit_card_has_installments'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gelecek aylara yayılan borç var'),
                    subtitle: const Text(
                      'Henüz güncel ekstreye yansımayan taksitleri aylara göre girin.',
                    ),
                    value: _hasFutureInstallments,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _hasFutureInstallments = value);
                            if (value && _installmentDrafts.isEmpty) {
                              _addInstallment();
                            }
                          },
                  ),
                  if (_hasFutureInstallments) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          for (final draft in _installmentDrafts) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: ValueKey(
                                      'installment_month_${draft.id}',
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _pickInstallmentMonth(draft),
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      DateFormat('MM/yyyy')
                                          .format(draft.statementMonth),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey(
                                      'installment_amount_${draft.id}',
                                    ),
                                    controller: draft.amountController,
                                    decoration: InputDecoration(
                                      labelText: 'Aylık Tutar',
                                      suffixText: currencySymbol,
                                      isDense: true,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: const [
                                      CurrencyInputFormatter(decimalDigits: 2),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    validator: (value) {
                                      if (_parseAmount(value ?? '') <= 0) {
                                        return 'Tutar girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Taksidi kaldır',
                                  onPressed: _isSaving
                                      ? null
                                      : () => _removeInstallment(draft),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: draft.noteController,
                              decoration: const InputDecoration(
                                labelText: 'Not (isteğe bağlı)',
                                hintText: 'Örn: Telefon 3/5',
                                isDense: true,
                              ),
                            ),
                            const Divider(height: 24),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: const ValueKey('add_installment_month'),
                              onPressed: _isSaving ? null : _addInstallment,
                              icon: const Icon(Icons.add),
                              label: const Text('AYLIK BORÇ EKLE'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Gelecek: ${CurrencyInputFormatter.formatNumber(_futureInstallmentTotal, decimalDigits: 2)} $currencySymbol',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Her tutar seçilen ayın hesap kesim gününde kart borcuna eklenir.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_bank != null)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SİL'),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('İPTAL'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('KAYDET'),
        ),
      ],
    );
  }
}

class _InstallmentDraft {
  final String id;
  DateTime statementMonth;
  final TextEditingController amountController;
  final TextEditingController noteController;

  _InstallmentDraft({
    required this.id,
    required this.statementMonth,
    String amount = '',
    String note = '',
  })  : amountController = TextEditingController(text: amount),
        noteController = TextEditingController(text: note);

  factory _InstallmentDraft.fromEntry(CreditCardInstallmentEntry entry) {
    final amount = CurrencyInputFormatter.formatNumber(
      entry.amount,
      decimalDigits: 2,
    );
    return _InstallmentDraft(
      id: entry.id,
      statementMonth: entry.statementMonth,
      amount: amount,
      note: entry.note ?? '',
    );
  }

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}
