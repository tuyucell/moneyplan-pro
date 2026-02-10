import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/wallet/providers/portfolio_provider.dart';
import 'package:moneyplan_pro/features/watchlist/providers/asset_cache_provider.dart';
import 'package:moneyplan_pro/features/wallet/models/portfolio_asset.dart';
import 'package:moneyplan_pro/features/watchlist/widgets/sparkline_widget.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/asset_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/wallet/providers/bes_provider.dart';
import 'package:moneyplan_pro/core/services/currency_service.dart';

class PortfolioView extends ConsumerWidget {
  const PortfolioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final portfolioAssets = ref.watch(portfolioProvider);
    final besAccount = ref.watch(besProvider);

    if (portfolioAssets.isEmpty && besAccount == null) {
      return _buildEmptyState(context, lc);
    }

    final displayCurrency = ref.watch(investDisplayCurrencyProvider);

    return Column(
      children: [
        _buildSummaryCard(context, ref, portfolioAssets, lc, displayCurrency),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: portfolioAssets.length,
          itemBuilder: (context, index) {
            final asset = portfolioAssets[index];
            return _PortfolioItemCard(
              asset: asset,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetDetailPage(
                      assetId: asset.id,
                      symbol: asset.symbol,
                      name: asset.name,
                    ),
                  ),
                );
              },
              onLongPress: () => _showAssetOptions(context, ref, asset, lc),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref,
      List<PortfolioAsset> assets, String lc, String displayCurrency) {
    final currencyService = ref.watch(currencyServiceProvider);
    double totalValueTRY = 0;
    double totalCostTRY = 0;
    var allLoaded = true;

    for (final asset in assets) {
      final marketAsset = ref.watch(assetProvider(asset.id)).asData?.value;
      if (marketAsset != null && marketAsset.currentPriceUsd != null) {
        // Market asset price is in USD from API
        final currentValueUSD = marketAsset.currentPriceUsd! * asset.units;
        totalValueTRY += currencyService.convertToTRY(currentValueUSD, 'USD');

        // Asset average cost is in its own currency
        totalCostTRY += currencyService.convertToTRY(
            asset.units * asset.averageCost, asset.currencyCode);
      } else {
        allLoaded = false;
        totalCostTRY += currencyService.convertToTRY(
            asset.units * asset.averageCost, asset.currencyCode);
      }
    }

    // Convert TRY totals to Display Currency
    final totalValueDisplay =
        currencyService.convertFromTRY(totalValueTRY, displayCurrency);
    final totalCostDisplay =
        currencyService.convertFromTRY(totalCostTRY, displayCurrency);

    // Include BES (BES is always in TRY)
    final besAccount = ref.watch(besProvider);
    double besValueDisplay = 0;
    if (besAccount != null) {
      besValueDisplay = currencyService.convertFromTRY(
          besAccount.getTotalValue(), displayCurrency);
    }

    final finalTotalValueDisplay = totalValueDisplay + besValueDisplay;
    final profitDisplay =
        finalTotalValueDisplay - (allLoaded ? totalCostDisplay : 0);
    final profitPercent =
        totalCostDisplay > 0 ? (profitDisplay / totalCostDisplay) * 100 : 0.0;
    final isPositive = profitDisplay >= 0;

    final displayFormat = NumberFormat.currency(
        locale: displayCurrency == 'TRY' ? 'tr_TR' : 'en_US',
        symbol: currencyService.getSymbol(displayCurrency),
        decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tr(AppStrings.totalPortfolioValue, lc),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            allLoaded ? displayFormat.format(finalTotalValueDisplay) : '---',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryStat(
                  AppStrings.tr(AppStrings.totalProfitLoss, lc),
                  '${isPositive ? '+' : ''}${displayFormat.format(profitDisplay)} (${profitPercent.toStringAsFixed(2)}%)',
                  (isPositive ? Colors.green : Colors.red)
                      .withValues(alpha: 0.2)),
              const SizedBox(width: 12),
              _buildSummaryStat(
                  AppStrings.tr(AppStrings.assetCount, lc),
                  assets.length.toString(),
                  Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showAssetOptions(
      BuildContext context, WidgetRef ref, PortfolioAsset asset, String lc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    asset.symbol
                        .substring(0, math.min(2, asset.symbol.length))
                        .toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name.isNotEmpty ? asset.name : asset.symbol,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.grey900),
                    ),
                    Text(
                      '${asset.units} ${AppStrings.tr(AppStrings.unitsCount, lc)}',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildOptionTile(
              context,
              icon: Icons.edit,
              color: AppColors.primary,
              title: AppStrings.tr(AppStrings.edit, lc),
              subtitle: AppStrings.tr(AppStrings.updateAmountCost, lc),
              onTap: () {
                Navigator.pop(context);
                _showEditAssetDialog(context, ref, asset, lc);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.delete_outline,
              color: AppColors.error,
              title: AppStrings.tr(AppStrings.removePortfolio, lc),
              subtitle: AppStrings.tr(AppStrings.removeAssetInfo, lc),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, asset, lc);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      onTap: onTap,
    );
  }

  void _showEditAssetDialog(
      BuildContext context, WidgetRef ref, PortfolioAsset asset, String lc) {
    final unitsController = TextEditingController(text: asset.units.toString());
    final costController =
        TextEditingController(text: asset.averageCost.toString());
    final currencyService = ref.read(currencyServiceProvider);
    final sign = currencyService.getSymbol(asset.currencyCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${AppStrings.tr(AppStrings.edit, lc)} ${asset.symbol}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitsController,
              decoration: InputDecoration(
                  labelText: AppStrings.tr(AppStrings.unitsLabel, lc),
                  border: const OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: InputDecoration(
                  labelText:
                      '${AppStrings.tr(AppStrings.averageCostLabel, lc)} ($sign)',
                  border: const OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.tr(AppStrings.cancel, lc))),
          ElevatedButton(
            onPressed: () {
              final units = double.tryParse(unitsController.text) ?? 0;
              final cost = double.tryParse(costController.text) ?? 0;
              if (units > 0 && cost >= 0) {
                ref
                    .read(portfolioProvider.notifier)
                    .updateAssetDetails(asset.symbol, units, cost);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppStrings.tr(AppStrings.assetUpdated, lc))));
              }
            },
            child: Text(AppStrings.tr(AppStrings.save, lc)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, PortfolioAsset asset, String lc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.tr(AppStrings.remove, lc)),
        content: Text(
            '${asset.symbol} ${AppStrings.tr(AppStrings.confirmRemove, lc)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.tr(AppStrings.cancel, lc))),
          TextButton(
            onPressed: () {
              ref.read(portfolioProvider.notifier).removeAsset(asset.symbol);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppStrings.tr(AppStrings.assetDeleted, lc)),
                  backgroundColor: AppColors.error));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.tr(AppStrings.remove, lc)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.pie_chart_outline,
                size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(AppStrings.tr(AppStrings.noAssetsYet, lc),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              AppStrings.tr(AppStrings.addAssetsFromMarkets, lc),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioItemCard extends ConsumerWidget {
  final PortfolioAsset asset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PortfolioItemCard({
    required this.asset,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final assetAsync = ref.watch(assetProvider(asset.id));
    final currencyService = ref.watch(currencyServiceProvider);
    final displayCurrency = ref.watch(investDisplayCurrencyProvider);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            _buildLeading(asset.symbol),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.symbol,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      '${asset.units} ${AppStrings.tr(AppStrings.unitsCount, lc)}${asset.currencyCode != 'TRY' ? ' (${asset.currencyCode})' : ''}',
                      style: const TextStyle(
                          color: AppColors.grey600, fontSize: 13)),
                ],
              ),
            ),

            // Sparkline in the middle
            if (assetAsync.value != null)
              Expanded(
                flex: 2,
                child: SparklineWidget(
                  isPositive: (assetAsync.value!.change24h ?? 0) >= 0,
                  width: 50,
                  height: 30,
                ),
              ),
            const SizedBox(width: 8),

            assetAsync.when(
              data: (marketAsset) {
                if (marketAsset == null) return const SizedBox.shrink();

                // API value is in USD
                final currentValueUSD =
                    marketAsset.currentPriceUsd! * asset.units;

                // Convert both to TRY for profit calculation
                final currentValueTRY =
                    currencyService.convertToTRY(currentValueUSD, 'USD');
                final totalCostTRY = currencyService.convertToTRY(
                    asset.units * asset.averageCost, asset.currencyCode);

                final profitTRY = currentValueTRY - totalCostTRY;
                final profitPercent =
                    totalCostTRY > 0 ? (profitTRY / totalCostTRY) * 100 : 0.0;
                final isPositive = profitTRY >= 0;

                // Show value in selected investment currency
                final currencyFormat = NumberFormat.currency(
                    locale: displayCurrency == 'TRY' ? 'tr_TR' : 'en_US',
                    symbol: currencyService.getSymbol(displayCurrency),
                    decimalDigits: 0);

                final currentValueDisplay = currencyService.convertFromTRY(
                    currentValueTRY, displayCurrency);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currencyFormat.format(currentValueDisplay),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Icon(
                            isPositive
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.error,
                            size: 20),
                        Text(
                          '${isPositive ? '+' : ''}${profitPercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: isPositive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                  width: 40, height: 20, child: LinearProgressIndicator()),
              error: (_, __) => Text(AppStrings.tr(AppStrings.error, lc)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(String symbol) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, math.min(2, symbol.length)).toUpperCase(),
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
