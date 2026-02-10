import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/alerts/providers/alerts_provider.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:moneyplan_pro/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/auth/data/models/user_model.dart';

import 'package:moneyplan_pro/features/alerts/presentation/pages/alerts_page.dart';

class NotificationBadgeIcon extends ConsumerWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final activeCount = alerts.where((a) => a.isActive).length;
    final lc = ref.watch(languageProvider).code;

    return Stack(
      children: [
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
        if (activeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.surface(context), width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                activeCount > 9 ? '9+' : '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
