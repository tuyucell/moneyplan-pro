import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:intl/intl.dart';

class CompoundInterestPage extends StatefulWidget {
  const CompoundInterestPage({super.key});

  @override
  State<CompoundInterestPage> createState() => _CompoundInterestPageState();
}

class _CompoundInterestPageState extends State<CompoundInterestPage> {
  final _principalController = TextEditingController(text: '10000');
  final _monthlyController = TextEditingController(text: '1000');
  final _rateController = TextEditingController(text: '10');
  final _yearsController = TextEditingController(text: '5');
  final _monthsController = TextEditingController(text: '0');

  double _totalAmount = 0;
  double _totalInvested = 0;
  double _totalInterest = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text) ?? 0;
    final monthly = double.tryParse(_monthlyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 0;
    final extraMonths = int.tryParse(_monthsController.text) ?? 0;

    var amount = principal;
    var invested = principal;

    // Monthly compound calculation
    final monthlyRate = rate / 100 / 12;
    final totalMonths = (years * 12) + extraMonths;

    for (var i = 0; i < totalMonths; i++) {
      amount = (amount + (i == 0 ? 0 : 0)) * (1 + monthlyRate) + monthly;
      // Note: This iterative approach adds monthly payment at the *end* of each month
      // Adjusted loop for standard iterative monthly addition:
      // Round 1: amount = 10000 * 1.0025 + 1000 = 11025
      // To match standard FV formula where P earns interest and PMTs earn interest:
      // This implementation matches 'End of Period' payments.
      invested += monthly;
    }

    setState(() {
      _totalAmount = amount;
      _totalInvested = invested;
      _totalInterest = amount - invested;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('Bileşik Faiz Hesaplama'),
        backgroundColor: AppColors.surface(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildResultCard(context, currencyFormat),
            const SizedBox(height: 32),
            _buildInputFields(context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hesapla',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Gelecekteki Toplam Değer',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(_totalAmount),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yatırdığın Ana Para',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(formatter.format(_totalInvested),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Kazanılan Faiz',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('+${formatter.format(_totalInterest)}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight
                              .bold)), // Keeping success color or white depending on contrast
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields(BuildContext context) {
    return Column(
      children: [
        _buildTextField('Başlangıç Yatırımı', _principalController,
            suffix: '₺'),
        const SizedBox(height: 16),
        _buildTextField('Aylık Ek Yatırım', _monthlyController, suffix: '₺'),
        const SizedBox(height: 16),
        _buildTextField('Yıllık Faiz Oranı', _rateController, suffix: '%'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildTextField('Süre (Yıl)', _yearsController,
                    suffix: 'Yıl')),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTextField('Süre (Ay)', _monthsController,
                    suffix: 'Ay')),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? suffix}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: (_) => _calculate(), // Real-time calculation
    );
  }
}
