import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/watchlist/providers/watchlist_provider.dart';
import 'package:invest_guide/features/watchlist/providers/asset_cache_provider.dart';
import 'package:invest_guide/features/watchlist/models/watchlist_item.dart';
import 'package:invest_guide/features/shared/widgets/enhanced_market_item_card.dart'; // Add this import
import 'package:invest_guide/features/watchlist/providers/watchlist_refresh_provider.dart';
import 'dart:async';

import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';

class WatchlistPage extends ConsumerWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final watchlist = ref.watch(watchlistProvider);
    // Trigger periodic refresh
    ref.listen(watchlistRefreshProvider, (previous, next) {
      if (next.hasValue) {
        // Assets will re-fetch automatically because cache was cleared in the provider
      }
    });

    // Filter unique categories, default to 'Genel' if null, always encompass 'Tümü'
    final categories = <String>[AppStrings.tr(AppStrings.tabAll, lc)];
    final itemCategories = watchlist
        .map((e) => _getCategoryDisplayName(e.category, lc))
        .toSet()
        .toList();
    itemCategories.sort(); // sort alphabetically
    categories.addAll(itemCategories);

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface(context),
          centerTitle: false,
          title: Text(
            AppStrings.tr(AppStrings.watchlistTitle, lc),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          bottom: watchlist.isEmpty
              ? null
              : TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary(context),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: categories.map((c) => Tab(text: c)).toList(),
                ),
          actions: const [
            SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: AppColors.surface(context),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: AppColors.textSecondary(context)),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.tr(AppStrings.searchHint, lc),
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(watchlistProvider);
                },
                child: watchlist.isEmpty
                    ? _buildEmptyState(context, lc)
                    : TabBarView(
                        children: categories.map((category) {
                          if (category == AppStrings.tr(AppStrings.tabAll, lc)) {
                            return _buildWatchlistItems(context, ref, watchlist, lc);
                          } else {
                            final filtered = watchlist
                                .where((e) => _getCategoryDisplayName(e.category, lc) == category)
                                .toList();
                            if (filtered.isEmpty) return _buildEmptyState(context, lc);
                            return _buildWatchlistItems(context, ref, filtered, lc);
                          }
                        }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String? categoryId, String lc) {
    switch (categoryId) {
      case 'crypto':
        return AppStrings.tr(AppStrings.catCrypto, lc);
      case 'stock':
        return AppStrings.tr(AppStrings.catStock, lc);
      case 'forex':
        return AppStrings.tr(AppStrings.catForex, lc);
      case 'commodity':
        return AppStrings.tr(AppStrings.catCommodity, lc);
      case 'etf':
        return AppStrings.tr(AppStrings.catFunds, lc);
      case 'bond':
        return AppStrings.tr(AppStrings.catBond, lc);
      case 'pension_fund':
        return AppStrings.tr(AppStrings.catPension, lc);
      case 'life_insurance':
        return AppStrings.tr(AppStrings.catInsurance, lc);
      default:
        return AppStrings.tr(AppStrings.tabOther, lc);
    }
  }

  Widget _buildEmptyState(BuildContext context, String lc) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_border,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.tr(AppStrings.emptyListTitle, lc),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.tr(AppStrings.emptyListDesc, lc),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistItems(BuildContext context, WidgetRef ref, List<WatchlistItem> watchlist, String lc) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        final item = watchlist[index];
        return Dismissible(
          key: Key(item.symbol),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, item.name, lc);
          },
          onDismissed: (direction) async {
            try {
              await ref.read(watchlistProvider.notifier).removeFromWatchlist(item.symbol);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.symbol} ${AppStrings.tr(AppStrings.removedFromList, lc)}',
                      style: TextStyle(color: AppColors.textPrimary(context)),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.surface(context),
                    duration: const Duration(seconds: 2),
                  ),

                );
              }
            } catch (e) {
              // Error handling
            }
          },
          child: _buildWatchlistCard(context, ref, item),
        );
      },
    );
  }

  Widget _buildWatchlistCard(BuildContext context, WidgetRef ref, WatchlistItem item) {
    if (item.assetId == null) return const SizedBox.shrink();

    final assetAsync = ref.watch(assetProvider(item.assetId!));

    return assetAsync.when(
      data: (asset) {
        if (asset == null) {
          // Fallback if asset is null but we have item data
          return EnhancedMarketItemCard(
            assetId: item.assetId!,
            symbol: item.symbol,
            name: item.name,
            price: 0.0,
            change24h: 0.0,
            categoryId: item.category ?? 'other',
            imageUrl: null,
          );
        }
        return EnhancedMarketItemCard(
          assetId: asset.id,
          symbol: asset.symbol,
          name: asset.name,
          price: asset.currentPriceUsd ?? 0.0,
          change24h: asset.change24h ?? 0.0,
          categoryId: item.category ?? 'other',
          imageUrl: asset.iconUrl,
        );
      },
      loading: () => Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => EnhancedMarketItemCard(
        assetId: item.assetId!,
        symbol: item.symbol,
        name: item.name,
        price: 0.0,
        change24h: 0.0,
        categoryId: item.category ?? 'other',
        imageUrl: null,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String itemName, String lc) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(AppStrings.tr(AppStrings.areYouSure, lc), style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text('$itemName ${AppStrings.tr(AppStrings.removeFromWatchlist, lc)}', style: TextStyle(color: AppColors.textSecondary(context))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.tr(AppStrings.cancel, lc)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.tr(AppStrings.remove, lc)),
          ),
        ],
      ),
    );
  }
}
