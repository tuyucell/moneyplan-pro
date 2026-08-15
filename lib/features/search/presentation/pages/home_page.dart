import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/constants/colors.dart';
import 'package:moneyplan_pro/features/search/presentation/pages/markets_page.dart';
import 'package:moneyplan_pro/features/wallet/pages/wallet_page.dart';
import 'package:moneyplan_pro/features/watchlist/pages/watchlist_page.dart';
import 'package:moneyplan_pro/features/profile/presentation/pages/profile_page.dart';
import 'package:moneyplan_pro/features/tools/presentation/pages/tools_page.dart';
import 'package:moneyplan_pro/core/providers/language_provider.dart';
import 'package:moneyplan_pro/core/providers/navigation_provider.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/features/monetization/widgets/banner_ad_widget.dart';
import 'package:moneyplan_pro/core/services/remote_config_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // We need to watch language here to rebuild when it changes
    // But we are in a StatefulWidget using standard State, we need to access ref.
    // So we must convert to ConsumerStatefulWidget OR use Consumer inside.
    // However, HomePage is just a StatefulWidget currently.
    // Let's convert it to ConsumerStatefulWidget to fully support reactive updates.
    return Consumer(
      builder: (context, ref, child) {
        final languageCode = ref.watch(languageProvider).code;
        final selectedIndex = ref.watch(bottomNavProvider);
        final liveMarketsEnabled = ref
            .watch(featureEnabledProvider('live_market_data'))
            .maybeWhen(data: (enabled) => enabled, orElse: () => false);
        final cryptoMarketsEnabled = ref
            .watch(featureEnabledProvider('crypto_market_data'))
            .maybeWhen(data: (enabled) => enabled, orElse: () => false);
        final marketsEnabled = liveMarketsEnabled || cryptoMarketsEnabled;
        final pages = <Widget>[
          marketsEnabled
              ? const MarketsPage()
              : _MarketFeatureUnavailable(languageCode: languageCode),
          const WalletPage(),
          marketsEnabled
              ? const WatchlistPage()
              : _MarketFeatureUnavailable(languageCode: languageCode),
          const ToolsPage(),
          const ProfilePage(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BannerAdWidget(),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    ref.read(bottomNavProvider.notifier).state = index;
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.surface(context),
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
                      label:
                          AppStrings.tr(AppStrings.navWatchlist, languageCode),
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
      },
    );
  }
}

class _MarketFeatureUnavailable extends StatelessWidget {
  final String languageCode;

  const _MarketFeatureUnavailable({required this.languageCode});

  @override
  Widget build(BuildContext context) {
    final isTurkish = languageCode == 'tr';

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(isTurkish ? 'Piyasalar' : 'Markets'),
        backgroundColor: AppColors.surface(context),
        foregroundColor: AppColors.textPrimary(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  isTurkish
                      ? 'Piyasa eğitim araçları yakında'
                      : 'Market education tools are coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isTurkish
                      ? 'Veri sağlayıcı izinleri tamamlanırken bütçe, tasarruf hedefleri ve kendi girdiğiniz portföy kayıtlarını kullanmaya devam edebilirsiniz.'
                      : 'While data-provider permissions are being completed, you can continue using budgeting, savings goals, and your manually entered portfolio records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.45,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
