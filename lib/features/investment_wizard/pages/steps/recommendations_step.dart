import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/investment_plan_provider.dart';
import '../../../watchlist/providers/watchlist_provider.dart';
import '../../../watchlist/models/watchlist_item.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:invest_guide/features/search/presentation/pages/asset_detail_page.dart';
import 'package:go_router/go_router.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class RecommendationsStep extends ConsumerWidget {
  final VoidCallback onReset;

  const RecommendationsStep({
    super.key,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(investmentPlanProvider.notifier);
    final results = notifier.calculateInvestmentPlan();
    final allocation = results['recommendedAllocation'] as Map<String, dynamic>;
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // We need to translate dynamic values like 'Conservative', 'Balanced' which come from logic
    final profile = allocation['profile'] as String;
    // Map internal profile keys to localized strings with return info
    var profileTitle = AppStrings.tr(profile, lc);
    if (profile == AppStrings.profileStarter) {
      profileTitle =
          '${AppStrings.tr(AppStrings.profileStarter, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %3)';
    } else if (profile == AppStrings.profileBalanced) {
      profileTitle =
          '${AppStrings.tr(AppStrings.profileBalanced, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %6)';
    } else if (profile == AppStrings.profileAggressive) {
      profileTitle =
          '${AppStrings.tr(AppStrings.profileAggressive, lc)} (${AppStrings.tr(AppStrings.realReturn, lc)} %9)';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            AppStrings.tr(AppStrings.portfolioRecsTitle, lc),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.tr(AppStrings.suitableProfileMsg, lc)}$profileTitle',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 32),

          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profileTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            AppStrings.tr(allocation['description'], lc),
                            // Ideally provider should return keys, but for now we display as is or map it if possible.
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Allocation Section
          _SectionCard(
            title: AppStrings.tr(AppStrings.recAllocationTitle, lc),
            icon: Icons.pie_chart_outline,
            children: [
              ...(allocation['allocation'] as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                final label = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InvestmentAllocationBar(
                    label: AppStrings.tr(label, lc),
                    percentage: entry.value as int,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 24),

          // Suggested Assets Section
          _SectionCard(
            title: AppStrings.tr(AppStrings.recAssetsTitle, lc),
            icon: Icons.list_alt_outlined,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: (allocation['suggestedAssets'] as List<dynamic>)
                    .map((symbol) {
                  final watchlist = ref.watch(watchlistProvider);
                  final isInWatchlist =
                      watchlist.any((item) => item.symbol == symbol);
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssetDetailPage(
                                  assetId: symbol,
                                  symbol: symbol,
                                  name: symbol,
                                ),
                              ),
                            );
                          },
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(
                              symbol,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        IconButton(
                          icon: Icon(
                            isInWatchlist ? Icons.star : Icons.star_border,
                            size: 18,
                            color: isInWatchlist
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                          onPressed: () {
                            final watchlistItem =
                                WatchlistItem(symbol: symbol, name: symbol);
                            if (isInWatchlist) {
                              ref
                                  .read(watchlistProvider.notifier)
                                  .removeFromWatchlist(symbol);
                            } else {
                              ref
                                  .read(watchlistProvider.notifier)
                                  .addToWatchlist(watchlistItem);
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go(AppRouter.home);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppStrings.tr(AppStrings.returnHomeBtn, lc),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.border(context)),
              ),
              child: Text(AppStrings.tr(AppStrings.createNewPlanBtn, lc),
                  style: TextStyle(color: AppColors.textPrimary(context))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
