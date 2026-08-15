import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/currency_service.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';

Future<BankAccount?> showBankAccountEditorDialog(
  BuildContext context, {
  BankAccount? bank,
  String defaultType = 'Vadesiz Hesap',
}) {
  return showDialog<BankAccount>(
    context: context,
    useSafeArea: true,
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
  late String _selectedCurrency;
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
      text: _bank?.overdraftLimit.toStringAsFixed(0) ?? '0',
    );
    _statementDayController = TextEditingController(
      text: _bank?.paymentDay.toString() ?? '1',
    );
    _dueDayController = TextEditingController(
      text: _bank?.dueDay.toString() ?? '10',
    );
    _initialBalanceController = TextEditingController(
      text: _bank?.initialBalance.toStringAsFixed(0) ?? '0',
    );
    _selectedCurrency = _bank?.currencyCode ?? 'TRY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  double _parseAmount(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String? _validateDay(String? value) {
    final day = int.tryParse(value ?? '');
    if (day == null || day < 1 || day > 31) {
      return '1 ile 31 arasında bir gün girin';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final savedAccount = BankAccount(
      id: _bank?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      accountType: _accountType,
      overdraftInterestRate: _bank?.overdraftInterestRate ?? 4.5,
      overdraftLimit: _parseAmount(_limitController.text),
      paymentDay: int.parse(_statementDayController.text),
      dueDay: _isCreditCard ? int.parse(_dueDayController.text) : 10,
      isActive: _bank?.isActive ?? true,
      currencyCode: _selectedCurrency,
      initialBalance: _parseAmount(_initialBalanceController.text),
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
                ),
                if (_isCreditCard) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dueDayController,
                    decoration: const InputDecoration(
                      labelText: 'Son Ödeme Günü (1-31)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateDay,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialBalanceController,
                  decoration: InputDecoration(
                    labelText:
                        _isCreditCard ? 'Başlangıç Borcu' : 'Mevcut Bakiye',
                    suffixText: currencySymbol,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
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
