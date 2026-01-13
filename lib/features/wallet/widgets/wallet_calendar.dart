import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/colors.dart';
import '../models/transaction_category.dart';
import '../models/wallet_transaction.dart';
import '../providers/wallet_provider.dart';

class WalletCalendar extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(DateTime, List<WalletTransaction>, List<WalletTransaction>) onShowTransactions;

  const WalletCalendar({
    super.key,
    required this.selectedDate,
    required this.focusedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onShowTransactions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(walletProvider); // Rebuild on changes
    final walletNotifier = ref.read(walletProvider.notifier);
    final transactions = walletNotifier.getTransactionsByMonth(
      focusedDay.year,
      focusedDay.month,
    );

    final transactionDateEvents = <DateTime, List<WalletTransaction>>{};
    final dueDateEvents = <DateTime, List<WalletTransaction>>{};

    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      final shouldShowAsTransactionEvent = transaction.type == TransactionType.income || transaction.dueDate == null;

      if (shouldShowAsTransactionEvent) {
        if (transactionDateEvents[transactionDate] == null) {
          transactionDateEvents[transactionDate] = [];
        }
        transactionDateEvents[transactionDate]!.add(transaction);
      }

      if (transaction.dueDate != null) {
        final dueDate = DateTime(
          transaction.dueDate!.year,
          transaction.dueDate!.month,
          transaction.dueDate!.day,
        );
        if (dueDateEvents[dueDate] == null) {
          dueDateEvents[dueDate] = [];
        }
        dueDateEvents[dueDate]!.add(transaction);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'tr_TR',
            headerVisible: false,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              outsideDaysVisible: false,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final allEvents = <WalletTransaction>[];
              allEvents.addAll(transactionDateEvents[normalizedDay] ?? []);
              allEvents.addAll(dueDateEvents[normalizedDay] ?? []);
              return allEvents;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                final normalizedDay = DateTime(day.year, day.month, day.day);
                final dayTransactionDates = transactionDateEvents[normalizedDay] ?? [];
                final dayDueDates = dueDateEvents[normalizedDay] ?? [];

                final markers = <Widget>[];

                if (dayTransactionDates.isNotEmpty) {
                  final hasIncome = dayTransactionDates.any((t) => t.type == TransactionType.income);
                  final hasExpense = dayTransactionDates.any((t) => t.type == TransactionType.expense);

                  if (hasIncome) {
                    markers.add(_buildMarkerIndicator(AppColors.success));
                  }
                  if (hasExpense) {
                    markers.add(_buildMarkerIndicator(AppColors.error.withValues(alpha: 0.7)));
                  }
                }

                if (dayDueDates.isNotEmpty) {
                  final hasOverdue = dayDueDates.any((t) => t.isOverdue);
                  markers.add(_buildMarkerIndicator(hasOverdue ? AppColors.error : AppColors.warning));
                }

                if (markers.isEmpty) return null;

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: markers,
                  ),
                );
              },
            ),
            onDaySelected: (selDay, focDay) {
              onDaySelected(selDay, focDay);
              
              final normalizedDay = DateTime(selDay.year, selDay.month, selDay.day);
              final dayTransactionDates = transactionDateEvents[normalizedDay] ?? [];
              final dayDueDates = dueDateEvents[normalizedDay] ?? [];

              if (dayTransactionDates.isNotEmpty || dayDueDates.isNotEmpty) {
                onShowTransactions(selDay, dayTransactionDates, dayDueDates);
              }
            },
            onPageChanged: onPageChanged,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _CalendarLegend(label: 'Gelir', color: AppColors.success),
                    const SizedBox(width: 16),
                    _CalendarLegend(label: 'Gider', color: AppColors.error.withValues(alpha: 0.7)),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CalendarLegend(label: 'Vade Tarihi', color: AppColors.warning),
                    SizedBox(width: 16),
                    _CalendarLegend(label: 'Gecikmiş', color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerIndicator(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 0.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _CalendarLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
