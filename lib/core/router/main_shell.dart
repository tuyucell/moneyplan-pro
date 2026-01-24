import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/monetization/widgets/banner_ad_widget.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider).code;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // Handled by container
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary(context),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.trending_up_outlined),
                  activeIcon: const Icon(Icons.trending_up),
                  label: AppStrings.tr(AppStrings.navMarkets, languageCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: const Icon(Icons.account_balance_wallet),
                  label: AppStrings.tr(AppStrings.navWallet, languageCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bookmark_outline),
                  activeIcon: const Icon(Icons.bookmark),
                  label: AppStrings.tr(AppStrings.navWatchlist, languageCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.apps_outlined),
                  activeIcon: const Icon(Icons.apps),
                  label: AppStrings.tr(AppStrings.navTools, languageCode),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: AppStrings.tr(AppStrings.navProfile, languageCode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
