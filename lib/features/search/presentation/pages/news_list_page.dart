import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/services/api/moneyplan_pro_api.dart';
import 'package:moneyplan_pro/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/monetization/services/ad_service.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/features/shared/widgets/notification_badge_icon.dart';

class NewsListPage extends ConsumerStatefulWidget {
  const NewsListPage({super.key});

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  List<dynamic> _news = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final news = await MoneyPlanProApi.getNews(limit: 50);
      if (mounted) {
        setState(() {
          _news = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getDefaultImage(String title, String source) {
    final t = title.toLowerCase();
    if (t.contains('btc') ||
        t.contains('bitcoin') ||
        t.contains('kripto') ||
        t.contains('coin')) {
      return 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('altın') || t.contains('gold') || t.contains('ons')) {
      return 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('dolar') ||
        t.contains('usd') ||
        t.contains('döviz') ||
        t.contains('kur')) {
      return 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('hisse') ||
        t.contains('borsa') ||
        t.contains('bist')) {
      return 'https://images.unsplash.com/photo-1611974714851-48206132973b?q=80&w=500&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=500&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          AppStrings.tr(AppStrings.financeNewsTitle, lc),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: false,
        actions: const [
          NotificationBadgeIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _news.isEmpty
              ? Center(child: Text(AppStrings.tr(AppStrings.newsNotFound, lc)))
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _news.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _news[index];
                      final imageUrl = (item['image_url'] != null &&
                              item['image_url'].toString().isNotEmpty)
                          ? item['image_url']
                          : _getDefaultImage(
                              item['title'] ?? '', item['source'] ?? '');

                      return InkWell(
                        onTap: () async {
                          await ref
                              .read(adServiceProvider.notifier)
                              .showInterstitialAd(context);
                          if (context.mounted) {
                            await context.push(AppRouter.newsDetail,
                                extra: item);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border(context)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 100,
                                    height: 100,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(Icons.newspaper,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item['source']?.toUpperCase() ??
                                                AppStrings.tr(
                                                    AppStrings
                                                        .newsSourceDefault,
                                                    lc),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            item['pub_date'] != null
                                                ? item['pub_date']
                                                    .toString()
                                                    .split(' ')
                                                    .take(3)
                                                    .join(' ')
                                                : '',
                                            style: TextStyle(
                                              color: AppColors.textTertiary(
                                                  context),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item['title'] ?? '',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(context),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['description'] ?? '',
                                        style: TextStyle(
                                          color:
                                              AppColors.textSecondary(context),
                                          fontSize: 12,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
