import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/bes_provider.dart';
import '../pages/bes_detail_page.dart';
import '../../../../core/services/currency_service.dart';

class BesSummaryCard extends ConsumerWidget {
  const BesSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final besAccount = ref.watch(besProvider);
    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(investDisplayCurrencyProvider);

    final currencyFormat = NumberFormat.currency(
        locale: displayCurrency == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: currencyService.getSymbol(displayCurrency),
        decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BesDetailPage()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_outlined,
                            color: Colors.indigo, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'BES Birikimi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              if (besAccount == null)
                const Text(
                  'Veri yüklenmemiş. Analiz için döküman ekleyin.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else ...[
                if (DateTime.now()
                        .difference(besAccount.lastDataUpdate)
                        .inDays >
                    30)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verileriniz 30 günden eski. Güncellemek için yeni döküman yükleyin.',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(currencyService.convertFromTRY(
                              besAccount.getTotalValue(), displayCurrency)),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Güncel Toplam Değer',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+%18.5', // Bu kısım ileride dinamikleşecek
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
