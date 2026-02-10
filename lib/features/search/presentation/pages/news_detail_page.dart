import 'package:flutter/material.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailPage({super.key, required this.newsItem});

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Launch Error: $e');
    }
  }

  String _getDefaultImage(String title) {
    final t = title.toLowerCase();
    if (t.contains('btc') || t.contains('bitcoin') || t.contains('kripto')) {
      return 'https://images.unsplash.com/photo-1518546305927-5a555bb7020d?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('altın') || t.contains('gold')) {
      return 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('dolar') || t.contains('usd') || t.contains('döviz')) {
      return 'https://images.unsplash.com/photo-1580519542036-c47de6196ba5?q=80&w=500&auto=format&fit=crop';
    } else if (t.contains('hisse') || t.contains('borsa') || t.contains('bist')) {
      return 'https://images.unsplash.com/photo-1611974714851-48206132973b?q=80&w=500&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=500&auto=format&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (newsItem['image_url'] != null && newsItem['image_url'].toString().isNotEmpty)
        ? newsItem['image_url']
        : _getDefaultImage(newsItem['title'] ?? '');

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.newspaper, size: 64, color: AppColors.primary),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          newsItem['source']?.toUpperCase() ?? 'HABER',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        newsItem['pub_date'] ?? '',
                        style: TextStyle(
                          color: AppColors.textTertiary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    newsItem['title'] ?? '',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: AppColors.border(context)),
                  const SizedBox(height: 24),
                  Text(
                    newsItem['description'] ?? '',
                    style: TextStyle(
                      color: AppColors.textPrimary(context).withValues(alpha: 0.8),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _launchUrl(newsItem['link'] ?? ''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'HABERİN DEVAMINI OKU',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
