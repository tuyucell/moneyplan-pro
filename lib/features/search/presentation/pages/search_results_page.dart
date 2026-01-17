import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

import 'package:invest_guide/services/api/invest_guide_api.dart'; // Added Import

class SearchResultsPage extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      // Fetch data from multiple sources in parallel
      final results = await Future.wait([
        InvestGuideApi.getStocks(),
        InvestGuideApi.getCryptoMarkets(limit: 100),
        InvestGuideApi.getCurrencies(),
        InvestGuideApi.getCommodities(),
      ]);

      final allItems = <Map<String, dynamic>>[];

      // Process Stocks
      for (var item in results[0]) {
        allItems.add({
          'type': 'Stock',
          'symbol': item['symbol'],
          'name': item['name'],
          'price': item['price'],
          'change': item['change_percent'],
          'id': item['id'] ?? item['symbol']
        });
      }

      // Process Crypto
      for (var item in results[1]) {
        allItems.add({
          'type': 'Crypto',
          'symbol': item['symbol'].toString().toUpperCase(),
          'name': item['name'],
          'price': item['price'],
          'change': item['change_24h'],
          'image': item['image'],
          'id': item['id']
        });
      }

      // Process Currencies
      for (var item in results[2]) {
        allItems.add({
          'type': 'Forex',
          'symbol': item['symbol'],
          'name': item['name'],
          'price': item['price'],
          'change': 0.0,
          'id': item['symbol']
        });
      }

      // Process Commodities
      for (var item in results[3]) {
        allItems.add({
          'type': 'Commodity',
          'symbol': item['symbol'],
          'name': item['name'],
          'price': item['price'],
          'change': item['change_percent'],
          'id': item['id'] ?? item['symbol']
        });
      }

      // Filter locally
      final lowerQuery = query.toLowerCase();
      final filtered = allItems.where((item) {
        final symbol = (item['symbol'] ?? '').toString().toLowerCase();
        final name = (item['name'] ?? '').toString().toLowerCase();
        return symbol.contains(lowerQuery) || name.contains(lowerQuery);
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.border(context).withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: widget.initialQuery.isEmpty,
            style:
                TextStyle(fontSize: 14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: AppStrings.tr(AppStrings.searchHint, lc),
              hintStyle: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary(context)),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              prefixIcon: Icon(Icons.search,
                  size: 16, color: AppColors.textSecondary(context)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _currentQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (val) {
              _performSearch(val);
            },
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: AppColors.textSecondary(context)),
                      const SizedBox(height: 16),
                      Text(
                        _currentQuery.isEmpty
                            ? AppStrings.tr(AppStrings.searchHint, lc)
                            : AppStrings.tr(AppStrings.noDataFound, lc),
                        style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return _buildResultItem(context, item);
                  },
                ),
    );
  }

  Widget _buildResultItem(BuildContext context, Map<String, dynamic> item) {
    final isUp = (item['change'] ?? 0) >= 0;
    final changeStr =
        '${isUp ? '+' : ''}${(item['change'] ?? 0).toStringAsFixed(2)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        onTap: () {
          // Basic navigation - details not implemented for all types yet
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
              item['type'] == 'Crypto'
                  ? Icons.currency_bitcoin
                  : item['type'] == 'Stock'
                      ? Icons.candlestick_chart
                      : item['type'] == 'Forex'
                          ? Icons.currency_exchange
                          : Icons.diamond,
              color: AppColors.primary,
              size: 20),
        ),
        title: Text(
          item['symbol'],
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context)),
        ),
        subtitle: Text(
          item['name'],
          style:
              TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item['price']}', // Formatting needed ideally
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context)),
            ),
            Text(
              changeStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUp ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
