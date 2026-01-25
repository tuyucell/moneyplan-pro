import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/services/api/invest_guide_api.dart';
import 'package:intl/intl.dart';
import 'package:invest_guide/features/wallet/providers/portfolio_provider.dart';
import 'package:invest_guide/features/wallet/models/portfolio_asset.dart';
import 'package:invest_guide/features/watchlist/models/watchlist_item.dart';
import 'package:invest_guide/features/watchlist/providers/watchlist_provider.dart';
import 'package:invest_guide/features/watchlist/providers/asset_cache_provider.dart';
import 'package:invest_guide/features/alerts/presentation/widgets/add_alert_dialog.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/auth/presentation/providers/auth_providers.dart';
import 'package:invest_guide/features/auth/data/models/user_model.dart';
import 'package:invest_guide/features/auth/presentation/widgets/auth_prompt_dialog.dart';

class AssetDetailPage extends ConsumerStatefulWidget {
  final String assetId;
  final String? symbol;
  final String? name;
  final double? currentPrice;
  final double? priceChange24h;
  final String? categoryId;

  const AssetDetailPage({
    super.key,
    required this.assetId,
    this.symbol,
    this.name,
    this.currentPrice,
    this.priceChange24h,
    this.categoryId,
  });

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  List<FlSpot> _chartData = [];
  List<DateTime> _chartTimestamps = [];
  bool _isLoading = true;
  String _selectedPeriod = '7';
  Map<String, dynamic>? _assetDetails;
  List<dynamic> _news = [];
  bool _isNewsLoading = false;

  // Technical Indicators
  double? _rsi;
  double? _ma20;

