import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/constants/colors.dart';

class WalletSelector extends ConsumerWidget {
  final DateTime selectedDate;
  final bool isYearlyView;
  final Function(DateTime) onDateChanged;

  const WalletSelector({
    super.key,
    required this.selectedDate,
    required this.isYearlyView,
    required this.onDateChanged,
  });

  String _getMonthName(int month, String lc) {
    final months = [
      AppStrings.tr(AppStrings.monthJan, lc),
      AppStrings.tr(AppStrings.monthFeb, lc),
      AppStrings.tr(AppStrings.monthMar, lc),
      AppStrings.tr(AppStrings.monthApr, lc),
      AppStrings.tr(AppStrings.monthMay, lc),
      AppStrings.tr(AppStrings.monthJun, lc),
      AppStrings.tr(AppStrings.monthJul, lc),
      AppStrings.tr(AppStrings.monthAug, lc),
      AppStrings.tr(AppStrings.monthSep, lc),
      AppStrings.tr(AppStrings.monthOct, lc),
      AppStrings.tr(AppStrings.monthNov, lc),
      AppStrings.tr(AppStrings.monthDec, lc),
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    
    final title = isYearlyView 
        ? '${selectedDate.year} ${AppStrings.tr(AppStrings.yearly, lc)}'
        : '${_getMonthName(selectedDate.month, lc)} ${selectedDate.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            onPressed: () {
              if (isYearlyView) {
                onDateChanged(DateTime(selectedDate.year - 1, selectedDate.month));
              } else {
                onDateChanged(DateTime(selectedDate.year, selectedDate.month - 1));
              }
            },
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () {
              if (isYearlyView) {
                onDateChanged(DateTime(selectedDate.year + 1, selectedDate.month));
              } else {
                onDateChanged(DateTime(selectedDate.year, selectedDate.month + 1));
              }
            },
          ),
        ],
      ),
    );
  }
}
