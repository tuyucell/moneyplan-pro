import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import 'package:invest_guide/features/subscription/presentation/widgets/pro_feature_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/wallet/pages/email_sync_page.dart';

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
      ),
      body: GridView.count(
        padding: context.adaptivePadding, // Use adaptive padding
        crossAxisCount: context.isTablet ? 3 : 2, // 3 columns on tablet
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: context.isTablet ? 1.1 : 0.9, // Adjust aspect ratio for better look on tablet
        children: [
          _buildToolCard(
            context,
            icon: Icons.trending_up,
            title: AppStrings.tr(AppStrings.toolCompound, lc),
            subtitle: AppStrings.tr(AppStrings.toolCompoundDesc, lc),
            color: AppColors.primary,
            onTap: () => context.push('/tools/compound_interest'),
          ),
          _buildToolCard(
            context,
            icon: Icons.calculate_outlined,
            title: AppStrings.tr(AppStrings.toolLoan, lc),
            subtitle: AppStrings.tr(AppStrings.toolLoanDesc, lc),
            color: AppColors.primary,
            onTap: () => context.push('/tools/loan_kmh'),
          ),
          _buildToolCard(
            context,
            icon: Icons.credit_card,
            title: AppStrings.tr(AppStrings.toolCreditCard, lc),
            subtitle: AppStrings.tr(AppStrings.toolCreditCardDesc, lc),
            color: AppColors.error,
            onTap: () => context.push('/tools/credit_card_assistant'),
          ),
          _buildToolCard(
            context,
            icon: Icons.elderly,
            title: AppStrings.tr(AppStrings.toolRetirement, lc),
            subtitle: AppStrings.tr(AppStrings.toolRetirementDesc, lc),
            color: Colors.purple,
            onTap: () => context.push('/tools/retirement'),
          ),
          _buildToolCard(
            context,
            icon: Icons.insights,
            title: 'Yatırım Asistanı',
            subtitle: 'Risk & Getiri Analizi',
            color: Colors.orange,
            onTap: () => context.push('/investment_wizard'),
          ),
          ProFeatureGate(
            featureName: 'Gelecek Simülasyonu',
            // LOCKED STATE
            lockedChild: _buildToolCard(
              context,
              icon: Icons.lock_outline,
              title: 'Gelecek Simülasyonu',
              subtitle: 'Pro Özellik',
              color: Colors.grey,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('🌟 Pro\'ya Yükselt'),
                    content: const Text(
                        'Gelecek simülasyonunu kullanmak için Pro\'ya geçin.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Kapat')),
                    ],
                  ),
                );
              },
            ),
            // UNLOCKED STATE
            child: _buildToolCard(
              context,
              icon: Icons.auto_graph_outlined,
              title: 'Gelecek Simülasyonu',
              subtitle: 'Finansal İkiziniz',
              color: Colors.indigo,
              onTap: () => context.push('/tools/scenario_planner'),
            ),
          ),
          _buildToolCard(
            context,
            icon: Icons.mark_email_unread_outlined,
            title: 'E-posta Otomasyonu',
            subtitle: 'AI ile Veri Çekme',
            color: Colors.blueAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmailSyncPage()),
              );
            },
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.shadowSm(context),
            border: Border.all(color: AppColors.border(context)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.adaptiveSp(16),
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.adaptiveSp(12),
                  color: AppColors.textSecondary(context),
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
