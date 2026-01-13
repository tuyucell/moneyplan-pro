import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:intl/intl.dart';

class RetirementCalculatorPage extends ConsumerStatefulWidget {
  const RetirementCalculatorPage({super.key});

  @override
  ConsumerState<RetirementCalculatorPage> createState() =>
      _RetirementCalculatorPageState();
}

class _RetirementCalculatorPageState
    extends ConsumerState<RetirementCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // SGK Fields
  final _ageController = TextEditingController(text: '30');
  final _workStartAgeController = TextEditingController(text: '22');
  final _currentDaysController = TextEditingController(text: '2500');

  // BES Fields
  final _besMonthlyController = TextEditingController(text: '2000');
  final _besCurrentBalanceController = TextEditingController(text: '50000');
  final _besDurationYearsController = TextEditingController(text: '20');
  final _besReturnRateController = TextEditingController(text: '12');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ageController.dispose();
    _workStartAgeController.dispose();
    _currentDaysController.dispose();
    _besMonthlyController.dispose();
    _besCurrentBalanceController.dispose();
    _besDurationYearsController.dispose();
    _besReturnRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.toolRetirement, lc)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'SGK (4A/4B/4C)'),
            Tab(text: 'BES (Emeklilik)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSgkTab(lc),
          _buildBesTab(lc),
        ],
      ),
    );
  }

  Widget _buildSgkTab(String lc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputSection(
            title: 'SGK Emeklilik Bilgileri',
            children: [
              _buildTextField(_ageController, 'Mevcut Yaşınız', Icons.person),
              _buildTextField(_workStartAgeController,
                  'İlk Sigorta Giriş Yaşınız', Icons.work_outline),
              _buildTextField(_currentDaysController, 'Mevcut Prim Günü',
                  Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 24),
          _buildResultCard(
            title: 'Tahmini Emeklilik Durumu',
            value: 'EYT Kapsamında Değil',
            subtitle: 'Gereken Ek Prim: 4.700 Gün',
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          _buildTipsCard([
            '4A (SSK), 4B (Bağ-Kur) ve 4C (Emekli Sandığı) için emeklilik yaşları farklılık gösterir.',
            '1999 öncesi girişliler için EYT avantajı bulunmaktadır.',
            'Maaş hesaplaması son 10 yılın ortalamasına göre belirlenir.',
          ]),
        ],
      ),
    );
  }

  Widget _buildBesTab(String lc) {
    final monthly = double.tryParse(_besMonthlyController.text) ?? 0;
    final current = double.tryParse(_besCurrentBalanceController.text) ?? 0;
    final years = int.tryParse(_besDurationYearsController.text) ?? 0;
    final rate = (double.tryParse(_besReturnRateController.text) ?? 0) / 100;

    // Updated Government Contribution Rule: 20%
    const govRate = 0.20;

    var total = current;
    var totalGov = 0.0;

    for (var i = 0; i < years * 12; i++) {
      total += monthly;
      totalGov += monthly * govRate;
      total *= (1 + rate / 12);
      totalGov *= (1 +
          rate / 12); // Assuming gov contribution also grows in the same fund
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputSection(
            title: 'BES Birikim Planı',
            children: [
              _buildTextField(_besMonthlyController, 'Aylık Ödeme',
                  Icons.payments_outlined),
              _buildTextField(_besCurrentBalanceController, 'Mevcut Birikim',
                  Icons.savings_outlined),
              _buildTextField(_besDurationYearsController, 'Kalan Süre (Yıl)',
                  Icons.timer_outlined),
              _buildTextField(_besReturnRateController,
                  'Tahmini Fon Getirisi (%)', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 24),
          _buildBesSummary(total, totalGov, currencyFormat),
          const SizedBox(height: 24),
          _buildTipsCard([
            'Bugünkü karar ile Devlet Katkısı %20 olarak güncellenmiştir.',
            'BES\'ten 10 yıl ve 56 yaş kriterini doldurmadan ayrılırsanız devlet katkısının bir kısmından feragat edersiniz.',
            'Fon dağılımınızı yılda 12 kez değiştirme hakkınız vardır.',
          ]),
        ],
      ),
    );
  }

  Widget _buildBesSummary(double total, double gov, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Tahmini Toplam Birikim',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            format.format(total + gov),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleResult('Anapara + Getiri', format.format(total)),
              _buildSimpleResult('Devlet Katkısı (%20)', format.format(gov)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleResult(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInputSection(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ...children.expand((e) => [e, const SizedBox(height: 16)]).toList()
            ..removeLast(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hesapla'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildResultCard(
      {required String title,
      required String value,
      required String subtitle,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTipsCard(List<String> tips) {
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
            'Biliyor muydunuz?',
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
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(tip,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                  height: 1.4))),
                    ],
                  ),
                )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
