import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:intl/intl.dart';

class LoanKmhCalculatorPage extends ConsumerStatefulWidget {
  const LoanKmhCalculatorPage({super.key});

  @override
  ConsumerState<LoanKmhCalculatorPage> createState() =>
      _LoanKmhCalculatorPageState();
}

class _LoanKmhCalculatorPageState extends ConsumerState<LoanKmhCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController(text: '100000');
  final _rateController = TextEditingController(text: '4.25');
  final _maturityController = TextEditingController(text: '32');

  double _resultNet = 0;
  double _resultTax = 0;
  double _resultGross = 0;
  double _effectiveRate = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculate();
  }

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final monthlyRate = double.tryParse(_rateController.text) ?? 0;
    final days = int.tryParse(_maturityController.text) ?? 0;

    if (_tabController.index == 0) {
      // Mevduat (Deposit)
      // Stopaj: %17.5 for < 6 months
      const stopajRate = 0.175;
      _resultGross = (amount * monthlyRate * days) / (30 * 100);
      _resultTax = _resultGross * stopajRate;
      _resultNet = _resultGross - _resultTax;
      _effectiveRate = monthlyRate * (1 - stopajRate);
    } else {
      // KMH (Overdraft)
      // Taxes: BSMV %15, KKDF %15
      const taxMultiplier = 1.30;
      _resultGross = (amount * monthlyRate * days) / (30 * 100);
      _resultNet = _resultGross * taxMultiplier;
      _resultTax = _resultNet - _resultGross;
      _effectiveRate = monthlyRate * taxMultiplier;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lc = ref.watch(languageProvider).code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.toolLoan, lc)),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => _calculate(),
          tabs: [
            Tab(text: AppStrings.tr(AppStrings.tabInvestments, lc)),
            Tab(text: AppStrings.tr(AppStrings.kmhAccount, lc)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(lc),
            const SizedBox(height: 24),
            _buildResultCard(lc),
            const SizedBox(height: 24),
            _buildTipsCard(lc),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(String lc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _amountController,
            label: _tabController.index == 0 ? 'Ana Para' : 'Kullanılan Tutar',
            suffix: 'TL',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _rateController,
            label: 'Aylık Faiz Oranı',
            suffix: '%',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _maturityController,
            label: 'Süre (Gün)',
            suffix: 'Gün',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppStrings.tr(AppStrings.calculate, lc)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String lc) {
    final isDeposit = _tabController.index == 0;
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDeposit
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            isDeposit ? 'Net Kazanç' : 'Toplam Maliyet',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(_resultNet),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultItem(
                  'Brüt Faiz', currencyFormat.format(_resultGross)),
              _buildResultItem(isDeposit ? 'Stopaj' : 'Vergi (BSMV+KKDF)',
                  currencyFormat.format(_resultTax)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResultItem(
                  'Efektif Aylık Fa.', '%${_effectiveRate.toStringAsFixed(2)}'),
              _buildResultItem(
                  'Günlük Faiz',
                  currencyFormat.format(_resultGross /
                      int.parse(_maturityController.text.isEmpty
                          ? '1'
                          : _maturityController.text))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }

  Widget _buildTipsCard(String lc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          leading: const Icon(Icons.lightbulb_outline,
              color: Colors.orange, size: 22),
          title: const Text(
            'Püf Noktaları',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                letterSpacing: 0.5),
          ),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const Divider(),
            const SizedBox(height: 8),
            _buildTipItem('Valör Kaybı:',
                'Cuma günü yatırdığınız para genellikle Pazartesi faiz almaya başlar. 3 günlük faiz kaybı yaşamamak için hafta başını tercih edin.'),
            const SizedBox(height: 12),
            _buildTipItem('KMH Faizi:',
                'KMH faizi günlük işler. Hafta sonu veya tatil günlerinde de faiz işlemeye devam eder, o yüzden mümkünse Cuma günü KMH borcunu kapatın.'),
            if (_tabController.index == 0) ...[
              const SizedBox(height: 12),
              _buildTipItem('Vergi Avantajı:',
                  'Vade uzadıkça (%17.5\'ten %10\'a) stopaj oranı düşer. Uzun vade her zaman daha fazla net getiri sağlar.'),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String desc) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
            color: AppColors.textSecondary(context), fontSize: 13, height: 1.4),
        children: [
          TextSpan(
              text: '$title ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: desc),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
