import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/features/calculators/services/calculator_history_service.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:uuid/uuid.dart';

class RealEstateCalculatorPage extends ConsumerStatefulWidget {
  const RealEstateCalculatorPage({super.key});

  @override
  ConsumerState<RealEstateCalculatorPage> createState() =>
      _RealEstateCalculatorPageState();
}

class _RealEstateCalculatorPageState
    extends ConsumerState<RealEstateCalculatorPage> {
  final _housePriceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _rentController = TextEditingController();
  final _inflationController = TextEditingController(text: '40');
  final _returnRateController = TextEditingController(text: '10');
  final _loanRateController = TextEditingController(text: '1.20');
  final _loanTermController = TextEditingController(text: '10');
  final _yearController = TextEditingController(text: '10');

  bool _isMortgage = true;
  bool _isLoanTermMonths = false;

  double? _rentMultiplier;
  double? _adjustedHousePrice;
  double? _opportunityCost;
  double? _totalLoanPayment;
  double? _monthlyLoanPayment;
  bool _calculated = false;

  final _historyService = CalculatorHistoryService();

  Future<void> _saveCalculation() async {
    final language = ref.read(languageProvider);
    final lc = language.code;
    try {
      final currencyFormat = NumberFormat.currency(
          locale: lc == 'tr' ? 'tr_TR' : 'en_US',
          symbol: lc == 'tr' ? '₺' : '\$',
          decimalDigits: 0);

      final item = CalculatorHistoryItem(
        id: const Uuid().v4(),
        title: AppStrings.tr(AppStrings.realEstateCalculatorTitle, lc),
        date: DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
        type: 'real_estate',
        inputs: {
          'house_price': _housePriceController.text,
          'rent': _rentController.text,
          'is_mortgage': _isMortgage,
          'inflation': _inflationController.text,
          'return_rate': _returnRateController.text,
          'down_payment': _downPaymentController.text,
          'loan_rate': _loanRateController.text,
          'loan_term': _loanTermController.text,
          'is_term_months': _isLoanTermMonths,
          'analysis_years': _yearController.text,
        },
        results: {
          'rent_multiplier':
              '${_rentMultiplier!.toStringAsFixed(1)} ${AppStrings.tr(AppStrings.rentMultiplierValue, lc)}',
          'future_house_value': currencyFormat.format(_adjustedHousePrice),
          'opportunity_cost': currencyFormat.format(_opportunityCost),
          'verdict': _adjustedHousePrice! > _opportunityCost!
              ? AppStrings.tr(AppStrings.buyHouseTitleShort, lc)
              : AppStrings.tr(AppStrings.rentHouseTitleShort, lc),
          'monthly_payment':
              _isMortgage ? currencyFormat.format(_monthlyLoanPayment) : '-',
          'total_loan_payment':
              _isMortgage ? currencyFormat.format(_totalLoanPayment) : '-',
        },
      );

      await _historyService.saveResult(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.tr(AppStrings.calculationSaved, lc),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildHistoryModal(),
    );
  }

  Widget _buildHistoryModal() {
    final lc = ref.read(languageProvider).code;
    return FutureBuilder<List<CalculatorHistoryItem>>(
      future: _historyService.getHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final history =
            snapshot.data!.where((item) => item.type == 'real_estate').toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.tr(AppStrings.calculationHistory, lc),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context)),
              ),
            ),
            const Divider(),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  AppStrings.tr(AppStrings.noDataFound, lc),
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.error,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _historyService.deleteItem(item.id),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _showHistoryDetail(item);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background(context),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.border(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.date,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary(
                                              context))),
                                  Text(item.results['verdict'] ?? '',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (item.results['verdict'] ?? '')
                                                      .contains(AppStrings.tr(
                                                          AppStrings
                                                              .houseLabelShort,
                                                          'tr')) ||
                                                  (item.results['verdict'] ??
                                                          '')
                                                      .contains(AppStrings.tr(
                                                          AppStrings
                                                              .houseLabelShort,
                                                          'en'))
                                              ? AppColors.success
                                              : AppColors.warning)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  '${AppStrings.tr(AppStrings.houseLabelShort, lc)}: ${item.inputs['house_price']} ${lc == 'tr' ? '₺' : '\$'}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(context))),
                              if ((item.inputs['is_mortgage'] as bool? ??
                                  false))
                                Text(
                                    '${AppStrings.tr(AppStrings.loanLabelShort, lc)}: ${item.inputs['loan_rate']}% | ${item.inputs['loan_term']} ${(item.inputs['is_term_months'] as bool? ?? false) ? AppStrings.tr(AppStrings.monthJan, lc).substring(0, 2) : AppStrings.tr(AppStrings.years, lc)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            AppColors.textSecondary(context))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showHistoryDetail(CalculatorHistoryItem item) {
    final language = ref.read(languageProvider);
    final lc = language.code;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final isMortgage = item.inputs['is_mortgage'] as bool? ?? false;
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border(context),
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.tr(AppStrings.analysisSummary, lc),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context))),
                    Text(item.date,
                        style:
                            TextStyle(color: AppColors.textSecondary(context))),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (item.results['verdict'] ?? '').contains(
                                AppStrings.tr(
                                    AppStrings.houseLabelShort, 'tr')) ||
                            (item.results['verdict'] ?? '').contains(
                                AppStrings.tr(AppStrings.houseLabelShort, 'en'))
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: (item.results['verdict'] ?? '').contains(
                                    AppStrings.tr(
                                        AppStrings.houseLabelShort, 'tr')) ||
                                (item.results['verdict'] ?? '').contains(
                                    AppStrings.tr(
                                        AppStrings.houseLabelShort, 'en'))
                            ? AppColors.success
                            : AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          (item.results['verdict'] ?? '').contains(
                                      AppStrings.tr(
                                          AppStrings.houseLabelShort, 'tr')) ||
                                  (item.results['verdict'] ?? '').contains(
                                      AppStrings.tr(
                                          AppStrings.houseLabelShort, 'en'))
                              ? Icons.home
                              : Icons.savings,
                          color: (item.results['verdict'] ?? '').contains(
                                      AppStrings.tr(
                                          AppStrings.houseLabelShort, 'tr')) ||
                                  (item.results['verdict'] ?? '').contains(
                                      AppStrings.tr(AppStrings.houseLabelShort, 'en'))
                              ? AppColors.success
                              : AppColors.warning,
                          size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.tr(AppStrings.resultLabel, lc),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(item.results['verdict'] ?? '',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: (item.results['verdict'] ?? '')
                                                .contains(AppStrings.tr(
                                                    AppStrings.houseLabelShort,
                                                    'tr')) ||
                                            (item.results['verdict'] ?? '')
                                                .contains(AppStrings.tr(
                                                    AppStrings.houseLabelShort,
                                                    'en'))
                                        ? AppColors.success
                                        : AppColors.warning)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppStrings.tr(AppStrings.inputsLabel, lc),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildDetailRow(
                          context,
                          AppStrings.tr(AppStrings.housePriceLabel, lc),
                          '${item.inputs['house_price'] ?? '-'}'),
                      const Divider(),
                      _buildDetailRow(
                          context,
                          AppStrings.tr(AppStrings.paymentType, lc),
                          isMortgage
                              ? AppStrings.tr(AppStrings.withMortgage, lc)
                              : AppStrings.tr(AppStrings.cashDown, lc)),
                      if (isMortgage) ...[
                        const Divider(),
                        if (item.inputs.containsKey('down_payment')) ...[
                          _buildDetailRow(
                              context,
                              AppStrings.tr(AppStrings.downPaymentLabel, lc),
                              '${item.inputs['down_payment']}'),
                          const Divider(),
                        ],
                        if (item.inputs.containsKey('loan_rate')) ...[
                          _buildDetailRow(
                              context,
                              AppStrings.tr(
                                  AppStrings.loanInterestRateLabel, lc),
                              '%${item.inputs['loan_rate']}'),
                          const Divider(),
                        ],
                        if (item.inputs.containsKey('loan_term')) ...[
                          _buildDetailRow(
                              context,
                              AppStrings.tr(AppStrings.maturity, lc),
                              '${item.inputs['loan_term']} ${(item.inputs['is_term_months'] as bool? ?? false) ? AppStrings.tr(AppStrings.monthJan, lc).substring(0, 2) : AppStrings.tr(AppStrings.years, lc)}'),
                        ],
                      ],
                      if (item.inputs.containsKey('analysis_years')) ...[
                        const Divider(),
                        _buildDetailRow(
                            context,
                            AppStrings.tr(AppStrings.analysisDuration, lc),
                            '${item.inputs['analysis_years']} ${AppStrings.tr(AppStrings.years, lc)}'),
                      ] else if (item.inputs.containsKey('rent')) ...[
                        const Divider(),
                      ],
                      if (item.inputs.containsKey('rent'))
                        _buildDetailRow(
                            context,
                            AppStrings.tr(AppStrings.monthlyRentLabel, lc),
                            '${item.inputs['rent']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppStrings.tr(AppStrings.financialDetails, lc),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      if (isMortgage) ...[
                        _buildDetailRow(
                            context,
                            AppStrings.tr(AppStrings.monthlyInstallment, lc),
                            item.results['monthly_payment'] ?? '-'),
                        const Divider(),
                        _buildDetailRow(
                            context,
                            AppStrings.tr(AppStrings.totalRepayment, lc),
                            item.results['total_loan_payment'] ?? '-'),
                        const Divider(),
                      ],
                      _buildDetailRow(
                          context,
                          AppStrings.tr(AppStrings.rentMultiplierLabel, lc),
                          item.results['rent_multiplier'] ?? '-'),
                      const Divider(),
                      _buildDetailRow(
                          context,
                          AppStrings.tr(AppStrings.futureHouseValue, lc),
                          item.results['future_house_value'] ?? '-',
                          valueColor: AppColors.primary),
                      const Divider(),
                      _buildDetailRow(
                          context,
                          AppStrings.tr(AppStrings.alternativeInvestment, lc),
                          item.results['opportunity_cost'] ?? '-',
                          valueColor: AppColors.success),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary(context))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary(context))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _housePriceController.dispose();
    _downPaymentController.dispose();
    _rentController.dispose();
    _inflationController.dispose();
    _returnRateController.dispose();
    _loanRateController.dispose();
    _loanTermController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _calculate() {
    final housePrice = double.tryParse(_housePriceController.text
            .replaceAll('.', '')
            .replaceAll(',', '')) ??
        0;
    final monthlyRent = double.tryParse(
            _rentController.text.replaceAll('.', '').replaceAll(',', '')) ??
        0;

    double safeParse(String vol) =>
        double.tryParse(vol.replaceAll(',', '.')) ?? 0;

    final inflationRate = safeParse(_inflationController.text);
    final realReturnRate = safeParse(_returnRateController.text);
    final analysisYears = int.tryParse(_yearController.text) ?? 10;

    final downPayment = _isMortgage
        ? (double.tryParse(_downPaymentController.text
                .replaceAll('.', '')
                .replaceAll(',', '')) ??
            0)
        : housePrice;

    if (housePrice > 0 && monthlyRent > 0) {
      _rentMultiplier = housePrice / (monthlyRent * 12);

      _adjustedHousePrice =
          housePrice * pow((1 + inflationRate / 100), analysisYears);

      var totalLoanCost = 0.0;
      var monthlyPayment = 0.0;
      var loanAmount = 0.0;
      var totalMonths = 0;

      if (_isMortgage && downPayment < housePrice) {
        loanAmount = housePrice - downPayment;
        final monthlyRate = safeParse(_loanRateController.text) / 100;
        final termInput = int.tryParse(_loanTermController.text) ??
            (_isLoanTermMonths ? 120 : 10);

        totalMonths = _isLoanTermMonths ? termInput : termInput * 12;

        if (monthlyRate > 0) {
          monthlyPayment = loanAmount *
              (monthlyRate * pow(1 + monthlyRate, totalMonths)) /
              (pow(1 + monthlyRate, totalMonths) - 1);
        } else {
          monthlyPayment = loanAmount / totalMonths;
        }

        final paymentsInAnalysis = min(analysisYears * 12, totalMonths);
        totalLoanCost = monthlyPayment * paymentsInAnalysis;
      } else {
        totalLoanCost = 0;
      }

      _totalLoanPayment = totalLoanCost;
      _monthlyLoanPayment = monthlyPayment;

      final nominalRate = inflationRate + realReturnRate;
      final monthlyNominalRate = pow(1 + nominalRate / 100, 1 / 12) - 1;

      final opportunityCapital =
          downPayment * pow((1 + nominalRate / 100), analysisYears);
      var opportunityCashFlow = 0.0;

      var monthlyRentIter = monthlyRent;
      final monthlySavedFromLoan =
          (_isMortgage && downPayment < housePrice) ? monthlyPayment : 0;

      for (var month = 1; month <= analysisYears * 12; month++) {
        if (month > 1 && (month - 1) % 12 == 0) {
          monthlyRentIter = monthlyRentIter * (1 + inflationRate / 100);
        }

        double monthlySavings = 0;
        if (month <= totalMonths) {
          monthlySavings += monthlySavedFromLoan;
        }
        monthlySavings -= monthlyRentIter;

        var monthsRemaining = (analysisYears * 12) - month;
        opportunityCashFlow +=
            monthlySavings * pow(1 + monthlyNominalRate, monthsRemaining);
      }

      _opportunityCost = opportunityCapital + opportunityCashFlow;

      setState(() {
        _calculated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final currencyFormat = NumberFormat.currency(
        locale: lc == 'tr' ? 'tr_TR' : 'en_US',
        symbol: lc == 'tr' ? '₺' : '\$',
        decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.tr(AppStrings.realEstateCalculatorTitle, lc),
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.textPrimary(context)),
        ),
        actions: [
          IconButton(
            onPressed: _showHistory,
            icon: Icon(Icons.history, color: AppColors.textPrimary(context)),
            tooltip: AppStrings.tr(AppStrings.calculationHistory, lc),
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.border(context), height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMortgage = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isMortgage
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _isMortgage
                                  ? AppColors.primary
                                  : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.tr(AppStrings.withMortgage, lc),
                            style: TextStyle(
                              fontWeight: _isMortgage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _isMortgage
                                  ? AppColors.primary
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMortgage = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isMortgage
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: !_isMortgage
                                  ? AppColors.success
                                  : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.tr(AppStrings.cashDown, lc),
                            style: TextStyle(
                              fontWeight: !_isMortgage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: !_isMortgage
                                  ? AppColors.success
                                  : AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildInputField(context,
                controller: _housePriceController,
                label: AppStrings.tr(AppStrings.housePriceLabel, lc),
                hint: '0',
                icon: Icons.home_work_outlined),
            const SizedBox(height: 16),
            if (_isMortgage) ...[
              _buildInputField(context,
                  controller: _downPaymentController,
                  label: AppStrings.tr(AppStrings.downPaymentLabel, lc),
                  hint: '0',
                  icon: Icons.savings_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildInputField(context,
                        controller: _loanRateController,
                        label: AppStrings.tr(AppStrings.loanRateInputLabel, lc),
                        hint: '1.20',
                        icon: Icons.percent,
                        isPercentage: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _buildInputField(context,
                        controller: _loanTermController,
                        label: AppStrings.tr(AppStrings.maturity, lc),
                        hint: _isLoanTermMonths ? '120' : '10',
                        icon: Icons.calendar_today,
                        isYear: true,
                        customSuffix: GestureDetector(
                          onTap: () => setState(
                              () => _isLoanTermMonths = !_isLoanTermMonths),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isLoanTermMonths
                                  ? AppStrings.tr(AppStrings.monthJan, lc)
                                      .substring(0, 2)
                                  : AppStrings.tr(AppStrings.years, lc),
                              style: TextStyle(
                                  color: AppColors.textTertiary(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildInputField(context,
                controller: _rentController,
                label: AppStrings.tr(AppStrings.monthlyRentLabel, lc),
                hint: '0',
                icon: Icons.payments_outlined),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(AppStrings.tr(AppStrings.assumptions, lc),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildInputField(context,
                        controller: _inflationController,
                        label:
                            '${AppStrings.tr(AppStrings.expectedInflation, lc)} (%)',
                        hint: '40',
                        icon: Icons.trending_up,
                        isPercentage: true)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildInputField(context,
                        controller: _returnRateController,
                        label:
                            AppStrings.tr(AppStrings.realReturnPercentage, lc),
                        hint: '10',
                        icon: Icons.show_chart,
                        isPercentage: true,
                        infoText:
                            AppStrings.tr(AppStrings.inflationOverNet, lc))),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(context,
                controller: _yearController,
                label: AppStrings.tr(AppStrings.analysisYearsLabel, lc),
                hint: '10',
                icon: Icons.timelapse,
                isYear: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(AppStrings.tr(AppStrings.calculate, lc),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_calculated) ...[
              const SizedBox(height: 32),
              Text(AppStrings.tr(AppStrings.results, lc),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context))),
              const SizedBox(height: 16),
              if (_isMortgage) ...[
                _buildResultCard(context,
                    title: AppStrings.tr(AppStrings.monthlyInstallment, lc),
                    value: currencyFormat.format(_monthlyLoanPayment),
                    description:
                        '${_loanTermController.text} ${_isLoanTermMonths ? AppStrings.tr(AppStrings.monthJan, lc).substring(0, 2) : AppStrings.tr(AppStrings.years, lc).toLowerCase()} ${lc == 'tr' ? 'boyunca sabit' : 'fixed period'}',
                    color: AppColors.error,
                    icon: Icons.calendar_month),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.tr(AppStrings.loanCostTable, lc),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary(context))),
                      const SizedBox(height: 12),
                      _buildComparisonRow(
                          context,
                          AppStrings.tr(AppStrings.loanAmountLabel, lc),
                          (_housePriceController.text.isEmpty
                                  ? 0
                                  : double.tryParse(_housePriceController.text
                                          .replaceAll('.', '')) ??
                                      0) -
                              (double.tryParse(_downPaymentController.text
                                      .replaceAll('.', '')) ??
                                  0),
                          AppColors.textPrimary(context),
                          currencyFormat),
                      const Divider(height: 16),
                      _buildComparisonRow(
                          context,
                          AppStrings.tr(AppStrings.totalRepayment, lc),
                          _monthlyLoanPayment! *
                              (int.tryParse(_loanTermController.text) ?? 10) *
                              (_isLoanTermMonths ? 1 : 12),
                          AppColors.error,
                          currencyFormat),
                      const Divider(height: 16),
                      _buildComparisonRow(
                          context,
                          AppStrings.tr(AppStrings.totalInterestLabel, lc),
                          (_monthlyLoanPayment! *
                                  (int.tryParse(_loanTermController.text) ??
                                      10) *
                                  (_isLoanTermMonths ? 1 : 12)) -
                              ((_housePriceController.text.isEmpty
                                      ? 0
                                      : double.tryParse(_housePriceController
                                              .text
                                              .replaceAll('.', '')) ??
                                          0) -
                                  (double.tryParse(_downPaymentController.text
                                          .replaceAll('.', '')) ??
                                      0)),
                          AppColors.warning,
                          currencyFormat),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildResultCard(context,
                  title: AppStrings.tr(AppStrings.rentMultiplierLabel, lc),
                  value:
                      '${_rentMultiplier!.toStringAsFixed(1)} ${AppStrings.tr(AppStrings.rentMultiplierValue, lc)}',
                  description: AppStrings.tr(AppStrings.amortizationPeriod, lc),
                  color: AppColors.info,
                  icon: Icons.hourglass_bottom),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  children: [
                    _buildComparisonRow(
                        context,
                        AppStrings.tr(AppStrings.futureHouseValue, lc),
                        _adjustedHousePrice!,
                        AppColors.primary,
                        currencyFormat),
                    const Divider(height: 24),
                    _buildComparisonRow(
                        context,
                        AppStrings.tr(AppStrings.alternativeInvestment, lc),
                        _opportunityCost!,
                        AppColors.success,
                        currencyFormat),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildVerdictCard(context, currencyFormat, lc),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saveOfCalculationWithFeedback,
                  icon: const Icon(Icons.save_alt),
                  label: Text(AppStrings.tr(AppStrings.saveResultBtn, lc)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  void _saveOfCalculationWithFeedback() async {
    await _saveCalculation();
  }

  Widget _buildVerdictCard(
      BuildContext context, NumberFormat currencyFormat, String lc) {
    double remainingLoan = 0;
    var loanMonths = int.tryParse(_loanTermController.text) ?? 120;
    if (!_isLoanTermMonths) loanMonths *= 12;

    var analysisMonths = (int.tryParse(_yearController.text) ?? 10) * 12;

    if (_isMortgage && loanMonths > analysisMonths) {
      remainingLoan = _monthlyLoanPayment! * (loanMonths - analysisMonths);
    }

    final netValueBuy = _adjustedHousePrice! - remainingLoan;
    final netValueRent = _opportunityCost!;

    final buyIsBetter = netValueBuy > netValueRent;
    final diff = (netValueBuy - netValueRent).abs();
    var analysisYears = int.tryParse(_yearController.text) ?? 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: buyIsBetter
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: buyIsBetter ? AppColors.success : AppColors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(buyIsBetter ? Icons.home : Icons.savings,
                  color: buyIsBetter ? AppColors.success : AppColors.warning,
                  size: 28),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      buyIsBetter
                          ? AppStrings.tr(AppStrings.buyHouseMoreProfitable, lc)
                          : AppStrings.tr(AppStrings.rentingMoreProfitable, lc),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: buyIsBetter
                              ? AppColors.success
                              : AppColors.warning))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            buyIsBetter
                ? AppStrings.tr(AppStrings.buyHouseVerdict, lc)
                    .replaceFirst('{0}', analysisYears.toString())
                    .replaceFirst('{1}', currencyFormat.format(diff))
                : AppStrings.tr(AppStrings.rentingVerdict, lc)
                    .replaceFirst('{0}', analysisYears.toString())
                    .replaceFirst('{1}', currencyFormat.format(diff)),
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary(context),
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String title, double value,
      Color color, NumberFormat format) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500))),
        Text(format.format(value),
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context,
      {required String title,
      required String value,
      required String description,
      required Color color,
      required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppColors.shadowSm(context)),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context))),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary(context)))
              ])),
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPercentage = false,
    bool isYear = false,
    String? infoText,
    Widget? customSuffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context))),
            if (infoText != null) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: infoText,
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.info_outline,
                    size: 16, color: AppColors.textTertiary(context)),
              )
            ]
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
