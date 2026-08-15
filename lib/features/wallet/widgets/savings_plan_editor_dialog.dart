import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';
import 'package:moneyplan_pro/features/wallet/models/bank_account.dart';
import 'package:moneyplan_pro/features/wallet/models/savings_goal.dart';
import 'package:moneyplan_pro/features/wallet/providers/bank_account_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/savings_goal_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/wallet_provider.dart';
import 'package:moneyplan_pro/features/wallet/services/savings_plan_ledger_service.dart';

Future<void> showSavingsPlanEditor(
  BuildContext context, {
  SavingsGoal? existing,
  SavingsPlanType initialType = SavingsPlanType.savings,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SavingsPlanEditorDialog(
      existing: existing,
      initialType: initialType,
    ),
  );
}

class SavingsPlanEditorDialog extends ConsumerStatefulWidget {
  final SavingsGoal? existing;
  final SavingsPlanType initialType;

  const SavingsPlanEditorDialog({
    super.key,
    this.existing,
    this.initialType = SavingsPlanType.savings,
  });

  @override
  ConsumerState<SavingsPlanEditorDialog> createState() =>
      _SavingsPlanEditorDialogState();
}

class _SavingsPlanEditorDialogState
    extends ConsumerState<SavingsPlanEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _target;
  late final TextEditingController _periodic;
  late final TextEditingController _interest;
  late final TextEditingController _years;
  late final TextEditingController _paymentDay;
  late final TextEditingController _governmentRate;
  late final TextEditingController _returnRate;
  late final TextEditingController _profitShare;

  late SavingsPlanType _type;
  late ContributionPeriod _period;
  late SavingsFundingMethod _fundingMethod;
  late String _currency;
  String? _paymentAccountId;
  late bool _automaticPayment;
  late bool _createWalletExpense;
  late DateTime _startDate;
  DateTime? _maturityDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.existing;
    _type = plan?.planType ?? widget.initialType;
    _period = plan?.contributionPeriod ?? ContributionPeriod.monthly;
    _fundingMethod = plan?.fundingMethod ?? SavingsFundingMethod.cash;
    _currency = plan?.currencyCode ??
        (_type == SavingsPlanType.lifeInsurance ? 'USD' : 'TRY');
    _paymentAccountId = plan?.paymentAccountId;
    _automaticPayment =
        plan?.automaticPayment ?? _type != SavingsPlanType.savings;
    _createWalletExpense = plan?.createWalletExpense ?? false;
    _startDate = plan?.contractStartDate ?? DateTime.now();
    _maturityDate = plan?.maturityDate;
    _name = TextEditingController(text: plan?.name ?? '');
    _balance = TextEditingController(text: _number(plan?.currentAmount));
    _target = TextEditingController(text: _number(plan?.targetAmount));
    _periodic =
        TextEditingController(text: _number(plan?.periodicContribution));
    _interest = TextEditingController(text: _number(plan?.interestRate));
    _years = TextEditingController(
      text: plan?.contractYears?.toString() ??
          (_type == SavingsPlanType.lifeInsurance ? '10' : ''),
    );
    _paymentDay = TextEditingController(
      text: (plan?.paymentDay ?? DateTime.now().day.clamp(1, 28)).toString(),
    );
    _governmentRate = TextEditingController(
      text: _number(plan?.governmentContributionRate ?? 20),
    );
    _returnRate = TextEditingController(
      text: _number(plan?.estimatedAnnualReturnRate),
    );
    _profitShare = TextEditingController(
      text: _number(plan?.annualProfitShareRate),
    );
  }

  static String _number(double? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _balance,
      _target,
      _periodic,
      _interest,
      _years,
      _paymentDay,
      _governmentRate,
      _returnRate,
      _profitShare,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isContract => _type != SavingsPlanType.savings;

  List<BankAccount> _eligibleAccounts(List<BankAccount> accounts) {
    return accounts.where((account) {
      if (!account.isActive) return false;
      final isCreditCard = account.accountType == 'Kredi Kartı';
      return _fundingMethod == SavingsFundingMethod.creditCard
          ? isCreditCard
          : !isCreditCard;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(bankAccountProvider);
    final eligibleAccounts = _eligibleAccounts(accounts);
    if (_paymentAccountId != null &&
        !eligibleAccounts.any((account) => account.id == _paymentAccountId)) {
      _paymentAccountId = null;
    }
    final currencies =
        ref.read(currencyServiceProvider).getAvailableCurrencies();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      title: Text(
          widget.existing == null ? 'Yeni yatırım planı' : 'Planı düzenle'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<SavingsPlanType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Plan türü',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SavingsPlanType.savings,
                    child: Text('Birikim / vadeli hesap'),
                  ),
                  DropdownMenuItem(
                    value: SavingsPlanType.bes,
                    child: Text('BES'),
                  ),
                  DropdownMenuItem(
                    value: SavingsPlanType.lifeInsurance,
                    child: Text('Geri ödemeli hayat sigortası'),
                  ),
                ],
                onChanged: widget.existing == null
                    ? (value) {
                        if (value == null) return;
                        setState(() {
                          _type = value;
                          _automaticPayment = value != SavingsPlanType.savings;
                          if (value == SavingsPlanType.lifeInsurance) {
                            _currency = 'USD';
                            if (_years.text.isEmpty) _years.text = '10';
                          } else if (_currency == 'USD' &&
                              value == SavingsPlanType.bes) {
                            _currency = 'TRY';
                          }
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: switch (_type) {
                    SavingsPlanType.bes => 'BES planı / şirket adı',
                    SavingsPlanType.lifeInsurance => 'Poliçe / şirket adı',
                    SavingsPlanType.savings => 'Hesap adı',
                  },
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _numberField(
                      _balance,
                      _isContract ? 'Bugünkü fon değeri' : 'Güncel bakiye',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Para',
                        border: OutlineInputBorder(),
                      ),
                      items: currencies
                          .map((code) => DropdownMenuItem(
                                value: code,
                                child: Text(code),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _currency = value ?? _currency),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isContract) ...[
                _numberField(_target, 'Hedef tutar (isteğe bağlı)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numberField(_interest, 'Yıllık faiz %')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dateField(
                            'Vade tarihi', _maturityDate, _pickMaturity)),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _numberField(_periodic, 'Dönemlik ödeme')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<ContributionPeriod>(
                        initialValue: _period,
                        decoration: const InputDecoration(
                          labelText: 'Periyot',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ContributionPeriod.monthly,
                            child: Text('Aylık'),
                          ),
                          DropdownMenuItem(
                            value: ContributionPeriod.quarterly,
                            child: Text('3 aylık'),
                          ),
                          DropdownMenuItem(
                            value: ContributionPeriod.semiAnnual,
                            child: Text('6 aylık'),
                          ),
                          DropdownMenuItem(
                            value: ContributionPeriod.yearly,
                            child: Text('Yıllık'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _period = value ?? _period),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _dateField(
                            'Sözleşme başlangıcı', _startDate, _pickStart)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _numberField(_years, 'Süre (yıl)', integer: true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _numberField(_paymentDay, 'Ödeme günü (1-28)',
                            integer: true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _numberField(_returnRate, 'Tahmini yıllık fon %')),
                  ],
                ),
                if (_type == SavingsPlanType.bes) ...[
                  const SizedBox(height: 12),
                  _numberField(
                      _governmentRate, 'Devlet katkısı % (değiştirilebilir)'),
                ],
                if (_type == SavingsPlanType.lifeInsurance) ...[
                  const SizedBox(height: 12),
                  _numberField(_profitShare, 'Yıllık kâr payı oranı %'),
                ],
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _automaticPayment,
                  title: const Text('Dönemsel ödemeyi otomatik uygula'),
                  subtitle: const Text(
                      'Plan bakiyesi her tamamlanan dönemde ilerletilir.'),
                  onChanged: (value) => setState(() {
                    _automaticPayment = value;
                    if (!value) _createWalletExpense = false;
                  }),
                ),
                if (_automaticPayment) ...[
                  DropdownButtonFormField<SavingsFundingMethod>(
                    initialValue: _fundingMethod,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme yöntemi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SavingsFundingMethod.cash,
                        child: Text('Nakit / banka hesabı'),
                      ),
                      DropdownMenuItem(
                        value: SavingsFundingMethod.creditCard,
                        child: Text('Kredi kartı'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _fundingMethod = value ?? _fundingMethod;
                      _paymentAccountId = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _paymentAccountId,
                    decoration: InputDecoration(
                      labelText:
                          _fundingMethod == SavingsFundingMethod.creditCard
                              ? 'Kredi kartı'
                              : 'Banka hesabı (isteğe bağlı)',
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      if (_fundingMethod == SavingsFundingMethod.cash)
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Hesapsız nakit'),
                        ),
                      ...eligibleAccounts.map(
                        (account) => DropdownMenuItem<String?>(
                          value: account.id,
                          child: Text(account.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _paymentAccountId = value),
                  ),
                  if (_fundingMethod == SavingsFundingMethod.creditCard &&
                      eligibleAccounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Önce Cüzdan > Kart/Hesap Ayarları bölümünden kart ekleyin.',
                        style:
                            TextStyle(color: AppColors.warning, fontSize: 12),
                      ),
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _createWalletExpense,
                    title: const Text('Cüzdana düzenli gider kaydı ekle'),
                    subtitle: const Text(
                      'Ekstre/e-posta ile ayrıca içe aktarıyorsanız çift kaydı önlemek için kapalı bırakın.',
                    ),
                    onChanged: (value) =>
                        setState(() => _createWalletExpense = value ?? false),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Fon getirisi, devlet katkısı ve kâr payı burada tahmini izleme içindir; sözleşme ve şirket ekstresi gerçek değerin kaynağıdır.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(eligibleAccounts),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool integer = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: integer
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        child: Text(
            value == null ? 'Seç' : DateFormat('dd.MM.yyyy').format(value)),
      ),
    );
  }

  Future<void> _pickStart() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _startDate = value);
  }

  Future<void> _pickMaturity() async {
    final value = await showDatePicker(
      context: context,
      initialDate:
          _maturityDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 36500)),
    );
    if (value != null) setState(() => _maturityDate = value);
  }

  Future<void> _save(List<BankAccount> eligibleAccounts) async {
    final name = _name.text.trim();
    final periodic = _parse(_periodic);
    final years = int.tryParse(_years.text.trim());
    final day = int.tryParse(_paymentDay.text.trim()) ?? 1;
    if (name.isEmpty) return _error('Plan adı zorunlu.');
    if (_isContract && periodic <= 0) {
      return _error('Dönemlik ödeme sıfırdan büyük olmalı.');
    }
    if (_isContract && (years == null || years <= 0)) {
      return _error('Sözleşme süresini yıl olarak girin.');
    }
    if (day < 1 || day > 28) return _error('Ödeme günü 1-28 arasında olmalı.');
    if (_createWalletExpense &&
        _fundingMethod == SavingsFundingMethod.creditCard &&
        (_paymentAccountId == null || eligibleAccounts.isEmpty)) {
      return _error('Gider kaydı için bir kredi kartı seçin.');
    }

    setState(() => _saving = true);
    try {
      final balance = _parse(_balance);
      var target = _parse(_target);
      if (target <= 0) {
        final periodsPerYear = 12 /
            switch (_period) {
              ContributionPeriod.monthly => 1,
              ContributionPeriod.quarterly => 3,
              ContributionPeriod.semiAnnual => 6,
              ContributionPeriod.yearly => 12,
            };
        target = _isContract
            ? balance + periodic * periodsPerYear * (years ?? 1)
            : (balance > 0 ? balance : 1);
      }
      final maturity = _isContract
          ? DateTime(_startDate.year + years!, _startDate.month, _startDate.day)
          : _maturityDate;
      SavingsGoal saved;
      final existing = widget.existing;
      if (existing == null) {
        saved = await ref.read(savingsGoalProvider.notifier).addGoal(
              name,
              target,
              0xFFFFA726,
              currentAmount: balance,
              interestRate: _isContract ? null : _parse(_interest),
              maturityDate: maturity,
              currencyCode: _currency,
              planType: _type,
              periodicContribution: periodic,
              contributionPeriod: _period,
              fundingMethod: _fundingMethod,
              paymentAccountId: _paymentAccountId,
              automaticPayment: _isContract && _automaticPayment,
              createWalletExpense: _isContract && _createWalletExpense,
              contractStartDate: _isContract ? _startDate : null,
              contractYears: _isContract ? years : null,
              paymentDay: day,
              governmentContributionRate: _parse(_governmentRate),
              estimatedAnnualReturnRate: _parse(_returnRate),
              annualProfitShareRate: _parse(_profitShare),
            );
      } else {
        saved = existing.copyWith(
          name: name,
          targetAmount: target,
          currentAmount: balance,
          interestRate: _isContract ? null : _parse(_interest),
          maturityDate: maturity,
          currencyCode: _currency,
          periodicContribution: periodic,
          contributionPeriod: _period,
          fundingMethod: _fundingMethod,
          paymentAccountId: _paymentAccountId,
          clearPaymentAccountId: _paymentAccountId == null,
          automaticPayment: _isContract && _automaticPayment,
          createWalletExpense: _isContract && _createWalletExpense,
          contractStartDate: _isContract ? _startDate : null,
          contractYears: _isContract ? years : null,
          paymentDay: day,
          governmentContributionRate: _parse(_governmentRate),
          estimatedAnnualReturnRate: _parse(_returnRate),
          annualProfitShareRate: _parse(_profitShare),
        );
        await ref.read(savingsGoalProvider.notifier).updateGoal(saved);
      }

      await SavingsPlanLedgerService.sync(
        plan: saved,
        wallet: ref.read(walletProvider.notifier),
        transactions: ref.read(walletProvider),
        accounts: ref.read(bankAccountProvider),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _error('Kaydedilemedi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
