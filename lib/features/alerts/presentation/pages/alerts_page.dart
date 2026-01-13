import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/alerts/providers/alerts_provider.dart';
import 'package:invest_guide/features/watchlist/providers/asset_cache_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(AppStrings.tr(AppStrings.priceAlertsTitle, lc), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        foregroundColor: AppColors.textPrimary(context),
      ),
      body: alerts.isEmpty
          ? _buildEmptyState(context, lc)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(context, ref, alert, lc);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textTertiary(context)),
          const SizedBox(height: 16),
          Text(
            AppStrings.tr(AppStrings.noAlertsYet, lc),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tr(AppStrings.noAlertsDesc, lc),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WidgetRef ref, dynamic alert, String lc) {
    final assetAsync = ref.watch(assetProvider(alert.assetId));
    final currentPrice = assetAsync.value?.currentPriceUsd;
    
    var isTriggered = false;
    if (currentPrice != null) {
      if (alert.isAbove && currentPrice >= alert.targetPrice) isTriggered = true;
      if (!alert.isAbove && currentPrice <= alert.targetPrice) isTriggered = true;
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(alertsProvider.notifier).removeAlert(alert.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.tr(AppStrings.alertDeleted, lc))),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTriggered ? AppColors.success : AppColors.border(context),
            width: isTriggered ? 2 : 1, 
          ),
          boxShadow: AppColors.shadowSm(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                alert.isAbove ? Icons.trending_up : Icons.trending_down,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      Switch(
                        value: alert.isActive, 
                        onChanged: (val) {
                          ref.read(alertsProvider.notifier).toggleAlert(alert.id, val);
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  Text(
                    '${AppStrings.tr(AppStrings.targetPriceLabel, lc)}: \$${alert.targetPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${AppStrings.tr(AppStrings.currentPriceShort, lc)}: ${currentPrice != null ? '\$${currentPrice.toStringAsFixed(2)}' : AppStrings.tr(AppStrings.loading, lc)}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                      ),
                      if (isTriggered && alert.isActive) 
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            AppStrings.tr(AppStrings.triggeredLabel, lc),
                            style: const TextStyle(
                               color: AppColors.success, 
                               fontWeight: FontWeight.bold, 
                               fontSize: 12
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
