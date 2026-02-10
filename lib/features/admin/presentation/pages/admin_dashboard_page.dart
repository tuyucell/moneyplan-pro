import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:moneyplan_pro/core/config/providers/app_config_provider.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final notifier = ref.read(appConfigProvider.notifier);
    final lc = ref.watch(languageProvider).code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: const Text(
          'Admin Konsolu',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.resetToDefaults(),
            tooltip: 'Varsayılanlara Dön',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('WEB ADMİN & ANALİTİK', context),
            const SizedBox(height: 12),
            _buildWebAdminCard(context),
            const SizedBox(height: 32),
            _buildSectionTitle('GENEL İSTATİSTİKLER (SİMÜLE)', context),
            const SizedBox(height: 16),
            _buildStatsGrid(context),
            const SizedBox(height: 32),
            _buildSectionTitle('REKLAM KONTROLÜ', context),
            const SizedBox(height: 8),
            _buildInfoBanner(
              context,
              'İlk başta düşük tutup zamanla artırabilirsin. Kullanıcıyı kaçırmamak için dikkatli ayarla!',
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildAdConfigCard(context, config, notifier, lc),
            const SizedBox(height: 32),
            _buildSectionTitle('PRO ÖZELLİK ERİŞİMİ', context),
            const SizedBox(height: 16),
            _buildProFeaturesCard(context, config, notifier, lc),
            const SizedBox(height: 48),
            _buildInfoCard(context, lc),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAdminCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Detaylı Metrikler & Yönetim',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Kullanıcı takibi, audit logları ve canlı intelligence paneline web üzerinden erişin.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              url_launcher.launchUrl(
                Uri.parse('https://moneyplan.pro/admin/'),
                mode: url_launcher.LaunchMode.externalApplication,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Web Panelini Aç'),
                SizedBox(width: 8),
                Icon(Icons.open_in_new, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.textTertiary(context),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          title: 'Toplam Kullanıcı',
          value: '1.248',
          icon: Icons.people_alt_outlined,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Pro Üyeler',
          value: '142',
          icon: Icons.star_rounded,
          color: Colors.amber,
        ),
        _buildStatCard(
          context,
          title: 'Aylık AI Maliyeti',
          value: '₺164',
          icon: Icons.bolt,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Aylık Ciro',
          value: '₺8.378',
          icon: Icons.payments_outlined,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.border(context).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdConfigCard(
    BuildContext context,
    AppConfig config,
    AppConfigNotifier notifier,
    String lc,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          _buildSliderOption(
            context,
            title: 'Native Ad Frekansı',
            subtitle: 'İşlem listelerinde her X kayıtta bir göster',
            value: config.nativeAdFrequency.toDouble(),
            min: 5,
            max: 30,
            onChanged: (val) => notifier
                .updateConfig(config.copyWith(nativeAdFrequency: val.toInt())),
            recommendation:
                config.nativeAdFrequency > 12 ? '✅ Güvenli' : '⚠️ Agresif',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildSliderOption(
            context,
            title: 'Interstitial Ad Frekansı',
            subtitle: 'Sayfa geçişlerinde her X işlemde bir göster',
            value: config.interstitialAdFrequency.toDouble(),
            min: 3,
            max: 20,
            onChanged: (val) => notifier.updateConfig(
                config.copyWith(interstitialAdFrequency: val.toInt())),
            recommendation:
                config.interstitialAdFrequency > 7 ? '✅ Güvenli' : '⚠️ Agresif',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildSliderOption(
            context,
            title: 'Interstitial Süre Limiti',
            subtitle: 'Tam ekran reklamların maksimum gösterim süresi (sn)',
            value: config.interstitialDuration.toDouble(),
            min: 3,
            max: 10,
            onChanged: (val) => notifier.updateConfig(
                config.copyWith(interstitialDuration: val.toInt())),
            recommendation: config.interstitialDuration <= 5
                ? '✅ Kullanıcı Dostu'
                : '⚠️ Uzun',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          SwitchListTile(
            title: const Text(
              'Rewarded Ad (Ödüllü Video)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Kullanıcılar istediklerinde izleyip ödül kazanabilir',
              style: TextStyle(fontSize: 12),
            ),
            value: config.rewardedAdEnabled == 1,
            activeThumbColor: Colors.green,
            onChanged: (value) => notifier.updateConfig(
                config.copyWith(rewardedAdEnabled: value ? 1 : 0)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    String? recommendation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withValues(alpha: 0.1),
          onChanged: onChanged,
        ),
        if (recommendation != null)
          Text(
            recommendation,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color:
                  recommendation.contains('✅') ? Colors.green : Colors.orange,
            ),
          ),
      ],
    );
  }

  Widget _buildProFeaturesCard(
    BuildContext context,
    AppConfig config,
    AppConfigNotifier notifier,
    String lc,
  ) {
    final featureNames = {
      'ai_analyst': 'AI Portföy Analisti',
      'scenario_planner': 'Gelecek Simülasyonu',
      'investment_comparison': 'Yatırım Karşılaştırma',
      'email_automation': 'E-posta Otomasyonu',
      'real_estate_calculator': 'Gayrimenkul Hesaplayıcı',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: config.proFeatures.entries.map((entry) {
          final isLast = config.proFeatures.entries.last.key == entry.key;
          final displayName = featureNames[entry.key] ?? entry.key;
          return Column(
            children: [
              SwitchListTile(
                title: Text(
                  displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  entry.value
                      ? 'Kilitli (Sadece Pro)'
                      : 'Ücretsiz (Herkese Açık)',
                  style: TextStyle(
                    color: entry.value ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: entry.value,
                activeThumbColor: Colors.red,
                activeTrackColor: Colors.red.withValues(alpha: 0.2),
                inactiveThumbColor: Colors.green,
                inactiveTrackColor: Colors.green.withValues(alpha: 0.2),
                onChanged: (value) => notifier.toggleFeatureLock(entry.key),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String lc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.security, color: Colors.indigo, size: 32),
          const SizedBox(height: 16),
          Text(
            'Güvenli Admin Erişimi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu ayarlar sadece senin cihazında geçerli bir "override" sağlar. Üretim ortamını etkilemez ancak testlerin için birebirdir. Gerçek uygulamada backend\'den kontrol edilecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
