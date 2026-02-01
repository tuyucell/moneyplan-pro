import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/shared/widgets/economic_calendar_widget.dart';

class EconomicCalendarPage extends ConsumerStatefulWidget {
  const EconomicCalendarPage({super.key});

  @override
  ConsumerState<EconomicCalendarPage> createState() =>
      _EconomicCalendarPageState();
}

class _EconomicCalendarPageState extends ConsumerState<EconomicCalendarPage> {
  String _selectedImpact = 'All';

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final calendarAsync = ref.watch(calendarDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          AppStrings.tr(AppStrings.economicCalendar, lc),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(context, lc),
          Expanded(
            child: calendarAsync.when(
              data: (events) {
                final filteredEvents = _filterEvents(events);
                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 48,
                            color: AppColors.textSecondary(context)
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.tr(AppStrings.noDataFound, lc),
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final data = filteredEvents[index];
                    return _CalendarListItem(data: data, lc: lc);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(AppStrings.tr(AppStrings.chartLoadError, lc)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, String lc) {
    final impacts = ['All', 'High', 'Medium', 'Low'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: impacts.length,
        itemBuilder: (context, index) {
          final impact = impacts[index];
          final isSelected = _selectedImpact == impact;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                impact == 'All' ? AppStrings.tr(AppStrings.tabAll, lc) : impact,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedImpact = impact);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border(context)),
              ),
            ),
          );
        },
      ),
    );
  }

  List<dynamic> _filterEvents(List<dynamic> events) {
    if (_selectedImpact == 'All') return events;
    return events
        .where((e) =>
            e['impact'].toString().toLowerCase() ==
            _selectedImpact.toLowerCase())
        .toList();
  }
}

class _CalendarListItem extends StatelessWidget {
  final dynamic data;
  final String lc;

  const _CalendarListItem({required this.data, required this.lc});

  @override
  Widget build(BuildContext context) {
    final impact = data['impact'] ?? 'Medium';
    final actual = data['actual'] ?? '';
    final forecast = data['forecast'] ?? '';
    final previous = data['previous'] ?? '';
    final unit = data['unit'] ?? '';

    Color impactColor;
    switch (impact.toString().toLowerCase()) {
      case 'critical':
      case 'high':
        impactColor = Colors.red;
        break;
      case 'medium':
        impactColor = Colors.orange;
        break;
      default:
        impactColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (data['flag_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Image.network(
                          data['flag_url'],
                          width: 16,
                          height: 11,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(width: 16),
                        ),
                      ),
                    ),
                  Text(
                    data['currency'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data['date']} • ${data['time']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: impactColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getLocalizedImpact(impact, lc),
                  style: TextStyle(
                      color: impactColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCompactValue(context,
                        AppStrings.tr(AppStrings.actualLabel, lc), actual, unit,
                        isActual: true),
                    const SizedBox(width: 12),
                    _buildCompactValue(
                        context,
                        AppStrings.tr(AppStrings.forecastLabel, lc),
                        forecast,
                        unit),
                    const SizedBox(width: 12),
                    _buildCompactValue(
                        context,
                        AppStrings.tr(AppStrings.previousLabel, lc),
                        previous,
                        unit),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactValue(
      BuildContext context, String label, String value, String unit,
      {bool isActual = false}) {
    final displayValue =
        (value == '' || value == 'null' || value == '-') ? '-' : '$value$unit';
    final isNegative = value.startsWith('-');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label.substring(0, 3).toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary(context).withValues(alpha: 0.5),
            letterSpacing: 0.2,
          ),
        ),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActual && displayValue != '-'
                ? (isNegative ? Colors.red : AppColors.success)
                : AppColors.textPrimary(context),
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
}
