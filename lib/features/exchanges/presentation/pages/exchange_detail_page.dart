import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ExchangeDetailPage extends StatelessWidget {
  final String exchangeId;
  final String exchangeName;
  final String country;
  final double volume24h;
  final int trustScore;

  const ExchangeDetailPage({
    super.key,
    required this.exchangeId,
    required this.exchangeName,
    required this.country,
    required this.volume24h,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          exchangeName,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 20),

            // Hakkında
            _buildSection(
              context,
              'Borsa Hakkında',
              Icons.info_outline,
              _getExchangeDescription(exchangeId),
            ),
            const SizedBox(height: 20),

            // Nasıl Üye Olunur
            _buildSection(
              context,
              'Nasıl Üye Olunur?',
              Icons.person_add_outlined,
              null,
              children: _getSignUpSteps(exchangeId),
            ),
            const SizedBox(height: 20),

            // Nasıl İşlem Yapılır
            _buildSection(
              context,
              'Nasıl İşlem Yapılır?',
              Icons.swap_horiz,
              null,
              children: _getTradingSteps(exchangeId),
            ),
            const SizedBox(height: 20),

            // Önemli Notlar
            _buildImportantNotes(context),
            const SizedBox(height: 20),

            // Borsaya Git Butonu
            _buildActionButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        children: [
          // Icon & Name
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.store,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exchangeName,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          country,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  '24s Hacim',
                  '\$${_formatVolume(volume24h)}',
                  Icons.trending_up,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border(context),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Güven Puanı',
                  '$trustScore/10',
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    String? description, {
    List<Widget>? children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (children != null) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildImportantNotes(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Önemli Notlar',
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoteItem(context, 'Yatırım yapmadan önce mutlaka araştırma yapın'),
          _buildNoteItem(context, 'Kaybetmeyi göze alabileceğinizden fazla yatırım yapmayın'),
          _buildNoteItem(context, 'İki faktörlü kimlik doğrulama (2FA) kullanın'),
          _buildNoteItem(context, 'Varlıklarınızı soğuk cüzdanlarda saklayın'),
        ],
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _launchExchangeURL(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_new, size: 20),
            SizedBox(width: 8),
            Text(
              'Borsaya Git',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000000) {
      return '${(volume / 1000000000000).toStringAsFixed(2)}T';
    } else if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(2);
    }
  }

  String _getExchangeDescription(String exchangeId) {
    final descriptions = {
      'binance': 'Binance, dünyanın en büyük kripto para borsasıdır. 2017 yılında Changpeng Zhao tarafından kurulmuştur. 600\'den fazla kripto para birimi ve düşük işlem ücretleri ile tanınır.',
      'coinbase': 'Coinbase, ABD merkezli önde gelen kripto para borsasıdır. Kullanıcı dostu arayüzü ve yüksek güvenlik standartları ile yeni başlayanlar için idealdir.',
      'btcturk': 'BtcTurk, Türkiye\'nin ilk ve en güvenilir kripto para borsasıdır. 2013 yılından beri hizmet vermektedir. TL ile işlem yapma imkanı sunar.',
      'paribu': 'Paribu, Türkiye\'nin önde gelen kripto para borsalarından biridir. Türk Lirası ile kolay alım satım imkanı ve güvenli platform sunar.',
      'nyse': 'New York Stock Exchange (NYSE), dünyanın en büyük borsa sıdır. 2800\'den fazla şirket listelenir ve günlük ortalama 169 milyar dolar işlem hacmine sahiptir.',
      'nasdaq': 'NASDAQ, teknoloji şirketlerinin ağırlıkta olduğu Amerikan borsasıdır. Apple, Microsoft, Amazon gibi dev şirketler burada işlem görür.',
      'bist': 'Borsa İstanbul (BIST), Türkiye\'nin tek hisse senedi ve türev ürünler borsasıdır. 400\'den fazla şirket işlem görmektedir.',
    };
    return descriptions[exchangeId] ?? 'Bu borsa hakkında detaylı bilgi için lütfen resmi web sitesini ziyaret edin.';
  }

  List<Widget> _getSignUpSteps(String exchangeId) {
    final steps = _getSignUpStepsText(exchangeId);
    return steps
        .asMap()
        .entries
        .map((entry) => _buildStepItem(entry.key + 1, entry.value))
        .toList();
  }

  List<String> _getSignUpStepsText(String exchangeId) {
    final cryptoSteps = [
      'Borsanın resmi web sitesine veya mobil uygulamasına gidin',
      '"Kayıt Ol" veya "Hesap Oluştur" butonuna tıklayın',
      'E-posta adresinizi ve güçlü bir şifre belirleyin',
      'E-posta doğrulamasını tamamlayın',
      'Kimlik doğrulama (KYC) sürecini tamamlayın (TC Kimlik, pasaport vb.)',
      'İki faktörlü kimlik doğrulama (2FA) ayarlayın',
      'Banka hesabınızı veya kredi kartınızı bağlayın',
    ];

    final stockSteps = [
      'Bir aracı kurum seçin ve web sitesine gidin',
      'Hesap açma formunu doldurun',
      'Kimlik belgelerinizi yükleyin (TC Kimlik, ikametgah belgesi)',
      'Hesap onayını bekleyin (1-3 iş günü)',
      'Hesabınıza para yatırın',
      'İşlem yapmaya başlayın',
    ];

    if (exchangeId == 'nyse' || exchangeId == 'nasdaq' || exchangeId == 'bist') {
      return stockSteps;
    }
    return cryptoSteps;
  }

  List<Widget> _getTradingSteps(String exchangeId) {
    final steps = _getTradingStepsText(exchangeId);
    return steps
        .asMap()
        .entries
        .map((entry) => _buildStepItem(entry.key + 1, entry.value))
        .toList();
  }

  List<String> _getTradingStepsText(String exchangeId) {
    final cryptoSteps = [
      'Hesabınıza TL veya kripto para yatırın',
      'İşlem yapmak istediğiniz kripto parayı seçin',
      '"Al" veya "Sat" sekmesini seçin',
      'İşlem türünü belirleyin (Market, Limit, Stop-Limit)',
      'Miktar ve fiyat bilgilerini girin',
      'İşlemi onaylayın',
      'Portföyünüzden işleminizi takip edin',
    ];

    final stockSteps = [
      'Hesabınıza para yatırın',
      'Almak istediğiniz hisseyi arayın',
      'Hisse detaylarını inceleyin',
      'Emir türünü seçin (Piyasa, Limit)',
      'Alım miktarını belirleyin',
      'Emri onaylayın',
      'Portföyünüzden takip edin',
    ];

    if (exchangeId == 'nyse' || exchangeId == 'nasdaq' || exchangeId == 'bist') {
      return stockSteps;
    }
    return cryptoSteps;
  }

  Widget _buildStepItem(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExchangeURL() async {
    final urls = {
      'binance': 'https://www.binance.com',
      'coinbase': 'https://www.coinbase.com',
      'btcturk': 'https://www.btcturk.com',
      'paribu': 'https://www.paribu.com',
      'nyse': 'https://www.nyse.com',
      'nasdaq': 'https://www.nasdaq.com',
      'bist': 'https://www.borsaistanbul.com',
    };

    final url = urls[exchangeId];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
