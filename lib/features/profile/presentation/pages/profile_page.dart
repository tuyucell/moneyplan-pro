import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:moneyplan_pro/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:moneyplan_pro/core/providers/theme_provider.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/features/subscription/presentation/pages/subscription_page.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';
import 'package:moneyplan_pro/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:moneyplan_pro/features/alerts/presentation/pages/alerts_page.dart';
import 'package:moneyplan_pro/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionTier = ref.watch(subscriptionProvider);
    final isPro = subscriptionTier == SubscriptionTier.pro;
    final language = ref.watch(languageProvider);
    final lc = language.code;

    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlertsPage()),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (ctx) => AuthPromptDialog(
                    title: lc == 'tr' ? 'Hesap Gerekli' : 'Account Required',
                    description: lc == 'tr'
                        ? 'Fiyat alarmlarınızı yönetmek için lütfen hesabınıza giriş yapın.'
                        : 'Please login to manage your price alerts.',
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            _buildUserHeader(context, user, isPro, lc),
            const SizedBox(height: 24),

            if (user == null) ...[
              _buildAuthCard(context, lc),
              const SizedBox(height: 24),
            ],

            // Settings/Options Sections
            _buildSectionHeader(
                context, AppStrings.tr(AppStrings.sectionAccount, lc)),
            _buildSubscriptionTile(context, ref, isPro, lc),

            const SizedBox(height: 24),
            _buildSectionHeader(
                context, AppStrings.tr(AppStrings.sectionAppSettings, lc)),
            _buildLanguageTile(context, ref, language, lc),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_none,
              title: AppStrings.tr(AppStrings.notifications, lc),
              subtitle: AppStrings.tr(AppStrings.on, lc),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NotificationPreferencesPage(languageCode: lc),
                  ),
                );
              },
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
            _buildSectionHeader(
                context, AppStrings.tr(AppStrings.sectionOther, lc)),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: AppStrings.tr(AppStrings.helpSupport, lc),
              onTap: () {
                url_launcher
                    .launchUrl(Uri.parse('https://moneyplan.pro/refund.html'));
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: AppStrings.tr(AppStrings.privacyPolicy, lc),
              onTap: () {
                url_launcher
                    .launchUrl(Uri.parse('https://moneyplan.pro/privacy.html'));
              },
            ),
            GestureDetector(
              onLongPress: () {
                if (user?.isAdmin == true && user?.canUseAccount == true) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const AdminDashboardPage()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bu bölüme yetkiniz yok.')),
                  );
                }
              },
              child: _buildSettingsTile(
                context,
                icon: Icons.info_outline,
                title: AppStrings.tr(AppStrings.about, lc),
                subtitle: 'v1.0.0',
                onTap: () {
                  url_launcher
                      .launchUrl(Uri.parse('https://moneyplan.pro/terms.html'));
                },
              ),
            ),

            if (user != null) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(AppStrings.tr(AppStrings.logout, lc)),
              ),
              TextButton.icon(
                onPressed: () =>
                    _confirmAccountDeletion(context, ref, isPro, lc),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(
                  lc == 'tr' ? 'Hesabı ve Verileri Sil' : 'Delete Account',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
    bool isPro,
    String lc,
  ) async {
    final confirmationController = TextEditingController();
    var canDelete = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 40,
          ),
          title: Text(
            lc == 'tr'
                ? 'Hesabın kalıcı olarak silinsin mi?'
                : 'Delete account?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lc == 'tr'
                    ? 'Profilin, cüzdanın, işlemlerin, birikimlerin ve buluttaki tüm kişisel verilerin geri alınamaz biçimde silinecek.'
                    : 'Your profile, wallet, transactions, savings and all personal cloud data will be permanently deleted.',
              ),
              if (isPro) ...[
                const SizedBox(height: 12),
                Text(
                  lc == 'tr'
                      ? 'Önemli: Hesabı silmek Apple aboneliğini otomatik iptal etmez.'
                      : 'Important: Deleting the account does not automatically cancel your Apple subscription.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => url_launcher.launchUrl(
                    Uri.parse('https://apps.apple.com/account/subscriptions'),
                    mode: url_launcher.LaunchMode.externalApplication,
                  ),
                  child: Text(
                    lc == 'tr'
                        ? 'Apple Aboneliğini Yönet'
                        : 'Manage Apple Subscription',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                lc == 'tr'
                    ? 'Onaylamak için SIL yaz:'
                    : 'Type DELETE to confirm:',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => setDialogState(() {
                  canDelete = value.trim() == (lc == 'tr' ? 'SIL' : 'DELETE');
                }),
                decoration: InputDecoration(
                  hintText: lc == 'tr' ? 'SIL' : 'DELETE',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(lc == 'tr' ? 'Vazgeç' : 'Cancel'),
            ),
            FilledButton(
              onPressed:
                  canDelete ? () => Navigator.pop(dialogContext, true) : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(
                lc == 'tr' ? 'Kalıcı Olarak Sil' : 'Delete Permanently',
              ),
            ),
          ],
        ),
      ),
    );
    confirmationController.dispose();
    if (confirmed != true || !context.mounted) return;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.go('/login');
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            lc == 'tr'
                ? 'Hesap silinemedi: $error'
                : 'Account could not be deleted: $error',
          ),
        ),
      );
    }
  }

  Widget _buildAuthCard(BuildContext context, String lc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            lc == 'tr'
                ? 'Tüm özelliklere erişmek için giriş yapın'
                : 'Login to access all features',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppStrings.tr(AppStrings.loginBtn, lc)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
      BuildContext context, UserModel? user, bool isPro, String lc) {
    final displayName =
        user?.displayName ?? (lc == 'tr' ? 'Misafir Kullanıcı' : 'Guest User');
    final email =
        user?.email ?? (lc == 'tr' ? 'Giriş yapılmadı' : 'Not logged in');
    final initials = user != null
        ? (user.displayName != null && user.displayName!.isNotEmpty
            ? user.displayName!.substring(0, 1).toUpperCase()
            : user.email.substring(0, 1).toUpperCase())
        : '?';

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
            child: Text(
              initials,
              style: const TextStyle(
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
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                if (user?.isAdmin == true) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user!.isSuperAdmin ? 'Süper Admin' : 'Admin',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPro
                        ? Colors.amber.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isPro ? Colors.amber : Colors.grey.shade400),
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
                        isPro
                            ? AppStrings.tr(AppStrings.subProActive, lc)
                            : AppStrings.tr(AppStrings.subFree,
                                lc), // Could translate active status directly if needed or keep simple
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

  Widget _buildSubscriptionTile(
      BuildContext context, WidgetRef ref, bool isPro, String lc) {
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
        title: Text(AppStrings.tr(AppStrings.subStatus, lc),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(isPro
            ? AppStrings.tr(AppStrings.subProActive, lc)
            : AppStrings.tr(AppStrings.subFree, lc)),
        trailing: ElevatedButton(
          onPressed: () {
            if (isPro) {
              url_launcher.launchUrl(
                Uri.parse('https://apps.apple.com/account/subscriptions'),
                mode: url_launcher.LaunchMode.externalApplication,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionPage()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isPro ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child:
              Text(isPro ? 'Yönet' : AppStrings.tr(AppStrings.btnUpgrade, lc)),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, WidgetRef ref, LanguageState language, String lc) {
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
        title: Text(AppStrings.tr(AppStrings.langTitle, lc),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${language.flag} ${language.name}'),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          _showLanguageDialog(context, ref, lc);
        },
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap}) {
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
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
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
            child: Row(children: [
              const Text('🇹🇷'),
              const SizedBox(width: 12),
              Text(AppStrings.tr(AppStrings.langTurkish, lc))
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(languageProvider.notifier).setLanguage('en');
              Navigator.pop(ctx);
            },
            child: Row(children: [
              const Text('🇺🇸'),
              const SizedBox(width: 12),
              Text(AppStrings.tr(AppStrings.langEnglish, lc))
            ]),
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
            child: Row(children: [
              const Icon(Icons.wb_sunny_outlined),
              const SizedBox(width: 12),
              Text(AppStrings.tr(AppStrings.themeLight, lc))
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: Row(children: [
              const Icon(Icons.nightlight_outlined),
              const SizedBox(width: 12),
              Text(AppStrings.tr(AppStrings.themeDark, lc))
            ]),
          ),
        ],
      ),
    );
  }
}