  final Map<String, String> _periods = {
    '1': '1D',
    '7': '7D',
    '30': '1M',
    '90': '3M',
    '365': '1Y',
    'max': 'ALL',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isNewsLoading = true);
    try {
      final news = await InvestGuideApi.getNews(limit: 5);
      if (mounted) {
        setState(() {
          _news = news;
          _isNewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isNewsLoading = false);
    }
  }

  void _calculateTechnicals() {
    if (_chartData.length < 14) return;

    // Simple RSI calculation (last 14 points)
    double gains = 0;
    double losses = 0;
    for (var i = _chartData.length - 14; i < _chartData.length - 1; i++) {
      var diff = _chartData[i + 1].y - _chartData[i].y;
      if (diff > 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }
    var rs = gains / (losses == 0 ? 1 : losses);
    _rsi = 100 - (100 / (1 + rs));

    // Simple Moving Averages
    if (_chartData.length >= 20) {
      _ma20 = _chartData
              .sublist(_chartData.length - 20)
              .map((e) => e.y)
              .reduce((a, b) => a + b) /
          20;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Convert period to yfinance format
      var period = '1mo';
      switch (_selectedPeriod) {
        case '1':
          period = '1d';
          break;
        case '7':
          period = '5d';
          break;
        case '30':
          period = '1mo';
          break;
        case '90':
          period = '3mo';
          break;
        case '365':
          period = '1y';
          break;
        case 'max':
          period = 'max';
          break;
      }

      // Fetch market chart data from our unified API
      final historyData =
          await InvestGuideApi.getMarketHistory(widget.assetId, period: period);

      // Fetch detailed stats (PE, Market Cap, Logo etc)
      var detailData = await InvestGuideApi.getAssetDetail(widget.assetId);

      // Fetch robust basic price/info (uses Backend -> CoinGecko -> Yahoo -> Mock fallback)
      final robustAsset = await ref
          .read(assetCacheProvider.notifier)
          .fetchAsset(widget.assetId);

      // Merge robust data into detailData if necessary
      if (robustAsset != null) {
        detailData ??= {};

        // If price is missing or 0, use robust price
        final detailPrice = (detailData['price'] as num?)?.toDouble() ?? 0.0;
        if (detailPrice == 0 && (robustAsset.currentPriceUsd ?? 0) > 0) {
          detailData['price'] = robustAsset.currentPriceUsd;
        }

        // If change is missing or 0, use robust change
        final detailChange =
            (detailData['change_percent'] as num?)?.toDouble() ?? 0.0;
        if (detailChange == 0 && (robustAsset.change24h ?? 0) != 0) {
          detailData['change_percent'] = robustAsset.change24h;
        }

        detailData.putIfAbsent('symbol', () => robustAsset.symbol);
        detailData.putIfAbsent('name', () => robustAsset.name);
        if (robustAsset.description != null) {
          detailData.putIfAbsent('description', () => robustAsset.description);
        }
      }

      if (mounted) {
        setState(() {
          final spots = <FlSpot>[];
          final timestamps = <DateTime>[];

          for (var i = 0; i < historyData.length; i++) {
            final point = historyData[i];
            final price = (point['close'] as num).toDouble();
            final date = DateTime.parse(point['date']);

            spots.add(FlSpot(i.toDouble(), price));
            timestamps.add(date);
          }

          _chartData = spots;
          _chartTimestamps = timestamps;
          _assetDetails = detailData;
          _calculateTechnicals();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error Loading Detail Data: $e');
      if (mounted) {
        // Fallback to widget data if everything fails
        setState(() {
          _isLoading = false;
          // Ensure we display at least what we passed in
          _assetDetails ??= {
            'price': widget.currentPrice,
            'change_percent': widget.priceChange24h,
            'symbol': widget.symbol,
            'name': widget.name,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background(context),
        bottomNavigationBar: _buildBottomBar(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.surface(context),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildModernHeader(),
                stretchModes: const [StretchMode.zoomBackground],
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                _WatchlistToggleAction(
                    assetId: widget.assetId,
                    symbol: widget.symbol ?? _assetDetails?['symbol'] ?? '',
                    name: widget.name ?? _assetDetails?['name'] ?? '',
                    categoryId:
                        widget.categoryId ?? _assetDetails?['category']),
                IconButton(
                  icon:
                      const Icon(Icons.notifications_active_outlined, size: 22),
                  onPressed: () {
                    final authState = ref.read(authNotifierProvider);
                    if (authState is AuthAuthenticated) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AddAlertDialog(
                          assetId: widget.assetId,
                          symbol: widget.symbol ??
                              _assetDetails?['symbol'] ??
                              'UNK',
                          name: widget.name ?? _assetDetails?['name'] ?? '',
                          currentPrice:
                              ((_assetDetails?['price'] as num?)?.toDouble() ??
                                  widget.currentPrice ??
                                  0.0),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (ctx) => AuthPromptDialog(
                          title:
                              lc == 'tr' ? 'Hesap Gerekli' : 'Account Required',
                          description: lc == 'tr'
                              ? 'Fiyat alarmı kurabilmek için lütfen giriş yapın veya kayıt olun.'
                              : 'Please login or sign up to create price alerts.',
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary(context),
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: AppStrings.tr(AppStrings.overview, lc)),
                    Tab(text: AppStrings.tr(AppStrings.statistics, lc)),
                    Tab(text: AppStrings.tr(AppStrings.news, lc)),
                    Tab(text: AppStrings.tr(AppStrings.about, lc)),
                  ],
                ),
              ),
            ),
          ],
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildOverviewTab(),
                    _buildStatisticsTab(),
                    _buildNewsTab(),
                    _buildAboutTab(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    var price = (_assetDetails?['price'] as num?)?.toDouble() ?? 0.0;
    if (price == 0 && widget.currentPrice != null) {
      price = widget.currentPrice!;
    }

    var change24h =
        (_assetDetails?['change_percent'] as num?)?.toDouble() ?? 0.0;
    if (change24h == 0 && widget.priceChange24h != null) {
      change24h = widget.priceChange24h!;
    }

    final isPositive = change24h >= 0;
    final symbol = (_assetDetails?['symbol'] ?? widget.symbol ?? '')
        .toString()
        .toUpperCase();
    final name = (_assetDetails?['name'] ?? widget.name ?? '').toString();

    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 70,
          left: 24,
          right: 24,
          bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface(context),
            AppColors.background(context),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_assetDetails?['logo_url'] != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.shadowSm(context),
                  ),
                  child: Image.network(_assetDetails!['logo_url'],
                      width: 32, height: 32),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      name,
                      style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPriceWithCurrency(price),
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPriceWithCurrency(double price) {
    final currency =
        _assetDetails?['currency']?.toString().toUpperCase() ?? 'USD';
    final sign = currency == 'TRY' ? '₺' : (currency == 'USD' ? '\$' : '');
    return '$sign${_formatPrice(price)}';
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildChart(),
          const SizedBox(height: 24),
          _buildTechnicalsCard(),
          const SizedBox(height: 24),
          _buildQuickStatsStrip(),
        ],
      ),
    );
  }

  Widget _buildTechnicalsCard() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final price = (_assetDetails?['price'] as num?)?.toDouble() ??
        widget.currentPrice ??
        0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr(AppStrings.technicalIndicators, lc),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTechnicalMeter(
                  'RSI (14)',
                  _rsi ?? 50,
                  0,
                  100,
                  (v) => v > 70
                      ? AppStrings.tr(AppStrings.overbought, lc)
                      : (v < 30
                          ? AppStrings.tr(AppStrings.oversold, lc)
                          : AppStrings.tr(AppStrings.neutral, lc))),
              _buildTechnicalMeter(
                  'MA (20)',
                  _ma20 ?? price,
                  0,
                  0,
                  (v) => _chartData.isNotEmpty
                      ? '${AppStrings.tr(AppStrings.price, lc)} ${_chartData.last.y > v ? AppStrings.tr(AppStrings.priceAbove, lc) : AppStrings.tr(AppStrings.priceBelow, lc)}'
                      : AppStrings.tr(AppStrings.insufficientData, lc)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalMeter(String label, double value, double min,
      double max, String Function(double) status) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary(context))),
        const SizedBox(height: 8),
        Text(
            value > 1000 ? _formatLargeNumber(value) : value.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(status(value),
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickStatsStrip() {
    final marketCap = (_assetDetails?['market_cap'] as num?)?.toDouble() ?? 0.0;
    final vol = (_assetDetails?['volume'] as num?)?.toDouble() ?? 0.0;

    final language = ref.watch(languageProvider);
    final lc = language.code;
    return Row(
      children: [
        Expanded(
            child: _buildQuickStat(AppStrings.tr(AppStrings.marketCap, lc),
                _formatLargeNumber(marketCap))),
        const SizedBox(width: 12),
        Expanded(
            child: _buildQuickStat(AppStrings.tr(AppStrings.volume24h, lc),
                _formatLargeNumber(vol))),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatistics(),
          const SizedBox(height: 16),
          _buildMarketData(),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final desc = _assetDetails?['description'] ??
        AppStrings.tr(AppStrings.noDescription, lc);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.tr(AppStrings.about, lc),
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            desc,
            style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textSecondary(context)),
          ),
          if (_assetDetails?['website'] != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.language, size: 18),
              label: Text(AppStrings.tr(AppStrings.officialWebsite, lc)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewsTab() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    if (_isNewsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_news.isEmpty) {
      return Center(child: Text(AppStrings.tr(AppStrings.newsNotFound, lc)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _news.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final news = _news[index];
        return InkWell(
          onTap: () {},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${news['source'] ?? ''} • ${_formatDate(news['date'] ?? '')}',
                      style: TextStyle(
                          color: AppColors.textTertiary(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (news['image'] != null) const SizedBox(width: 16),
              if (news['image'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(news['image'],
                      width: 80, height: 80, fit: BoxFit.cover),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
      ),
      child: Row(
        children: _periods.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = entry.key);
                _loadData();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary(context),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    if (_chartData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(context),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            AppStrings.tr(AppStrings.chartLoadError, lc),
            style: TextStyle(
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      );
    }

    final minY = _chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = _chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 1,
        ),
        boxShadow: AppColors.shadowSm(context),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border(context),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _chartData.length / 5,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getTimeLabel(value.toInt()),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${_formatPrice(value)}',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minY - (range * 0.1),
          maxY: maxY + (range * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: _chartData,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${_formatPrice(spot.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final marketCap = (_assetDetails?['market_cap'] as num?)?.toDouble() ?? 0.0;
    final volume = (_assetDetails?['volume'] as num?)?.toDouble() ?? 0.0;
    final peRatio = (_assetDetails?['pe_ratio'] as num?)?.toDouble();
    final divYield = (_assetDetails?['dividend_yield'] as num?)?.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr(AppStrings.statistics, lc),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(context),
              width: 1,
            ),
            boxShadow: AppColors.shadowSm(context),
          ),
          child: Column(
            children: [
              _buildStatRow(AppStrings.tr(AppStrings.marketCap, lc),
                  marketCap > 0 ? '\$${_formatLargeNumber(marketCap)}' : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.volume, lc),
                  volume > 0 ? _formatLargeNumber(volume) : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.peRatio, lc),
                  peRatio != null ? peRatio.toStringAsFixed(2) : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.dividendYield, lc),
                  divYield != null ? '%${divYield.toStringAsFixed(2)}' : '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketData() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final high52w = (_assetDetails?['high_52w'] as num?)?.toDouble() ?? 0.0;
    final low52w = (_assetDetails?['low_52w'] as num?)?.toDouble() ?? 0.0;
    final avgVolume = (_assetDetails?['avg_volume'] as num?)?.toDouble() ?? 0.0;
    final forwardPE = (_assetDetails?['forward_pe'] as num?)?.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.tr(AppStrings.marketData, lc),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border(context),
              width: 1,
            ),
            boxShadow: AppColors.shadowSm(context),
          ),
          child: Column(
            children: [
              _buildStatRow(AppStrings.tr(AppStrings.high52w, lc),
                  high52w > 0 ? _formatPrice(high52w) : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.low52w, lc),
                  low52w > 0 ? _formatPrice(low52w) : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.avgVolume, lc),
                  avgVolume > 0 ? _formatLargeNumber(avgVolume) : '-'),
              const Divider(height: 24),
              _buildStatRow(AppStrings.tr(AppStrings.expectedPE, lc),
                  forwardPE != null ? forwardPE.toStringAsFixed(2) : '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddPortfolioDialog(),
        icon: const Icon(Icons.add_chart, size: 20),
        label: Text(AppStrings.tr(AppStrings.addToPortfolio, lc),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showAddPortfolioDialog() {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final amountController = TextEditingController();
    final costController = TextEditingController(
        text:
            (_assetDetails?['price'] ?? widget.currentPrice ?? 0.0).toString());
    final currency =
        _assetDetails?['currency']?.toString().toUpperCase() ?? 'USD';
    final sign =
        currency == 'TRY' ? '₺' : (currency == 'USD' ? '\$' : currency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${widget.symbol?.toUpperCase() ?? _assetDetails?['symbol']} ${AppStrings.tr(AppStrings.addToPortfolio, lc)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: AppStrings.tr(AppStrings.unitsLabel, lc),
                border: const OutlineInputBorder(),
                hintText: '0.00',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: InputDecoration(
                labelText:
                    '${AppStrings.tr(AppStrings.averageCostLabel, lc)} ($sign)',
                border: const OutlineInputBorder(),
              ),
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
              final amount = double.tryParse(amountController.text) ?? 0;
              final cost = double.tryParse(costController.text) ?? 0;
              if (amount > 0 && cost > 0) {
                ref
                    .read(portfolioProvider.notifier)
                    .addOrUpdateAsset(PortfolioAsset(
                      id: widget.assetId,
                      symbol: (widget.symbol ?? _assetDetails?['symbol'])
                          .toString()
                          .toUpperCase(),
                      name: widget.name ?? _assetDetails?['name'] ?? '',
                      units: amount,
                      averageCost: cost,
                      category: _assetDetails?['category'],
                      currencyCode: currency,
                    ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(AppStrings.tr(
                        AppStrings.addedToPortfolioSuccess, lc))));
              }
            },
            child: Text(AppStrings.tr(AppStrings.add, lc)),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1) {
      return price.toStringAsFixed(2);
    } else if (price >= 0.01) {
      return price.toStringAsFixed(4);
    } else {
      return price.toStringAsFixed(8);
    }
  }

  String _formatLargeNumber(double number) {
    if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(2)}T';
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }

  String _getTimeLabel(int index) {
    if (_chartTimestamps.isEmpty ||
        index < 0 ||
        index >= _chartTimestamps.length) {
      return '';
    }

    final timestamp = _chartTimestamps[index];

    // Format based on selected period
    switch (_selectedPeriod) {
      case '1':
        // 1 Day: Show hours (e.g., "14:00")
        return DateFormat('HH:mm').format(timestamp);
      case '7':
        // 7 Days: Show day (e.g., "Mon" or "Pzt")
        return DateFormat('E').format(timestamp);
      case '30':
        // 1 Month: Show day and month (e.g., "15 Jan")
        return DateFormat('d MMM').format(timestamp);
      case '90':
      case '365':
        // 3 Months or 1 Year: Show month (e.g., "Jan")
        return DateFormat('MMM').format(timestamp);
      case 'max':
        // All time: Show year (e.g., "2023")
        return DateFormat('yyyy').format(timestamp);
      default:
        return DateFormat('d/M').format(timestamp);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface(context),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _WatchlistToggleAction extends ConsumerWidget {
  final String assetId;
  final String symbol;
  final String name;
  final String? categoryId;

  const _WatchlistToggleAction({
    required this.assetId,
    required this.symbol,
    required this.name,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final isInWatchlist = watchlist.any((item) => item.symbol == symbol);

    return IconButton(
      icon: Icon(
        isInWatchlist ? Icons.star_rounded : Icons.star_outline_rounded,
        color:
            isInWatchlist ? AppColors.warning : AppColors.textPrimary(context),
        size: 24,
      ),
      onPressed: () async {
        final notifier = ref.read(watchlistProvider.notifier);
        final language =
            ref.read(languageProvider); // Use read for event handler
        final lc = language.code;

        try {
          if (isInWatchlist) {
            await notifier.removeFromWatchlist(symbol);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lc == 'tr'
                      ? '$name favorilerden çıkarıldı.'
                      : '$name removed from favorites.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            await notifier.addToWatchlist(WatchlistItem(
              symbol: symbol,
              name: name,
              assetId: assetId,
              category: categoryId ?? 'other',
            ));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lc == 'tr'
                      ? '$name favorilere eklendi.'
                      : '$name added to favorites.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    lc == 'tr' ? 'İşlem başarısız: $e' : 'Action failed: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }
}
