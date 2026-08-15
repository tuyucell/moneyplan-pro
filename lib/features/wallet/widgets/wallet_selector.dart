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

    final now = DateTime.now();
    final isCurrentPeriod = isYearlyView
        ? selectedDate.year == now.year
        : selectedDate.year == now.year && selectedDate.month == now.month;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: lc == 'tr' ? 'Önceki dönem' : 'Previous period',
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () {
                  if (isYearlyView) {
                    onDateChanged(
                        DateTime(selectedDate.year - 1, selectedDate.month));
                  } else {
                    onDateChanged(
                        DateTime(selectedDate.year, selectedDate.month - 1));
                  }
                },
              ),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              IconButton(
                tooltip: lc == 'tr' ? 'Sonraki dönem' : 'Next period',
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: () {
                  if (isYearlyView) {
                    onDateChanged(
                        DateTime(selectedDate.year + 1, selectedDate.month));
                  } else {
                    onDateChanged(
                        DateTime(selectedDate.year, selectedDate.month + 1));
                  }
                },
              ),
            ],
          ),
          if (!isCurrentPeriod)
            TextButton.icon(
              key: const Key('wallet-current-period-button'),
              onPressed: () => onDateChanged(now),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.my_location_rounded, size: 13),
              label: Text(
                isYearlyView
                    ? (lc == 'tr' ? 'Bu yıla dön' : 'Back to this year')
                    : (lc == 'tr' ? 'Bu aya dön' : 'Back to this month'),
              ),
            ),
        ],
      ),
    );
  }
}
