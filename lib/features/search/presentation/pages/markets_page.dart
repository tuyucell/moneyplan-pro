import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/utils/responsive.dart';
import 'dart:async';
import 'package:invest_guide/services/api/invest_guide_api.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

import 'package:invest_guide/features/shared/widgets/economic_calendar_widget.dart';
import 'package:invest_guide/features/search/presentation/widgets/macro_indicators_widget.dart';
import 'package:invest_guide/features/search/presentation/widgets/search_overlay.dart';
import 'package:invest_guide/features/shared/services/widget_service.dart';
import 'package:invest_guide/core/router/app_router.dart';

class MarketsPage extends ConsumerStatefulWidget {
  const MarketsPage({super.key});

  @override
  ConsumerState<MarketsPage> createState() => _MarketsPageState();
}

class _MarketsPageState extends ConsumerState<MarketsPage> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _newsList = [];
  bool _isNewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final news = await InvestGuideApi.getNews(limit: 10);

      // Invalidate providers to force refresh of Macro and Calendar widgets
      ref.invalidate(macroDataProvider);
      ref.invalidate(calendarDataProvider);

      if (mounted) {
        setState(() {
          _newsList = news;
          _isNewsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('News Fetch Error: $e');
      if (mounted) setState(() => _isNewsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: AppColors.surface(context),
              elevation: 0,
              title: Text(
                AppStrings.tr(AppStrings.pageMarkets, lc),
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              actions: const [
                SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppColors.border(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _MarketTickerWidget(lc: lc),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SearchOverlay(languageCode: lc),
              ),
            ),
            const SliverToBoxAdapter(
              child: EconomicCalendarWidget(),
            ),
            const SliverToBoxAdapter(
              child: MacroIndicatorsWidget(),
            ),
            SliverToBoxAdapter(
              child: _LatestNewsWidget(
                news: _newsList,
                isLoading: _isNewsLoading,
                lc: lc,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  AppStrings.tr(AppStrings.headerInvestTools, lc),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: context.adaptivePadding,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.isTablet ? 3 : 2,
                  childAspectRatio: context.isTablet ? 1.5 : 1.3,
                  crossAxisSpacing: context.isTablet ? 16 : 12,
                  mainAxisSpacing: context.isTablet ? 16 : 12,
                ),
                delegate: SliverChildListDelegate([
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catCrypto, lc),
                    subtitle: AppStrings.tr(AppStrings.catCryptoDesc, lc),
                    icon: Icons.currency_bitcoin,
                    color: AppColors.crypto,
                    onTap: () => context.push(
                        '/category/crypto?name=${AppStrings.tr(AppStrings.catCrypto, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catStock, lc),
                    subtitle: AppStrings.tr(AppStrings.catStockDesc, lc),
                    icon: Icons.candlestick_chart,
                    color: AppColors.stock,
                    onTap: () => context.push(
                        '/category/stock?name=${AppStrings.tr(AppStrings.catStock, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catForex, lc),
                    subtitle: AppStrings.tr(AppStrings.catForexDesc, lc),
                    icon: Icons.currency_exchange,
                    color: AppColors.forex,
                    onTap: () => context.push(
                        '/category/forex?name=${AppStrings.tr(AppStrings.catForex, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catCommodity, lc),
                    subtitle: AppStrings.tr(AppStrings.catCommodityDesc, lc),
                    icon: Icons.diamond_outlined,
                    color: AppColors.commodity,
                    onTap: () => context.push(
                        '/category/commodity?name=${AppStrings.tr(AppStrings.catCommodity, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catFunds, lc),
                    subtitle: AppStrings.tr(AppStrings.catFundsDesc, lc),
                    icon: Icons.pie_chart_outline,
                    color: AppColors.etf,
                    onTap: () => context.push('/funds'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catBond, lc),
                    subtitle: AppStrings.tr(AppStrings.catBondDesc, lc),
                    icon: Icons.receipt_long,
                    color: AppColors.bond,
                    onTap: () => context.push(
                        '/category/bond?name=${AppStrings.tr(AppStrings.catBond, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catPension, lc),
                    subtitle: AppStrings.tr(AppStrings.catPensionDesc, lc),
                    icon: Icons.savings_outlined,
                    color: AppColors.success,
                    onTap: () => context.push(
                        '/category/pension_fund?name=${AppStrings.tr(AppStrings.catPension, lc)}'),
                  ),
                  _CategoryCard(
                    title: AppStrings.tr(AppStrings.catInsurance, lc),
                    subtitle: AppStrings.tr(AppStrings.catInsuranceDesc, lc),
                    icon: Icons.security,
                    color: AppColors.info,
                    onTap: () => context.push(
                        '/category/life_insurance?name=${AppStrings.tr(AppStrings.catInsurance, lc)}'),
                  ),
                ]),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

class _MarketTickerWidget extends StatefulWidget {
  final String lc;
  const _MarketTickerWidget({required this.lc});

  @override
  State<_MarketTickerWidget> createState() => _MarketTickerWidgetState();
}

class _MarketTickerWidgetState extends State<_MarketTickerWidget> {
  late ScrollController _scrollController;
  late Timer _timer;
  final double _scrollSpeed = 1.0;
  List<_TickerItem> _items = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _items = _getDemoItems();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  Future<void> _loadData() async {
    try {
      final data = await InvestGuideApi.getMarketSummary();
      if (data.isEmpty) return;

      final newItems = <_TickerItem>[];

      if (data['bist100'] != null) {
        final price = (data['bist100']['price'] as num).toDouble();
        final change = (data['bist100']['change_percent'] as num).toDouble();
        newItems.add(_TickerItem(
            'BIST 100',
            price.toStringAsFixed(2),
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            change >= 0));
      }

      if (data['dolar'] != null) {
        final price = (data['dolar']['price'] as num).toDouble();
        final change = (data['dolar']['change_percent'] as num).toDouble();
        newItems.add(_TickerItem(
            'USD/TRY',
            '₺${price.toStringAsFixed(2)}',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            change >= 0));
      }

      if (data['euro'] != null) {
        final price = (data['euro']['price'] as num).toDouble();
        final change = (data['euro']['change_percent'] as num).toDouble();
        newItems.add(_TickerItem(
            'EUR/TRY',
            '₺${price.toStringAsFixed(2)}',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            change >= 0));
      }

      if (data['gram_altin'] != null) {
        final price = (data['gram_altin']['price'] as num).toDouble();
        final change = (data['gram_altin']['change_percent'] as num).toDouble();
        newItems.add(_TickerItem(
            AppStrings.tr(AppStrings.goldGram, widget.lc),
            '₺${price.toStringAsFixed(2)}',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            change >= 0));
      }

      if (data['bitcoin'] != null) {
        final price = (data['bitcoin']['price'] as num).toDouble();
        final change = (data['bitcoin']['change_percent'] as num).toDouble();
        newItems.add(_TickerItem(
            'BTC/USD',
            '\$${price.toStringAsFixed(0)}',
            '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
            change >= 0));
      }

      if (mounted && newItems.isNotEmpty) {
        setState(() {
          _items = newItems;
        });

        // Update Home Screen Widget
        var pBist = '9.100,50', cBist = '+1.2%';
        var pUsd = '32.50', cUsd = '+0.1%';
        var pGold = '2.450', cGold = '+0.5%';

        /* Note: Since the free API might not return BIST data, 
           we keep default/demo values for missing items or implement additional logic.
           For now we map what we have:
        */

        if (data['bist100'] != null) {
          pBist = (data['bist100']['price'] as num).toStringAsFixed(2);
          final ch = (data['bist100']['change_percent'] as num).toDouble();
          cBist = '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%';
        }

        if (data['dolar'] != null) {
          pUsd = (data['dolar']['price'] as num).toStringAsFixed(2);
          final ch = (data['dolar']['change_percent'] as num).toDouble();
          cUsd = '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%';
        }

        if (data['gram_altin'] != null) {
          pGold = (data['gram_altin']['price'] as num).toStringAsFixed(0);
          final ch = (data['gram_altin']['change_percent'] as num).toDouble();
          cGold = '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%';
        }

        // BIST data is not in the summary endpoint usually, using hardcoded or waiting for dedicated API
        // Updating widget with latest Available data

        await WidgetService.updateMarketData(
          priceBist: pBist,
          changeBist: cBist,
          priceUsd: pUsd,
          changeUsd: cUsd,
          priceGold: pGold,
          changeGold: cGold,
        );
      }
    } catch (e) {
      debugPrint('Ticker Load Error: $e');
    }
  }

  List<_TickerItem> _getDemoItems() {
    return [];
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_scrollController.hasClients) {
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(_scrollController.offset + _scrollSpeed);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length * 100,
        itemBuilder: (context, index) {
          final item = _items[index % _items.length];
          return _MarketTickerItem(item: item);
        },
      ),
    );
  }
}

class _TickerItem {
  final String symbol;
  final String price;
  final String change;
  final bool isUp;
  _TickerItem(this.symbol, this.price, this.change, this.isUp);
}

class _MarketTickerItem extends StatelessWidget {
  final _TickerItem item;
  const _MarketTickerItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
              color: AppColors.border(context).withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.symbol,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.price,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.change,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: item.isUp ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            item.isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: item.isUp ? AppColors.success : AppColors.error,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        highlightColor: color.withValues(alpha: 0.05),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textTertiary(context)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestNewsWidget extends StatelessWidget {
  final List<dynamic> news;
  final bool isLoading;
  final String lc;

  const _LatestNewsWidget({
    required this.news,
    required this.isLoading,
    required this.lc,
  });

  String _getDefaultImage(String title, String lc) {
    final t = title.toLowerCase();

    // Turkish keywords
    final isCrypto =
        t.contains('btc') || t.contains('bitcoin') || t.contains('kripto');
    final isGold = t.contains('altın') || t.contains('gold');
    final isForex = t.contains('dolar') ||
        t.contains('usd') ||
        t.contains('döviz') ||
        t.contains('eur');
    final isStock = t.contains('hisse') ||
        t.contains('borsa') ||
        t.contains('bist') ||
        t.contains('nasdaq');

    if (isCrypto) {
      return 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?q=80&w=500&auto=format&fit=crop';
    } else if (isGold) {
      return 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=500&auto=format&fit=crop';
    } else if (isForex) {
      return 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?q=80&w=500&auto=format&fit=crop';
    } else if (isStock) {
      return 'https://images.unsplash.com/photo-1611974714851-48206132973b?q=80&w=500&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=500&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading && news.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(
          child: Text(
            AppStrings.tr(AppStrings.newsNotFound, lc),
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr(AppStrings.headerLastNews, lc),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRouter.news),
                child: Text(
                  AppStrings.tr(AppStrings.btnSeeAll, lc),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final item = news[index];
                    final imageUrl = (item['image_url'] != null &&
                            item['image_url'].toString().isNotEmpty)
                        ? item['image_url']
                        : _getDefaultImage(item['title'] ?? '', lc);

                    return GestureDetector(
                      onTap: () =>
                          context.push(AppRouter.newsDetail, extra: item),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Image.network(
                                  imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.05),
                                    width: double.infinity,
                                    child: const Icon(Icons.newspaper,
                                        color: AppColors.primary, size: 32),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item['source']?.toUpperCase() ??
                                          AppStrings.tr(AppStrings.news, lc)
                                              .toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['title'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.textPrimary(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
