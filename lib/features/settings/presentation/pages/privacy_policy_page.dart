import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

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
                  ? 'Hesap ve finans kayıtları aktarım sırasında TLS ile, sunucu tarafında Supabase güvenlik kontrolleri ve satır bazlı erişim kurallarıyla korunur.'
                  : 'Account and financial records are protected in transit with TLS and on the server with Supabase security controls and row-level access rules.',
              icon: Icons.security,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'Veri Kullanımı' : 'Data Usage',
              content: lc == 'tr'
                  ? 'Gelir/gider, hesap ve desteklenen portföy kayıtları hesap işlevleri için Supabase ile eşitlenebilir. Birikim, BES ve geri ödemeli hayat sigortası planları bu sürümde cihazda kullanıcıya özel yerel alanda tutulur. İsteğe bağlı profil alanları, kullanıcı kimliğine bağlı özellik kullanım olayları ve bildirimleri açarsanız APNs cihaz tokenı da işlenebilir. AI özelliğini açık onayla kullandığınızda seçtiğiniz finansal özet, ekstre veya e-posta içeriği MoneyPlan Pro backend’i ve Google Gemini tarafından analiz edilir. Gmail bağlantısı isteğe bağlıdır. Veriler uygulamalar arası takip veya davranışsal reklam için kullanılmaz.'
                  : 'Transactions, accounts, and supported portfolio records may sync with Supabase for account features. Savings, private-pension, and return-of-premium life-insurance plans are stored on-device in user-scoped local storage in this release. Optional profile fields, account-linked usage events, and an APNs token if notifications are enabled may also be processed. With explicit AI consent, selected financial summaries, statements, or email content are analyzed by the MoneyPlan Pro backend and Google Gemini. Gmail access is optional. Data is not used for cross-app tracking or behavioral advertising.',
              icon: Icons.data_usage,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'Hesap Silme' : 'Account Deletion',
              content: lc == 'tr'
                  ? 'Profil > Hesabı ve Verileri Sil yolundan Auth hesabınızı ve ilişkili bulut finans verilerinizi kalıcı olarak silebilirsiniz. Cihazdaki yerel finans ve giriş verileri de temizlenir. App Store aboneliği ayrıca Apple hesabından iptal edilmelidir.'
                  : 'Use Profile > Delete Account and Data to permanently delete your Auth account and associated cloud financial data. Local financial and sign-in data is also cleared. An App Store subscription must be canceled separately through Apple.',
              icon: Icons.delete_forever,
            ),
            _buildSection(
              context,
              title: lc == 'tr' ? 'İletişim' : 'Contact',
              content: 'trgy.ycl@gmail.com',
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
