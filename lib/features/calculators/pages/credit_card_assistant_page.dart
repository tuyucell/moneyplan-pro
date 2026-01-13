import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class CreditCardAssistantPage extends ConsumerStatefulWidget {
  const CreditCardAssistantPage({super.key});

  @override
  ConsumerState<CreditCardAssistantPage> createState() =>
      _CreditCardAssistantPageState();
}

class _CreditCardAssistantPageState
    extends ConsumerState<CreditCardAssistantPage> {
  final _debtController = TextEditingController(text: '50000');
  double _minPayment = 0;
  double _remainingDebt = 0;
  double _interestOnRemaining = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final debt = double.tryParse(_debtController.text) ?? 0;
    // Minimum payment rule in TR (usually 20% or 40% based on limit)
    // Assuming 20% for simplicity
    _minPayment = debt * 0.20;
    _remainingDebt = debt - _minPayment;

    // Credit card interest rate (Jan 2026: ~3.75% avg)
    // Effective with BSMV/KKDF is ~4.875%
    const monthlyRate = 0.04875;
    _interestOnRemaining = _remainingDebt * monthlyRate;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lc = ref.watch(languageProvider).code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.toolCreditCard, lc)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCalculator(lc),
            const SizedBox(height: 24),
            _buildModernTips(lc),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculator(String lc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Asgari Ödeme Tuzağı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _debtController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculate(),
            decoration: InputDecoration(
              labelText: 'Dönem Borcu',
              suffixText: 'TL',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Minimum Ödeme (%20)', _minPayment),
          _buildInfoRow('Kalan Borç', _remainingDebt),
          _buildInfoRow('Gelecek Ayki Faiz Yükü', _interestOnRemaining,
              isHighlight: true),
          const SizedBox(height: 12),
          const Text(
            'Uyarı: Sadece asgariyi ödemek borcunuzu kartopu gibi büyütür. Borcunuz aslında azalmaz, faiz altında ezilir.',
            style: TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, double value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary(context))),
          Text(
            '${value.toStringAsFixed(2)} TL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? AppColors.error
                  : AppColors.textPrimary(context),
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTips(String lc) {
    return Column(
      children: [
        _buildStepTip(
          icon: Icons.calendar_month,
          title: 'Hesap Kesim Sırrı',
          desc:
              'Hesap kesim tarihinizden 1 gün sonra büyük harcamanızı yapın. Borcun ödeme tarihine kadar 40-45 gün sıfır faizle parayı kullanmış olursunuz.',
        ),
        _buildStepTip(
          icon: Icons.flash_on,
          title: 'Taksitli Nakit Avans vs KMH',
          desc:
              'Genellikle Taksitli Nakit Avans faizi KMH\'dan daha düşüktür. Acil para gerekirse önce taksitli seçenekleri kontrol edin.',
        ),
        _buildStepTip(
          icon: Icons.credit_score,
          title: 'Limit Yönetimi',
          desc:
              'Limitinizin %30\'undan fazlasını kullanmak kredi notunuzu düşürebilir. Düzenli ve düşük oranlı kullanım notunuzu yükseltir.',
        ),
      ],
    );
  }

  Widget _buildStepTip(
      {required IconData icon, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: AppColors.textSecondary(context), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
