import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lc = ref.watch(languageProvider).code;

    return Scaffold(
      appBar: AppBar(
        title: Text(lc == 'tr' ? 'Gizlilik ve Güvenlik' : 'Privacy & Security'),
        backgroundColor: AppColors.background(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: lc == 'tr'
                  ? 'Veri Güvenliği (KVKK/GDPR)'
                  : 'Data Security (GDPR/KVKK)',
              content: lc == 'tr'
                  ? 'Kişisel verileriniz KVKK ve GDPR standartlarına uygun olarak korunmaktadır. Verileriniz uçtan uca şifreleme yöntemleri ile saklanır.'
                  : 'Your personal data is protected in accordance with GDPR and KVKK standards. Your data is stored using end-to-end encryption methods.',
              icon: Icons.security,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'Veri Kullanımı' : 'Data Usage',
              content: lc == 'tr'
                  ? 'Finansal verileriniz sadece size özel analizler sunmak için kullanılır ve üçüncü taraflarla paylaşılmaz.'
                  : 'Your financial data is used only to provide you with personalized analysis and is not shared with third parties.',
              icon: Icons.data_usage,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'Hesap Silme' : 'Account Deletion',
              content: lc == 'tr'
                  ? 'Hesabınızı ve tüm verilerinizi istediğiniz zaman Profil ayarlarından silebilirsiniz.'
                  : 'You can delete your account and all your data at any time from Profile settings.',
              icon: Icons.delete_forever,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'İletişim' : 'Contact',
              content: 'support@moneyplanpro.com',
              icon: Icons.email,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'MoneyPlan Pro v1.0.0',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title,
      required String content,
      required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
