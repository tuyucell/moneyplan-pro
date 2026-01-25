import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import 'package:invest_guide/features/subscription/presentation/widgets/pro_feature_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/wallet/pages/email_sync_page.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:invest_guide/features/alerts/presentation/pages/alerts_page.dart';

class ToolsPage extends ConsumerWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          AppStrings.tr(AppStrings.pageTools, lc),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        foregroundColor: AppColors.textPrimary(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.primary),
            onPressed: () {
              final authState = ref.read(authNotifierProvider);
              if (authState is AuthAuthenticated) {
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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: context.isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: context.isTablet ? 1.2 : 1.0,
        children: [
          // 1. Yatırım Asistanı (Pro)
          ProFeatureGate(
            featureName: 'Yatırım Asistanı',
            lockedChild: _buildToolCard(
              context,
              icon: Icons.lock_outline,
              title: 'Yatırım Asistanı',
              subtitle: 'Pro Özellik',
              color: Colors.grey,
              onTap: () =>
                  ProFeatureGate.showUpsell(context, 'Yatırım Asistanı'),
            ),
            child: _buildToolCard(
              context,
              icon: Icons.insights,
              title: 'Yatırım Asistanı',
              subtitle: 'Risk & Getiri Analizi',
              color: Colors.orange,
              onTap: () => context.push('/investment_wizard'),
            ),
          ),

          // 2. Gelecek Simülasyonu (Pro)
          ProFeatureGate(
            featureName: 'Gelecek Simülasyonu',
            lockedChild: _buildToolCard(
              context,
              icon: Icons.lock_outline,
              title: 'Gelecek Simülasyonu',
              subtitle: 'Pro Özellik',
              color: Colors.grey,
              onTap: () =>
                  ProFeatureGate.showUpsell(context, 'Gelecek Simülasyonu'),
            ),
            child: _buildToolCard(
              context,
              icon: Icons.auto_graph_outlined,
              title: 'Gelecek Simülasyonu',
              subtitle: 'Finansal İkiziniz',
              color: Colors.indigo,
              onTap: () => context.push('/tools/scenario_planner'),
            ),
          ),

          // 3. Bileşik Faiz
          _buildToolCard(
            context,
            icon: Icons.trending_up,
            title: AppStrings.tr(AppStrings.toolCompound, lc),
            subtitle: AppStrings.tr(AppStrings.toolCompoundDesc, lc),
            color: AppColors.primary,
            onTap: () => context.push('/tools/compound_interest'),
          ),

          // 4. E-posta Otomasyonu (Pro)
          ProFeatureGate(
            featureName: 'E-posta Otomasyonu',
            lockedChild: _buildToolCard(
              context,
              icon: Icons.lock_outline,
              title: 'E-posta Otomasyonu',
              subtitle: 'Pro Özellik',
              color: Colors.grey,
              onTap: () =>
                  ProFeatureGate.showUpsell(context, 'E-posta Otomasyonu'),
            ),
            child: _buildToolCard(
              context,
              icon: Icons.mark_email_unread_outlined,
              title: 'E-posta Otomasyonu',
              subtitle: 'AI ile Veri Çekme',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmailSyncPage()),
                );
              },
            ),
          ),

          // 5. Kredi & Mevduat
          _buildToolCard(
            context,
            icon: Icons.calculate_outlined,
            title: AppStrings.tr(AppStrings.toolLoan, lc),
            subtitle: AppStrings.tr(AppStrings.toolLoanDesc, lc),
            color: AppColors.primary,
            onTap: () => context.push('/tools/loan_kmh'),
          ),

          // 6. Kredi Kartı Asistanı
          _buildToolCard(
            context,
            icon: Icons.credit_card,
            title: AppStrings.tr(AppStrings.toolCreditCard, lc),
            subtitle: AppStrings.tr(AppStrings.toolCreditCardDesc, lc),
            color: AppColors.error,
            onTap: () => context.push('/tools/credit_card_assistant'),
          ),

          // 7. Satın Alma Asistanı (AI)
          _buildToolCard(
            context,
            icon: Icons.psychology,
            title: 'Satın Alma Asistanı',
            subtitle: 'Nakit mi Taksit mi?',
            color: Colors.deepPurple,
            onTap: () => context.push('/tools/purchase_assistant'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
