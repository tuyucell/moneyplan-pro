import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AiPrivacyConsentService {
  static const _consentKey = 'ai_data_processing_consent_v1';

  static Future<bool> ensureConsent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_consentKey) == true) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shield_outlined, size: 40),
        title: const Text('AI Veri İşleme Onayı'),
        content: const Text(
          'Bu özelliği kullandığında seçtiğin finansal özet, ekstre veya '
          'e-posta içeriği analiz için MoneyPlan Pro sunucusuna ve Google '
          'Gemini hizmetine gönderilir. Ücretsiz Gemini katmanında gönderilen '
          'içerik Google ürünlerini geliştirmek için kullanılabilir. '
          'AI çıktısını kullanmadan önce mutlaka kontrol et.',
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://moneyplan.pro/privacy.html'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Gizlilik Politikası'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kabul Et ve Devam Et'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await prefs.setBool(_consentKey, true);
      return true;
    }
    return false;
  }
}
