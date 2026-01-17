import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/services/api/invest_guide_api.dart';

class SearchOverlay extends ConsumerStatefulWidget {
  final String languageCode;

  const SearchOverlay({super.key, required this.languageCode});

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              _controller.text.isEmpty
                                  ? AppStrings.tr(AppStrings.searchHint,
                                      widget.languageCode)
                                  : AppStrings.tr(AppStrings.noDataFound,
                                      widget.languageCode),
                              style: TextStyle(
                                color: AppColors.textSecondary(context),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return _buildResultItem(item);
                          },
                        ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);
    _showOverlay();

    try {
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
          _searchResults = filtered.take(10).toList(); // Limit to 10 results
          _isLoading = false;
        });
        if (filtered.isNotEmpty) {
          _showOverlay();
        }
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
      }
    }
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    final isUp = (item['change'] ?? 0) >= 0;
    final changeStr =
        '${isUp ? '+' : ''}${(item['change'] ?? 0).toStringAsFixed(2)}%';

    return InkWell(
      onTap: () {
        _removeOverlay();
        _focusNode.unfocus();

        // Navigate directly to asset detail page
        final assetId = item['id'];

        if (assetId != null && assetId.toString().isNotEmpty) {
          context.push('/exchanges/$assetId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.background(context),
          border: Border.all(
            color: AppColors.border(context).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
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
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['symbol'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(item['price'] as num).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  changeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUp ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.primary
                : AppColors.border(context).withValues(alpha: 0.5),
            width: _focusNode.hasFocus ? 1.5 : 1,
          ),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: _focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText:
                      AppStrings.tr(AppStrings.searchHint, widget.languageCode),
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _performSearch(value);
                  } else {
                    setState(() => _searchResults = []);
                    _removeOverlay();
                  }
                },
                onTap: () {
                  if (_controller.text.length >= 2) {
                    _showOverlay();
                  }
                },
              ),
            ),
            if (_controller.text.isNotEmpty)
              InkWell(
                onTap: () {
                  _controller.clear();
                  setState(() => _searchResults = []);
                  _removeOverlay();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.clear,
                    size: 18,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
