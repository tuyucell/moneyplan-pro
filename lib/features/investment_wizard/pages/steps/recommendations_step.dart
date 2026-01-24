import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/investment_plan_provider.dart';
import '../../../watchlist/providers/watchlist_provider.dart';
import '../../../watchlist/models/watchlist_item.dart';
import '../../widgets/investment_wizard_widgets.dart';
import 'package:invest_guide/features/search/presentation/pages/asset_detail_page.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class RecommendationsStep extends ConsumerStatefulWidget {
  final VoidCallback onReset;
  final VoidCallback? onPrevious;

  const RecommendationsStep({
    super.key,
    required this.onReset,
    this.onPrevious,
  });

  @override
  ConsumerState<RecommendationsStep> createState() =>
      _RecommendationsStepState();
}

class _RecommendationsStepState extends ConsumerState<RecommendationsStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadAI();
    });
  }

  Future<void> _checkAndLoadAI() async {
    final plan = ref.read(investmentPlanProvider);
    if (plan.aiRecommendation == null) {
      await ref
          .read(investmentPlanProvider.notifier)
          .generateAIRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
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
    } else {
      // AI returned custom profile string maybe? Use description if available or just raw profile
      if (allocation['description'] != null) {
        // If AI returned a custom description, we might want to use it
        // For now, allow raw profile string if translation fails or is custom
        if (profileTitle == profile && profile != 'muhafazakar') {
          profileTitle = profile;
        }
      }
    }

    final plan = ref.watch(investmentPlanProvider);
    final projections = results['projections'] as Map<String, dynamic>;
    final riskKey = (profile == 'starter' ||
            profile == 'muhafazakar' ||
            profile == 'Conservative')
        ? 'conservative'
        : (profile == 'balanced' ||
                profile == 'dengeli' ||
                profile == 'Balanced')
            ? 'moderate'
            : 'aggressive';

    final fiveYearResult = projections['5_years'][riskKey] as double;
    final tenYearResult = projections['10_years'][riskKey] as double;
    final numberFormat = NumberFormat('#,##0', lc == 'tr' ? 'tr_TR' : 'en_US');
    final currencySymbol = plan.currencyDisplay;

    // Show loading state if AI plan is not ready yet
    if (plan.aiRecommendation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              lc == 'tr'
                  ? 'Yapay Zeka Yatırım Planınızı Hazırlıyor...'
                  : 'AI is creating your investment plan...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lc == 'tr'
                  ? 'Piyasa verileri ve risk profiliniz analiz ediliyor.'
                  : 'Analyzing market data and your risk profile.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            AppStrings.tr(AppStrings.portfolioRecsTitle, lc),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 16),

          // Consolidated Investment Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CompactHeaderStat(
                      label: lc == 'tr' ? 'Hedef Yatırım' : 'Target Investment',
                      value:
                          '${numberFormat.format(plan.monthlyInvestmentAmount)} $currencySymbol',
                    ),
                    if (plan.hasDebt && plan.monthlyDebtPayment > 0)
                      _CompactHeaderStat(
                        label:
                            lc == 'tr' ? 'Aktif Kapasite' : 'Current Capacity',
                        value:
                            '${numberFormat.format(math.max(0, plan.monthlyAfterDebt < plan.monthlyInvestmentAmount ? plan.monthlyAfterDebt : plan.monthlyInvestmentAmount))} $currencySymbol',
                        isSecondary: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ProjectionDetailCol(
                        title: '5 ${AppStrings.tr(AppStrings.years, lc)}',
                        total: fiveYearResult,
                        principal:
                            projections['5_years']['totalInvested'] as double,
                        format: numberFormat,
                        symbol: currencySymbol,
                        lc: lc,
                      ),
                    ),
                    Container(width: 1, height: 50, color: Colors.white12),
                    Expanded(
                      child: _ProjectionDetailCol(
                        title: '10 ${AppStrings.tr(AppStrings.years, lc)}',
                        total: tenYearResult,
                        principal:
                            projections['10_years']['totalInvested'] as double,
                        format: numberFormat,
                        symbol: currencySymbol,
                        lc: lc,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile Info (Minimal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.tr(AppStrings.suitableProfileMsg, lc)}$profileTitle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Allocation Section
          _SectionCard(
            title: AppStrings.tr(AppStrings.recAllocationTitle, lc),
            icon: Icons.pie_chart_outline,
            padding: const EdgeInsets.all(16),
            children: [
              ...(allocation['allocation'] as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                final label = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InvestmentAllocationBar(
                    label: AppStrings.tr(label, lc),
                    percentage: entry.value as int,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Suggested Assets Section
          _SectionCard(
            title: AppStrings.tr(AppStrings.recAssetsTitle, lc),
            icon: Icons.list_alt_outlined,
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (allocation['suggestedAssets'] as List<dynamic>)
                    .map((symbol) {
                  final watchlist = ref.watch(watchlistProvider);
                  final isInWatchlist =
                      watchlist.any((item) => item.symbol == symbol);
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
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
                              left: Radius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Text(
                              symbol,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (isInWatchlist) {
                              await ref
                                  .read(watchlistProvider.notifier)
                                  .removeFromWatchlist(symbol);
                            } else {
                              await ref
                                  .read(watchlistProvider.notifier)
                                  .addToWatchlist(WatchlistItem(
                                    symbol: symbol,
                                    name: symbol,
                                    category: 'stock',
                                    assetId: symbol,
                                  ));

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(language.code == 'tr'
                                        ? '$symbol izleme listesine eklendi'
                                        : '$symbol added to watchlist'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(
                            isInWatchlist
                                ? Icons.check_circle
                                : Icons
                                    .add_circle_outline, // Changed icons for better visibility
                            size: 20, // Slightly larger
                            color: isInWatchlist
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (widget.onPrevious != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                    child: Text(AppStrings.tr(AppStrings.back, lc),
                        style:
                            TextStyle(color: AppColors.textPrimary(context))),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.border(context)),
                  ),
                  child: Text(
                    AppStrings.tr(AppStrings.createNewPlanBtn, lc),
                    style: TextStyle(color: AppColors.textPrimary(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(bottomNavProvider.notifier).state = 0; // Markets tab
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
        ],
      ),
    );
  }
}

class _CompactHeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecondary;

  const _CompactHeaderStat({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSecondary ? Colors.white70 : Colors.white60,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSecondary
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ProjectionDetailCol extends StatelessWidget {
  final String title;
  final double total;
  final double principal;
  final NumberFormat format;
  final String symbol;
  final String lc;

  const _ProjectionDetailCol({
    required this.title,
    required this.total,
    required this.principal,
    required this.format,
    required this.symbol,
    required this.lc,
  });

  @override
  Widget build(BuildContext context) {
    final interest = total - principal;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${format.format(total)} $symbol',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SubStat(
                label: lc == 'tr' ? 'Anapara' : 'Principal',
                value: format.format(principal)),
            const SizedBox(width: 8),
            _SubStat(
                label: lc == 'tr' ? 'Getiri' : 'Return',
                value: format.format(interest),
                isGreen: true),
          ],
        ),
      ],
    );
  }
}

class _SubStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _SubStat(
      {required this.label, required this.value, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF4ADE80) : Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsets? padding;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
