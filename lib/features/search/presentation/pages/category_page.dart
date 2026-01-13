import 'package:flutter/material.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/features/exchanges/presentation/pages/exchange_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/features/shared/widgets/enhanced_market_item_card.dart';
import 'package:invest_guide/services/api/invest_guide_api.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage>
    with SingleTickerProviderStateMixin {
  List<MarketItem> _items = [];
  List<ExchangeItem> _exchanges = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  List<MarketItem> _filteredItems = [];
  List<ExchangeItem> _filteredExchanges = [];
  Map<String, dynamic>? _fearGreedData;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadData();
    _loadExchanges();
  }

  Future<void> _loadExchanges() async {
    final exchanges = _getMockExchanges(widget.categoryId);
    setState(() {
      _exchanges = exchanges;
      _filteredExchanges = List.from(_exchanges);
    });
  }

  List<ExchangeItem> _getMockExchanges(String categoryId) {
    final allExchanges = [
      ExchangeItem(
          id: 'binance',
          name: 'Binance',
          country: 'Global',
          volume24h: 76540000000,
          trustScore: 10,
          supportedCategories: ['crypto']),
      ExchangeItem(
          id: 'coinbase',
          name: 'Coinbase',
          country: 'ABD',
          volume24h: 21340000000,
          trustScore: 9,
          supportedCategories: ['crypto']),
      ExchangeItem(
          id: 'btcturk',
          name: 'BtcTurk',
          country: 'Türkiye',
          volume24h: 125000000,
          trustScore: 8,
          supportedCategories: ['crypto']),
      ExchangeItem(
          id: 'paribu',
          name: 'Paribu',
          country: 'Türkiye',
          volume24h: 98000000,
          trustScore: 7,
          supportedCategories: ['crypto']),
      ExchangeItem(
          id: 'nyse',
          name: 'New York Stock Exchange',
          country: 'ABD',
          volume24h: 1200000000000,
          trustScore: 10,
          supportedCategories: ['stock', 'etf']),
      ExchangeItem(
          id: 'nasdaq',
          name: 'NASDAQ',
          country: 'ABD',
          volume24h: 980000000000,
          trustScore: 10,
          supportedCategories: ['stock', 'etf']),
      ExchangeItem(
          id: 'bist',
          name: 'Borsa İstanbul (BIST)',
          country: 'Türkiye',
          volume24h: 15000000000,
          trustScore: 8,
          supportedCategories: ['stock', 'etf', 'bond']),
    ];

    return allExchanges
        .where((e) => e.supportedCategories.contains(categoryId))
        .toList()
      ..sort((a, b) => b.volume24h.compareTo(a.volume24h));
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.categoryId == 'crypto') {
        final data = await InvestGuideApi.getCryptoFearGreed();
        if (mounted) setState(() => _fearGreedData = data);
      }

      var items = <MarketItem>[];

      switch (widget.categoryId) {
        case 'crypto':
          final data = await InvestGuideApi.getCryptoMarkets(limit: 50);
          items = data.map<MarketItem>((coin) {
            return MarketItem(
              id: coin['id'],
              symbol: (coin['symbol'] as String).toUpperCase(),
              name: coin['name'],
              price: (coin['price'] as num).toDouble(),
              change24h: (coin['change_24h'] as num).toDouble(),
              imageUrl: coin['image'],
              marketCap: (coin['market_cap'] as num).toDouble(),
            );
          }).toList();
          break;

        case 'stock':
          final data = await InvestGuideApi.getStocks();
          items = data.map<MarketItem>((stock) {
            return MarketItem(
              id: stock['id'] ?? stock['symbol'] ?? '',
              symbol: stock['symbol'] ?? '',
              name: stock['name'] ?? '',
              price: double.tryParse(stock['price']?.toString() ?? '0') ?? 0.0,
              change24h:
                  double.tryParse(stock['change_percent']?.toString() ?? '0') ??
                      0.0,
              imageUrl: null,
            );
          }).toList();
          break;

        case 'forex':
          final currencies = await InvestGuideApi.getCurrencies();
          // Backend artık List<dynamic> döndürüyor: [{"symbol": "USD", "price": ...}, ...]
          items = currencies.map<MarketItem>((curr) {
            final code = curr['symbol'] ?? '';
            final name = curr['name'] ?? code;
            final price =
                double.tryParse(curr['price']?.toString() ?? '0') ?? 0.0;

            // Yahoo-style ID oluşturma (Grafik vb. için fallback gerekirse)
            var yahooSymbol = '$code/TRY';
            if (code == 'USD') {
              yahooSymbol = 'USDTRY=X';
            } else if (code == 'EUR') {
              yahooSymbol = 'EURTRY=X';
            } else if (code == 'GBP') {
              yahooSymbol = 'GBPTRY=X';
            }

            return MarketItem(
              id: yahooSymbol,
              symbol: '$code/TRY',
              name: name,
              price: price,
              change24h: 0.0, // TradingView listesinde change genelde 0 gelir
            );
          }).toList();
          break;

        case 'commodity':
          final data = await InvestGuideApi.getCommodities();
          items = data.map<MarketItem>((com) {
            return MarketItem(
              id: com['id'] ?? com['symbol'] ?? '',
              symbol: com['symbol'] ?? '',
              name: com['name'] ?? '',
              price: double.tryParse(com['price']?.toString() ?? '0') ?? 0.0,
              change24h:
                  double.tryParse(com['change_percent']?.toString() ?? '0') ??
                      0.0,
            );
          }).toList();
          break;

        case 'etf':
          final data = await InvestGuideApi.getETFs();
          items = data.map<MarketItem>((etf) {
            return MarketItem(
              id: etf['id'] ?? etf['symbol'] ?? '',
              symbol: etf['symbol'] ?? '',
              name: etf['name'] ?? '',
              price: double.tryParse(etf['price']?.toString() ?? '0') ?? 0.0,
              change24h:
                  double.tryParse(etf['change_percent']?.toString() ?? '0') ??
                      0.0,
            );
          }).toList();
          break;

        case 'bond':
          final data = await InvestGuideApi.getBonds();
          items = data.map<MarketItem>((bond) {
            return MarketItem(
              id: bond['id'] ?? bond['symbol'] ?? '',
              symbol: bond['symbol'] ?? '',
              name: bond['name'] ?? '',
              price: double.tryParse(bond['price']?.toString() ?? '0') ?? 0.0,
              change24h:
                  double.tryParse(bond['change_percent']?.toString() ?? '0') ??
                      0.0,
            );
          }).toList();
          break;
      }

      if (mounted) {
        setState(() {
          _items = items;
          _filteredItems = List.from(_items);
          _isLoading = false;
        });
        if (_searchController.text.isNotEmpty) {
          _onSearchChanged();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              '${AppStrings.tr(AppStrings.dataLoadError, ref.read(languageProvider).code)}: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) =>
              item.symbol.toLowerCase().contains(query) ||
              item.name.toLowerCase().contains(query))
          .toList();

      _filteredExchanges = _exchanges
          .where((ex) => ex.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(context),
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: AppStrings.tr(AppStrings.instrumentsLabel, lc)),
            Tab(text: AppStrings.tr(AppStrings.exchangesTitle, lc)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: AppColors.surface(context),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.border(context).withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                    hintText: AppStrings.tr(AppStrings.searchHint, lc),
                    hintStyle: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary(context)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: AppColors.textSecondary(context)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            })
                        : null),
                onChanged: (val) => setState(() {}),
              ),
            ),
          ),
          if (_fearGreedData != null && widget.categoryId == 'crypto')
            _buildFearGreedIndex(lc),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _filteredItems.isEmpty
                              ? Center(
                                  child: Text(
                                      AppStrings.tr(AppStrings.noDataFound, lc),
                                      style: TextStyle(
                                          color: AppColors.textSecondary(
                                              context))))
                              : RefreshIndicator(
                                  onRefresh: _loadData,
                                  color: AppColors.primary,
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredItems.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      return _MarketItemCard(
                                          item: item,
                                          categoryId: widget.categoryId);
                                    },
                                  ),
                                ),
                          _filteredExchanges.isEmpty
                              ? Center(
                                  child: Text(
                                      AppStrings.tr(AppStrings.noDataFound, lc),
                                      style: TextStyle(
                                          color: AppColors.textSecondary(
                                              context))))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredExchanges.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final exchange = _filteredExchanges[index];
                                    return _ExchangeCard(exchange: exchange);
                                  },
                                ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFearGreedIndex(String lc) {
    final value = _fearGreedData?['value'] ?? 50;
    final classification = _fearGreedData?['classification'] ?? 'Neutral';

    Color getColor(int val) {
      if (val < 25) return Colors.red;
      if (val < 45) return Colors.orange;
      if (val < 55) return Colors.amber;
      if (val < 75) return Colors.lightGreen;
      return Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColor(value).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.speed, color: getColor(value), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tr(AppStrings.fearGreedIndexTitle, lc),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '$value/100',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: getColor(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  classification.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketItemCard extends StatelessWidget {
  final MarketItem item;
  final String categoryId;

  const _MarketItemCard({
    required this.item,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedMarketItemCard(
      assetId: item.id,
      symbol: item.symbol,
      name: item.name,
      price: item.price,
      change24h: item.change24h,
      categoryId: categoryId,
      imageUrl: item.imageUrl,
    );
  }
}

class _ExchangeCard extends ConsumerWidget {
  final ExchangeItem exchange;

  const _ExchangeCard({required this.exchange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lc = ref.watch(languageProvider).code;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExchangeDetailPage(
                  exchangeId: exchange.id,
                  exchangeName: exchange.name,
                  country: exchange.country,
                  volume24h: exchange.volume24h,
                  trustScore: exchange.trustScore,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.store,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exchange.name,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exchange.country,
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.tr(AppStrings.volume24hShort, lc),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${_formatVolume(exchange.volume24h)}',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: exchange.trustScore >= 8
                              ? AppColors.success
                              : exchange.trustScore >= 6
                                  ? const Color(0xFFFFA500)
                                  : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${exchange.trustScore}/10',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000000000) {
      return '${(volume / 1000000000000).toStringAsFixed(2)}T';
    }
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    }
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    }
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toStringAsFixed(2);
  }
}

class MarketItem {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double? marketCap;
  final double? volume24h;
  final String? imageUrl;

  MarketItem({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    this.marketCap,
    this.volume24h,
    this.imageUrl,
  });
}

class ExchangeItem {
  final String id;
  final String name;
  final String country;
  final double volume24h;
  final int trustScore;
  final List<String> supportedCategories;

  ExchangeItem({
    required this.id,
    required this.name,
    required this.country,
    required this.volume24h,
    required this.trustScore,
    required this.supportedCategories,
  });
}
