import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';

class DuplicatePreventionInfo extends StatelessWidget {
  const DuplicatePreventionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Çift Kayıt Önleme Sistemi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            context,
            icon: Icons.money_off,
            title: 'Nakit Ödemeler',
            description: 'Manuel ekleyin. Bakiyenize dahil edilir.',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            context,
            icon: Icons.credit_card,
            title: 'Kart Ödemeleri',
            description:
                'Gmail/Outlook\'tan otomatik gelir. Bakiyenize dahil edilir.',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            context,
            icon: Icons.receipt_long,
            title: 'Fatura/Abonelikler (Karttan)',
            description:
                'Hatırlatıcı olarak gösterilir. Bakiyenize dahil EDİLMEZ (Kart ekstresinde zaten var).',
            isWarning: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isWarning
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isWarning ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
