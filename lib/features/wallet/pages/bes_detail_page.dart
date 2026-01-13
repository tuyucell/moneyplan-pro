import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/bes_provider.dart';
import '../services/bes_import_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/language_provider.dart';

class BesDetailPage extends ConsumerStatefulWidget {
  const BesDetailPage({super.key});

  @override
  ConsumerState<BesDetailPage> createState() => _BesDetailPageState();
}

class _BesDetailPageState extends ConsumerState<BesDetailPage> {
  NumberFormat _getCurrencyFormat(String code, CurrencyService service) {
    return NumberFormat.currency(
        locale: code == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: service.getSymbol(code),
        decimalDigits: 0);
  }

  @override
  Widget build(BuildContext context) {
    final besAccount = ref.watch(besProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(investDisplayCurrencyProvider);
    final format = _getCurrencyFormat(displayCurrency, currencyService);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text('BES Detay ve Analiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => _importData(),
          ),
          if (besAccount != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(),
            ),
        ],
      ),
      body: besAccount == null
          ? _buildEmptyState(lc)
          : _buildDataView(
              besAccount, lc, format, currencyService, displayCurrency),
    );
  }

  Widget _buildEmptyState(String lc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            const Text(
              'BES Veriniz Bulunmuyor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'BES hesap özetinizi (PDF veya CSV) yükleyerek fon dağılımınızı ve kazancınızı analiz edebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _importData,
              icon: const Icon(Icons.file_upload),
              label: const Text('Dosya Yükle (PDF / CSV)'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataView(besAccount, String lc, NumberFormat format,
      CurrencyService service, String displayCurrency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(besAccount, format, service, displayCurrency),
          const SizedBox(height: 24),
          const Text('Fon Dağılımı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (besAccount.assets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Fon bilgisi bulunamadı. Lütfen dökümanınızı kontrol edin.'),
              ),
            )
          else
            ...besAccount.assets.map((asset) =>
                _buildAssetTile(asset, format, service, displayCurrency)),
          const SizedBox(height: 24),
          const Text('İşlem Geçmişi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...besAccount.transactions.map((tx) =>
              _buildTransactionTile(tx, format, service, displayCurrency)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(besAccount, NumberFormat format,
      CurrencyService service, String displayCurrency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Toplam Birikim (Devlet Katkısı Dahil)',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            format.format(service.convertFromTRY(
                besAccount.getTotalValue(), displayCurrency)),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat(
                  'Kendi Birikiminiz',
                  format.format(service.convertFromTRY(
                      besAccount.getTotalValue() -
                          besAccount.governmentContribution,
                      displayCurrency))),
              _buildSmallStat(
                  'Devlet Katkısı',
                  format.format(service.convertFromTRY(
                      besAccount.governmentContribution, displayCurrency))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
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

  Widget _buildAssetTile(asset, NumberFormat format, CurrencyService service,
      String displayCurrency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(asset.fundCode,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${asset.units.toStringAsFixed(4)} Adet'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                format.format(service.convertFromTRY(
                    asset.getCurrentValue(asset.averageCost), displayCurrency)),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text('Maliyet Değeri',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(tx, NumberFormat format, CurrencyService service,
      String displayCurrency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.arrow_upward, color: Colors.white, size: 16),
        ),
        title: Text(tx.description ?? 'Katkı Payı Ödemesi'),
        subtitle: Text(DateFormat('dd.MM.yyyy').format(tx.date)),
        trailing: Text(
            format.format(service.convertFromTRY(tx.amount, displayCurrency)),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _importData() async {
    try {
      final account = await BesImportService.pickAndImport();
      if (account != null) {
        await ref.read(besProvider.notifier).updateAccount(account);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('BES Verileri Başarıyla İçe Aktarıldı'),
                backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verileri Temizle'),
        content: const Text(
            'İçe aktarılan tüm BES verilerini silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              ref.read(besProvider.notifier).clearAccount();
              Navigator.pop(ctx);
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
