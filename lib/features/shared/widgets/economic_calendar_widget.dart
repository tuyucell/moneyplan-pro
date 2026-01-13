import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/services/api/invest_guide_api.dart';

final calendarDataProvider = FutureProvider<List<dynamic>>((ref) async {
  return InvestGuideApi.getEconomicCalendar();
});

class EconomicCalendarWidget extends ConsumerWidget {
  const EconomicCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final calendarAsync = ref.watch(calendarDataProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr(AppStrings.economicCalendar, lc),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.tr(AppStrings.thisWeek, lc),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: calendarAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    AppStrings.tr(AppStrings.insufficientData, lc),
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final data = events[index];
                  final event = _Event(
                    date: data['date'] ?? '',
                    time: data['time'] ?? '',
                    title: data['title'] ?? '',
                    impact: data['impact'] ?? 'Medium',
                    impactLabel:
                        _getLocalizedImpact(data['impact'] ?? 'Medium', lc),
                    currency: data['currency'] ?? 'USD',
                  );
                  return _buildEventCard(context, event);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                AppStrings.tr(AppStrings.chartLoadError, lc),
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedImpact(String impact, String lc) {
    switch (impact.toLowerCase()) {
      case 'critical':
        return AppStrings.tr(AppStrings.impactCritical, lc);
      case 'high':
        return AppStrings.tr(AppStrings.impactHigh, lc);
      case 'medium':
        return AppStrings.tr(AppStrings.impactMedium, lc);
      default:
        return impact;
    }
  }

  Widget _buildEventCard(BuildContext context, _Event event) {
    Color impactColor;
    switch (event.impact) {
      case 'Critical':
        impactColor = Colors.red;
        break;
      case 'High':
        impactColor = Colors.orange;
        break;
      case 'Medium':
        impactColor = Colors.blue;
        break;
      default:
        impactColor = Colors.grey;
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  event.currency,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.impactLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: impactColor),
                ),
              ),
            ],
          ),
          Text(
            event.title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
                height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 12, color: AppColors.textSecondary(context)),
              const SizedBox(width: 4),
              Text(
                '${event.date}${event.date.isNotEmpty ? ' • ' : ''}${event.time}',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Event {
  final String date;
  final String time;
  final String title;
  final String impact;
  final String impactLabel;
  final String currency;

  _Event(
      {required this.date,
      required this.time,
      required this.title,
      required this.impact,
      required this.impactLabel,
      required this.currency});
}
