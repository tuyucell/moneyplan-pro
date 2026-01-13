import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:invest_guide/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:invest_guide/core/providers/theme_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionTier = ref.watch(subscriptionProvider);
    final isPro = subscriptionTier == SubscriptionTier.pro;
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          AppStrings.tr(AppStrings.profileTitle, lc),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            _buildUserHeader(context, isPro, lc),
            const SizedBox(height: 24),

            // Settings/Options Sections
            _buildSectionHeader(context, AppStrings.tr(AppStrings.sectionAccount, lc)),
            _buildSubscriptionTile(context, ref, isPro, lc),
            
            const SizedBox(height: 24),
            _buildSectionHeader(context, AppStrings.tr(AppStrings.sectionAppSettings, lc)),
            _buildLanguageTile(context, ref, language, lc),
            _buildSettingsTile(
              context, 
              icon: Icons.notifications_none, 
              title: AppStrings.tr(AppStrings.notifications, lc),
              subtitle: AppStrings.tr(AppStrings.on, lc), // Optional: translate or remove default
              onTap: () {},
            ),
             _buildSettingsTile(
              context, 
              icon: Icons.palette_outlined, 
              title: AppStrings.tr(AppStrings.appearance, lc),
              subtitle: AppStrings.tr(AppStrings.themeTitle, lc),
              onTap: () {
                 _showThemeDialog(context, ref, lc);
              },
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(context, AppStrings.tr(AppStrings.sectionOther, lc)),
            _buildSettingsTile(
              context, 
              icon: Icons.help_outline, 
              title: AppStrings.tr(AppStrings.helpSupport, lc),
              onTap: () {},
            ),
            _buildSettingsTile(
              context, 
              icon: Icons.privacy_tip_outlined, 
              title: AppStrings.tr(AppStrings.privacyPolicy, lc),
              onTap: () {},
            ),
             GestureDetector(
                onLongPress: () {
                   Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardPage()));
                },
                child: _buildSettingsTile(
                  context, 
                  icon: Icons.info_outline, 
                  title: AppStrings.tr(AppStrings.about, lc),
                  subtitle: 'v1.0.0',
                  onTap: () {},
                ),
             ),
             
             const SizedBox(height: 32),
             TextButton(
               onPressed: () {},
               style: TextButton.styleFrom(foregroundColor: AppColors.error),
               child: Text(AppStrings.tr(AppStrings.logout, lc)),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, bool isPro, String lc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Text(
              'TY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Turgay Yücel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'turgay@investguide.app',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPro ? Colors.amber : Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPro ? Icons.star : Icons.star_border,
                        size: 14,
                        color: isPro ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPro ? AppStrings.tr(AppStrings.subProActive, lc) : AppStrings.tr(AppStrings.subFree, lc), // Could translate active status directly if needed or keep simple
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPro ? Colors.amber[800] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary(context),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, WidgetRef ref, bool isPro, String lc) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user, color: Colors.indigo),
        ),
        title: Text(AppStrings.tr(AppStrings.subStatus, lc), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(isPro ? AppStrings.tr(AppStrings.subProActive, lc) : AppStrings.tr(AppStrings.subFree, lc)),
        trailing: ElevatedButton(
          onPressed: () {
             if (isPro) {
               ref.read(subscriptionProvider.notifier).downgradeToFree();
             } else {
               ref.read(subscriptionProvider.notifier).upgradeToPro();
             }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isPro ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(isPro ? AppStrings.tr(AppStrings.btnDowngrade, lc) : AppStrings.tr(AppStrings.btnUpgrade, lc)),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, LanguageState language, String lc) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.language, color: Colors.orange),
        ),
        title: Text(AppStrings.tr(AppStrings.langTitle, lc), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${language.flag} ${language.name}'),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
           _showLanguageDialog(context, ref, lc);
        },
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary(context), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String lc) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppStrings.tr(AppStrings.langTitle, lc)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(languageProvider.notifier).setLanguage('tr');
              Navigator.pop(ctx);
            },
            child: Row(children: [const Text('🇹🇷'), const SizedBox(width: 12), Text(AppStrings.tr(AppStrings.langTurkish, lc))]),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(languageProvider.notifier).setLanguage('en');
              Navigator.pop(ctx);
            },
            child: Row(children: [const Text('🇺🇸'), const SizedBox(width: 12), Text(AppStrings.tr(AppStrings.langEnglish, lc))]),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, String lc) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppStrings.tr(AppStrings.themeTitle, lc)),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
              Navigator.pop(ctx);
            },
            child: Row(children: [const Icon(Icons.wb_sunny_outlined), const SizedBox(width: 12), Text(AppStrings.tr(AppStrings.themeLight, lc))]),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: Row(children: [const Icon(Icons.nightlight_outlined), const SizedBox(width: 12), Text(AppStrings.tr(AppStrings.themeDark, lc))]),
          ),
        ],
      ),
    );
  }
}
