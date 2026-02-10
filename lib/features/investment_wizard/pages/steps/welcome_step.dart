import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';

class WelcomeStep extends ConsumerWidget {
  final VoidCallback onNext;

  const WelcomeStep({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return SingleChildScrollView(
      padding: context.adaptivePadding, // Use adaptive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.welcomeInvestTitle, lc),
            style: TextStyle(
              fontSize: context.adaptiveSp(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.tr(AppStrings.welcomeInvestDesc, lc),
            style: TextStyle(
              fontSize: context.adaptiveSp(16),
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),

          InvestmentInfoCard(
            icon: Icons.trending_up,
            title: AppStrings.tr(AppStrings.whyInvestTitle, lc),
            description: AppStrings.tr(AppStrings.whyInvestDesc, lc),
          ),
          const SizedBox(height: 16),

          InvestmentInfoCard(
            icon: Icons.savings,
            title: AppStrings.tr(AppStrings.startEarlyTitle, lc),
            description: AppStrings.tr(AppStrings.startEarlyDesc, lc),
          ),
          const SizedBox(height: 16),

          InvestmentInfoCard(
            icon: Icons.diversity_3,
            title: AppStrings.tr(AppStrings.diversificationTitle, lc),
            description: AppStrings.tr(AppStrings.diversificationDesc, lc),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.tr(AppStrings.letsStartBtn, lc),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
