import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/features/monetization/services/ad_service.dart';
import 'package:moneyplan_pro/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/email_integration_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionTier = ref.watch(subscriptionProvider);
    final isPro = subscriptionTier == SubscriptionTier.pro;
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.settingsTitle, lc)),
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subscription Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPro
                    ? [Colors.indigo.shade900, Colors.purple.shade900]
                    : [Colors.grey.shade200, Colors.grey.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPro ? Colors.transparent : Colors.grey.shade300,
              ),
              boxShadow: isPro
                  ? [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isPro ? Icons.star : Icons.star_border,
                      color: isPro ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro
                                ? AppStrings.tr(AppStrings.proActive, lc)
                                : AppStrings.tr(AppStrings.freePlan, lc),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPro ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            isPro
                                ? AppStrings.tr(AppStrings.fullAccessDesc, lc)
                                : AppStrings.tr(
                                    AppStrings.upgradeToProDescLong, lc),
                            style: TextStyle(
                              fontSize: 12,
                              color: isPro ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isPro)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(subscriptionProvider.notifier).upgradeToPro();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppStrings.tr(
                                  AppStrings.upgradedToProSuccess, lc))),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          Text(AppStrings.tr(AppStrings.upgradeToProSim, lc)),
                    ),
                  ),
                if (isPro)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(subscriptionProvider.notifier)
                            .downgradeToFree();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppStrings.tr(
                                  AppStrings.downgradedToFreeSuccess, lc))),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                      ),
                      child: Text(
                          AppStrings.tr(AppStrings.cancelSubscriptionSim, lc)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Email Integration Section
          Text(
            'Mail Entegrasyonu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.mail, color: Colors.red),
                  title: const Text('Gmail Bağlantısı'),
                  subtitle: const Text(
                    'Kredi kartı ekstreleri için (Duplicate önleme)',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: ref.watch(emailIntegrationProvider).isGmailConnected,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.success,
                  onChanged: (value) {
                    ref
                        .read(emailIntegrationProvider.notifier)
                        .setGmailConnected(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Gmail bağlantısı aktif edildi. Artık düzenli giderler bakiyeye dahil edilmeyecek.'
                              : 'Gmail bağlantısı kapatıldı. Tüm giderler bakiyeye dahil edilecek.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.mail, color: Colors.blue),
                  title: const Text('Outlook Bağlantısı'),
                  subtitle: const Text(
                    'Kredi kartı ekstreleri için (Duplicate önleme)',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: ref.watch(emailIntegrationProvider).isOutlookConnected,
                  activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.success,
                  onChanged: (value) {
                    ref
                        .read(emailIntegrationProvider.notifier)
                        .setOutlookConnected(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Outlook bağlantısı aktif edildi. Artık düzenli giderler bakiyeye dahil edilmeyecek.'
                              : 'Outlook bağlantısı kapatıldı. Tüm giderler bakiyeye dahil edilecek.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Genel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppStrings.tr(AppStrings.themeSettings, lc)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to theme settings if exists
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(AppStrings.tr(AppStrings.notifications, lc)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.ad_units),
            title: Text(AppStrings.tr(AppStrings.showTestAd, lc)),
            onTap: () {
              ref.read(adServiceProvider.notifier).showInterstitialAd(context);
            },
          ),
          const Divider(),
          GestureDetector(
            onLongPress: () {
              // Secret Admin Access: Long Press on 'About'
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminDashboardPage()),
              );
            },
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(AppStrings.tr(AppStrings.aboutWithAdmin, lc)),
              trailing: const Text('v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
