import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/utils/currency_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class InvestmentComparisonPage extends ConsumerStatefulWidget {
  const InvestmentComparisonPage({super.key});

  @override
  ConsumerState<InvestmentComparisonPage> createState() => _InvestmentComparisonPageState();
}

class _InvestmentComparisonPageState extends ConsumerState<InvestmentComparisonPage> {
  final _amountController = TextEditingController(text: '1000');
  DateTime? _startDate;

  final Map<int, Map<String, double>> _historicalData = {
    2010: {'gold': 65.0, 'usd': 1.50, 'eur': 2.00, 'bist': 600.0}, 
    2011: {'gold': 95.0, 'usd': 1.67, 'eur': 2.30, 'bist': 650.0},
    2012: {'gold': 98.0, 'usd': 1.80, 'eur': 2.35, 'bist': 750.0},
    2013: {'gold': 90.0, 'usd': 1.90, 'eur': 2.50, 'bist': 800.0},
    2014: {'gold': 90.0, 'usd': 2.15, 'eur': 2.90, 'bist': 850.0},
    2015: {'gold': 100.0, 'usd': 2.70, 'eur': 3.00, 'bist': 700.0},
    2016: {'gold': 125.0, 'usd': 3.00, 'eur': 3.30, 'bist': 770.0},
    2017: {'gold': 145.0, 'usd': 3.65, 'eur': 4.10, 'bist': 1100.0},
    2018: {'gold': 215.0, 'usd': 4.80, 'eur': 5.60, 'bist': 950.0},
    2019: {'gold': 280.0, 'usd': 5.75, 'eur': 6.40, 'bist': 1100.0},
    2020: {'gold': 450.0, 'usd': 7.00, 'eur': 8.00, 'bist': 1400.0},
    2021: {'gold': 780.0, 'usd': 11.50, 'eur': 13.00, 'bist': 1800.0},
    2022: {'gold': 1100.0, 'usd': 18.60, 'eur': 19.80, 'bist': 5500.0},
    2023: {'gold': 1950.0, 'usd': 29.50, 'eur': 32.50, 'bist': 7500.0},
    2024: {'gold': 2500.0, 'usd': 33.00, 'eur': 36.00, 'bist': 9000.0}, 
    2025: {'gold': 3200.0, 'usd': 42.00, 'eur': 45.00, 'bist': 12000.0}, 
  };

  List<Map<String, dynamic>> _results = [];
  bool _calculated = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculate() {
    final language = ref.read(languageProvider);
    final lc = language.code;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr(AppStrings.selectStartDatePrompt, lc))),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    final startYear = _startDate!.year;
    final startPrices = _historicalData[startYear] ?? _historicalData[2010]!;
    final currentPrices = _historicalData[2024]!; 

    _results = [];

    var goldAmount = amount / startPrices['gold']!;
    var goldValue = goldAmount * currentPrices['gold']!;
    _results.add({
      'name': AppStrings.tr(AppStrings.goldGramItemLabel, lc),
      'initialAmount': goldAmount, 
      'currentValue': goldValue,
      'color': const Color(0xFFFFD700),
      'icon': Icons.diamond_outlined,
      'unit': 'gr',
    });

    var usdAmount = amount / startPrices['usd']!;
    var usdValue = usdAmount * currentPrices['usd']!;
    _results.add({
      'name': AppStrings.tr(AppStrings.dollarUsdLabel, lc),
      'initialAmount': usdAmount,
      'currentValue': usdValue,
      'color': const Color(0xFF10B981),
      'icon': Icons.attach_money,
      'unit': '\$',
    });

    var eurAmount = amount / startPrices['eur']!;
    var eurValue = eurAmount * currentPrices['eur']!;
    _results.add({
      'name': AppStrings.tr(AppStrings.euroLabel, lc),
      'initialAmount': eurAmount,
      'currentValue': eurValue,
      'color': const Color(0xFF3B82F6),
      'icon': Icons.euro,
      'unit': '€',
    });

    var bistRatio = currentPrices['bist']! / startPrices['bist']!;
    var bistValue = amount * bistRatio;
    _results.add({
      'name': AppStrings.tr(AppStrings.borsaIstanbulLabel, lc),
      'initialAmount': null, 
      'currentValue': bistValue,
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.trending_up,
      'unit': '',
    });

    _results.sort((a, b) => (b['currentValue'] as double).compareTo(a['currentValue'] as double));

    setState(() {
      _calculated = true;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2015),
      firstDate: DateTime(2010),
      lastDate: DateTime(2023, 12, 31), 
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _calculated = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.tr(AppStrings.investmentComparisonTitle, lc),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.textPrimary(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border(context),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.history_edu, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                   Expanded(
                    child: Text(
                      AppStrings.tr(AppStrings.investmentComparisonInfo, lc),
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary(context), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '${AppStrings.tr(AppStrings.investmentAmountLabel, lc)} (${lc == 'tr' ? '₺' : '\$'})',
               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                      decoration: InputDecoration(
                        hintText: '1.000',
                         hintStyle: TextStyle(color: AppColors.textSecondary(context).withValues(alpha: 0.5)),
                        suffixText: lc == 'tr' ? '₺' : '\$',
                        suffixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              AppStrings.tr(AppStrings.whichDatePrompt, lc),
               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _startDate == null ? AppStrings.tr(AppStrings.selectYearPrompt, lc) : DateFormat('yyyy').format(_startDate!),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _startDate == null ? AppColors.textSecondary(context).withValues(alpha: 0.5) : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary(context)),
                  ],
                ),
              ),
            ),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  AppStrings.tr(AppStrings.compareBtn, lc),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_calculated) ...[
              const SizedBox(height: 32),
              Text(
                AppStrings.tr(AppStrings.todayValuesLabel, lc),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),

              Column(
                children: List.generate(_results.length, (index) {
                  final item = _results[index];
                  final isWinner = index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildComparisonCard(
                      context,
                      item,
                      isWinner,
                      lc,
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, Map<String, dynamic> item, bool isWinner, String lc) {
    final currencyFormat = NumberFormat.currency(
        locale: lc == 'tr' ? 'tr_TR' : 'en_US', 
        symbol: lc == 'tr' ? '₺' : '\$', 
        decimalDigits: 0
    );
    final unitFormat = NumberFormat.decimalPattern(lc == 'tr' ? 'tr_TR' : 'en_US');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppColors.success : AppColors.border(context),
          width: isWinner ? 2 : 1,
        ),
        boxShadow: isWinner ? [
          BoxShadow(color: AppColors.success.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))
        ] : AppColors.shadowSm(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(item['currentValue']),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isWinner ? AppColors.success : AppColors.textPrimary(context),
                  ),
                ),
                if (item['initialAmount'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                     '~${unitFormat.format(item['initialAmount'])} ${item['unit']}',
                     style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context).withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          if (isWinner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.tr(AppStrings.winnerLabel, lc),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
