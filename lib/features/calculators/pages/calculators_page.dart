import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/calculators/pages/real_estate_calculator_page.dart';
import 'package:invest_guide/features/calculators/pages/investment_comparison_page.dart';
import 'package:invest_guide/features/calculators/pages/simple_calculator_page.dart';
import 'package:invest_guide/features/calculators/pages/loan_kmh_calculator_page.dart';
import 'package:invest_guide/features/calculators/pages/credit_card_assistant_page.dart';
import 'package:invest_guide/features/calculators/pages/compound_interest_page.dart';
import 'package:invest_guide/features/subscription/presentation/widgets/pro_feature_gate.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class CalculatorsPage extends ConsumerWidget {
  const CalculatorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface(context),
        title: Text(
          AppStrings.tr(AppStrings.calculatorTools, lc),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.textPrimary(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border(context),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.tr(AppStrings.investTools, lc),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),

            // Yatırım Getirisi Simülatörü (Bileşik Faiz)
            _buildCalculatorCard(
              context,
              title: AppStrings.tr(AppStrings.investmentReturnsSim, lc),
              description:
                  AppStrings.tr(AppStrings.investmentReturnsSimDesc, lc),
              icon: Icons.trending_up,
              color: AppColors.success,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompoundInterestPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Gayrimenkul Kira Çarpanı
            _buildCalculatorCard(
              context,
              title: AppStrings.tr(AppStrings.realEstateCalculator, lc),
              description:
                  AppStrings.tr(AppStrings.realEstateCalculatorDesc, lc),
              icon: Icons.home_work_outlined,
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RealEstateCalculatorPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Yatırım Karşılaştırma Simülatörü
            ProFeatureGate(
              featureName: 'Yatırım Karşılaştırma',
              lockedChild: _buildCalculatorCard(
                context,
                title: AppStrings.tr(AppStrings.investmentComparison, lc),
                description:
                    AppStrings.tr(AppStrings.investmentComparisonDesc, lc),
                icon: Icons.lock_outline,
                color: Colors.grey,
                onTap: () {
                  ProFeatureGate.showUpsell(context,
                      AppStrings.tr(AppStrings.investmentComparison, lc));
                },
              ),
              child: _buildCalculatorCard(
                context,
                title: AppStrings.tr(AppStrings.investmentComparison, lc),
                description:
                    AppStrings.tr(AppStrings.investmentComparisonDesc, lc),
                icon: Icons.history_edu,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvestmentComparisonPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            Text(
              AppStrings.tr(AppStrings.generalTools, lc),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),

            // Kredi & Mevduat (Vergi/KMH)
            _buildCalculatorCard(
              context,
              title: AppStrings.tr(AppStrings.toolLoan, lc),
              description: AppStrings.tr(AppStrings.toolLoanDesc, lc),
              icon: Icons.calculate_outlined,
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoanKmhCalculatorPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Kredi Kartı Asistanı
            _buildCalculatorCard(
              context,
              title: AppStrings.tr(AppStrings.toolCreditCard, lc),
              description: AppStrings.tr(AppStrings.toolCreditCardDesc, lc),
              icon: Icons.credit_card,
              color: AppColors.error,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreditCardAssistantPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Hesap Makinesi
            _buildCalculatorCard(
              context,
              title: AppStrings.tr(AppStrings.simpleCalculator, lc),
              description: AppStrings.tr(AppStrings.simpleCalculatorDesc, lc),
              icon: Icons.exposure_outlined,
              color: AppColors.textSecondary(context),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimpleCalculatorPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: AppColors.shadowSm(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
