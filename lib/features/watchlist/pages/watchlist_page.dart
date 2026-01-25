import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/watchlist/providers/watchlist_provider.dart';
import 'package:invest_guide/features/watchlist/providers/asset_cache_provider.dart';
import 'package:invest_guide/features/watchlist/models/watchlist_item.dart';
import 'package:invest_guide/features/shared/widgets/enhanced_market_item_card.dart';
import 'package:invest_guide/features/watchlist/providers/watchlist_refresh_provider.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/auth/presentation/widgets/auth_prompt_dialog.dart';
import 'package:invest_guide/features/alerts/presentation/pages/alerts_page.dart';

class WatchlistPage extends ConsumerStatefulWidget {
  const WatchlistPage({super.key});

  @override
  ConsumerState<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends ConsumerState<WatchlistPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context, String lc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              AppStrings.tr(AppStrings.infoTitle, lc),
              style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              context,
              Icons.swap_vert_rounded,
              lc == 'tr' ? 'Sıralamayı Değiştirme' : 'Reorder Assets',
              lc == 'tr'
                  ? 'Varlığın üzerine basılı tutup yukarı veya aşağı sürükleyerek sırasını değiştirebilirsiniz.'
                  : 'Long-press an asset and drag it up or down to change its position.',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              context,
              Icons.swipe_left_rounded,
              lc == 'tr' ? 'Varlık Silme' : 'Delete Assets',
              lc == 'tr'
                  ? 'Bir varlığı listeden çıkarmak için sola kaydırmanız yeterlidir.'
                  : 'Simply swipe left on an asset to remove it from your list.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.tr(AppStrings.ok, lc),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final watchlist = ref.watch(watchlistProvider);

    ref.listen(watchlistRefreshProvider, (previous, next) {});

    final categories = <String>[AppStrings.tr(AppStrings.tabAll, lc)];
    final itemCategories = watchlist
        .map((e) => _getCategoryDisplayName(e.category, lc, symbol: e.symbol))
        .toSet()
        .toList();
    itemCategories.sort();
    categories.addAll(itemCategories);

