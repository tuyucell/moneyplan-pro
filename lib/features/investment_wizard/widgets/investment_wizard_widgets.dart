import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

/// Info card widget for displaying icon, title and description
class InvestmentInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InvestmentInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    height: 1.4,
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

/// Currency input field with formatting
class InvestmentInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? suffix;
  final Function(String) onChanged;

  const InvestmentInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (value) {
            var digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
            onChanged(digitsOnly);
          },
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Choice button for yes/no selections
class InvestmentChoiceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const InvestmentChoiceButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(context),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary(context),
            ),
          ),
        ),
      ),
    );
  }
}

class InvestmentProjectionCard extends ConsumerWidget {
  final String period;
  final Map<String, dynamic> values;
  final NumberFormat numberFormat;
  final String currencySymbol;

  final String selectedProfile;
  final Function(String) onProfileSelected;

  const InvestmentProjectionCard({
    super.key,
    required this.period,
    required this.values,
    required this.numberFormat,
    required this.selectedProfile,
    required this.onProfileSelected,
    this.currencySymbol = '₺',
  });

  String _formatCurrency(double amount) {
    return numberFormat.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double totalInvested = values['totalInvested'];
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${AppStrings.tr(AppStrings.totalInvestedLabel, lc).replaceAll(RegExp(r'[:₺\$]'), '').trim()}: ${_formatCurrency(totalInvested)} $currencySymbol',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProjectionRow(
            label:
                '${AppStrings.tr(AppStrings.conservativePlan, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %3)',
            value: values['conservative'] as double,
            totalInvested: totalInvested,
            color: AppColors.success,
            formatter: _formatCurrency,
            currencySymbol: currencySymbol,
            isSelected: selectedProfile == 'muhafazakar' ||
                selectedProfile == 'starter',
            onTap: () => onProfileSelected('muhafazakar'),
          ),
          const SizedBox(height: 12),
          _ProjectionRow(
            label:
                '${AppStrings.tr(AppStrings.balancedPlan, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %6)',
            value: values['moderate'] as double,
            totalInvested: totalInvested,
            color: AppColors.warning,
            formatter: _formatCurrency,
            currencySymbol: currencySymbol,
            isSelected:
                selectedProfile == 'dengeli' || selectedProfile == 'balanced',
            onTap: () => onProfileSelected('dengeli'),
          ),
          const SizedBox(height: 12),
          _ProjectionRow(
            label:
                '${AppStrings.tr(AppStrings.aggressivePlan, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %9)',
            value: values['aggressive'] as double,
            totalInvested: totalInvested,
            color: AppColors.error,
            formatter: _formatCurrency,
            currencySymbol: currencySymbol,
            isSelected:
                selectedProfile == 'agresif' || selectedProfile == 'aggressive',
            onTap: () => onProfileSelected('agresif'),
          ),
        ],
      ),
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String label;
  final double value;
  final double totalInvested;
  final Color color;
  final String Function(double) formatter;
  final String currencySymbol;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectionRow({
    required this.label,
    required this.value,
    required this.totalInvested,
    required this.color,
    required this.formatter,
    required this.currencySymbol,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profit = value - totalInvested;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.textPrimary(context)
                          : AppColors.textSecondary(context),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+${formatter(profit)} $currencySymbol',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${formatter(value)} $currencySymbol',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Allocation bar showing investment distribution
class InvestmentAllocationBar extends StatelessWidget {
  final String label;
  final int percentage;

  const InvestmentAllocationBar({
    super.key,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