    final filteredWatchlist = watchlist.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return item.symbol.toLowerCase().contains(query) ||
          item.name.toLowerCase().contains(query);
    }).toList();

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
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline_rounded,
                  color: AppColors.textSecondary(context)),
              onPressed: () => _showInfoDialog(context, lc),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              onPressed: () {
                final authState = ref.read(authNotifierProvider);
                if (authState is AuthAuthenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsPage()),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AuthPromptDialog(
                      title: lc == 'tr' ? 'Hesap Gerekli' : 'Account Required',
                      description: lc == 'tr'
                          ? 'Fiyat alarmlarınızı yönetmek için lütfen hesabınıza giriş yapın.'
                          : 'Please login to manage your price alerts.',
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
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
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surface(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.border(context).withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: _focusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _focusNode.hasFocus
                          ? AppColors.primary
                          : AppColors.textSecondary(context)
                              .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.0,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: AppStrings.tr(AppStrings.searchHint, lc),
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary(context)
                                .withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary(context)
                              .withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
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
                        children: categories.isEmpty
                            ? [const SizedBox()]
                            : categories.map((category) {
                                final currentList = (category ==
                                        AppStrings.tr(AppStrings.tabAll, lc))
                                    ? filteredWatchlist
                                    : filteredWatchlist
                                        .where((e) =>
                                            _getCategoryDisplayName(
                                                e.category, lc,
                                                symbol: e.symbol) ==
                                            category)
                                        .toList();

                                if (currentList.isEmpty &&
                                    _searchQuery.isNotEmpty) {
                                  return _buildNoResultsState(context, lc);
                                } else if (currentList.isEmpty) {
                                  return _buildEmptyState(context, lc);
                                }
                                return _buildWatchlistItems(
                                    context, ref, currentList, lc);
                              }).toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String? categoryId, String lc,
      {String? symbol}) {
    // Infer category if missing or 'other'
    var cid = categoryId;

    if (cid == null || cid == 'other' || cid == 'asset') {
      if (symbol != null) {
        final sym = symbol.toUpperCase();
        if (sym.endsWith('.IS')) {
          cid = 'stock';
        } else if (sym.length <= 5 &&
            (sym.contains('BTC') ||
                sym.contains('ETH') ||
                sym.contains('SOL') ||
                sym.contains('BNB'))) {
          cid = 'crypto';
        } else if (sym.length == 3) {
          cid = 'etf'; // Likely TEFAS like TCD, GSP etc
        }
      }
    }

    switch (cid) {
      case 'crypto':
        return AppStrings.tr(AppStrings.catCrypto, lc);
      case 'stock':
      case 'asset':
        return AppStrings.tr(AppStrings.catStock, lc);
      case 'forex':
        return AppStrings.tr(AppStrings.catForex, lc);
      case 'commodity':
        return AppStrings.tr(AppStrings.catCommodity, lc);
      case 'etf':
      case 'fund':
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

  Widget _buildNoResultsState(BuildContext context, String lc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary(context).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              AppStrings.tr(AppStrings.noDataFound, lc),
              style: TextStyle(
                  color: AppColors.textSecondary(context), fontSize: 16),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildWatchlistItems(BuildContext context, WidgetRef ref,
      List<WatchlistItem> watchlist, String lc) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: watchlist.length,
      onReorder: (oldIndex, newIndex) {
        // Find absolute indices in the global list if current view is filtered
        final itemToMove = watchlist[oldIndex];
        final globalList = ref.read(watchlistProvider);
        final globalOldIndex =
            globalList.indexWhere((e) => e.symbol == itemToMove.symbol);

        int globalNewIndex;
        if (newIndex >= watchlist.length) {
          // Moving to the end of the current view
          globalNewIndex = globalList.length;
        } else {
          final pivotItem = watchlist[newIndex];
          globalNewIndex =
              globalList.indexWhere((e) => e.symbol == pivotItem.symbol);
        }

        if (globalOldIndex != -1) {
          ref
              .read(watchlistProvider.notifier)
              .reorder(globalOldIndex, globalNewIndex);
        }
      },
      itemBuilder: (context, index) {
        final item = watchlist[index];
        return Dismissible(
          key: ValueKey(item.symbol), // Reorderable needs keys
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
              await ref
                  .read(watchlistProvider.notifier)
                  .removeFromWatchlist(item.symbol);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lc == 'tr'
                          ? '${item.name} listenizden kaldırıldı.'
                          : '${item.name} removed from watchlist.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: lc == 'tr' ? 'Geri Al' : 'Undo',
                      onPressed: () {
                        // Undo logic could be added here if needed,
                        // but logic currently makes it hard without re-adding
                        // For now we just show confirmation.
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lc == 'tr'
                          ? 'İşlem başarısız oldu. Lütfen tekrar deneyin.'
                          : 'Action failed. Please try again.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
              // Force refresh to restore item if delete failed
              ref.invalidate(watchlistProvider);
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildWatchlistCard(context, ref, item),
          ),
        );
      },
    );
  }

  Widget _buildWatchlistCard(
      BuildContext context, WidgetRef ref, WatchlistItem item) {
    if (item.assetId == null && item.symbol.isEmpty)
      return const SizedBox.shrink();
    // Fallback ID to symbol if assetId is missing (should be fixed by provider now)
    final effectiveId = item.assetId ?? item.symbol;
    final assetAsync = ref.watch(assetProvider(effectiveId));

    return assetAsync.when(
      data: (asset) {
        return EnhancedMarketItemCard(
          assetId: asset?.id ?? effectiveId,
          symbol: asset?.symbol ?? item.symbol,
          name: asset?.name ?? item.name,
          price: asset?.currentPriceUsd ?? 0.0,
          change24h: asset?.change24h ?? 0.0,
          categoryId: item.category ?? 'other',
          imageUrl: asset?.iconUrl,
        );
      },
      loading: () => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => EnhancedMarketItemCard(
        assetId: effectiveId,
        symbol: item.symbol,
        name: item.name,
        price: 0.0,
        change24h: 0.0,
        categoryId: item.category ?? 'other',
        imageUrl: null,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, String itemName, String lc) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(AppStrings.tr(AppStrings.areYouSure, lc),
            style: TextStyle(color: AppColors.textPrimary(context))),
        content: Text(
            '$itemName ${AppStrings.tr(AppStrings.removeFromWatchlist, lc)}',
            style: TextStyle(color: AppColors.textSecondary(context))),
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
