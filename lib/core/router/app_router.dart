import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/features/search/presentation/pages/home_page.dart';
import 'package:invest_guide/features/search/presentation/pages/search_results_page.dart';
import 'package:invest_guide/features/search/presentation/pages/category_page.dart';
import 'package:invest_guide/features/search/presentation/pages/asset_detail_page.dart';
import 'package:invest_guide/features/search/presentation/pages/pension_fund_page.dart';
import 'package:invest_guide/features/calculators/pages/life_insurance_page.dart';
import 'package:invest_guide/features/search/presentation/pages/fund_list_page.dart';
import 'package:invest_guide/features/search/data/models/asset.dart';
import 'package:invest_guide/features/exchanges/presentation/pages/exchange_list_page.dart';
import 'package:invest_guide/features/exchanges/presentation/pages/exchange_detail_page.dart';
import 'package:invest_guide/features/search/presentation/pages/news_list_page.dart';
import 'package:invest_guide/features/search/presentation/pages/news_detail_page.dart';
import 'package:invest_guide/core/constants/app_constants.dart';
import 'package:invest_guide/features/tools/presentation/pages/tools_page.dart';
import 'package:invest_guide/features/calculators/pages/compound_interest_page.dart';
import 'package:invest_guide/features/calculators/pages/loan_kmh_calculator_page.dart';
import 'package:invest_guide/features/calculators/pages/retirement_calculator_page.dart';
import 'package:invest_guide/features/calculators/pages/credit_card_assistant_page.dart';
import 'package:invest_guide/features/tools/presentation/pages/scenario_planner_page.dart';
import 'package:invest_guide/features/investment_wizard/pages/investment_wizard_page.dart';
import 'package:invest_guide/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/features/wallet/pages/add_transaction_page.dart';
import 'package:invest_guide/features/wallet/providers/wallet_provider.dart';
import 'package:invest_guide/features/wallet/models/wallet_transaction.dart';
import 'package:invest_guide/features/wallet/models/transaction_category.dart';
import 'package:invest_guide/core/providers/navigation_provider.dart';
import 'package:uuid/uuid.dart';

// Persistent storage for processed deep links to prevent duplicates even after app restarts
class DeepLinkPersistence {
  static const String _prefKey = 'processed_deep_links';
  static const int _maxItems = 100;

  static Future<bool> isProcessed(String linkKey) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    return list.contains(linkKey);
  }

  static Future<void> markProcessed(String linkKey) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];

    if (!list.contains(linkKey)) {
      list.add(linkKey);
      // Keep only the last N items to save space
      final trimmedList = list.length > _maxItems
          ? list.sublist(list.length - _maxItems)
          : list;
      await prefs.setStringList(_prefKey, trimmedList);
    }
  }
}

class QuickAddProcessor extends ConsumerStatefulWidget {
  final GoRouterState state;
  const QuickAddProcessor({super.key, required this.state});

  @override
  ConsumerState<QuickAddProcessor> createState() => _QuickAddProcessorState();
}

class _QuickAddProcessorState extends ConsumerState<QuickAddProcessor> {
  bool _processed = false;

  @override
  void initState() {
    super.initState();
    _handleProcessor();
  }

  @override
  void dispose() {
    debugPrint('WIDGET_LOG: QuickAddProcessor Disposed');
    super.dispose();
  }

  void _handleProcessor() async {
    debugPrint(
        'WIDGET_LOG: _handleProcessor triggered. _processed: $_processed');
    if (_processed) return;
    _processed = true;

    if (!mounted) {
      debugPrint('WIDGET_LOG: Processor triggered but not mounted.');
      return;
    }

    final query = widget.state.uri.queryParameters;
    final amountStr = query['amount'];
    final note = query['note'];
    final categoryParam = query['category'];
    final nonce = query['u'] ?? query['t'] ?? 'unknown';

    // Persistent de-duplication check
    final linkKey = '${widget.state.uri.path}_$nonce';
    final isAlreadyProcessed = await DeepLinkPersistence.isProcessed(linkKey);

    if (isAlreadyProcessed) {
      debugPrint(
          'WIDGET_LOG: Deep link already processed: $linkKey. Redirecting...');
      _redirectToHome();
      return;
    }

    await DeepLinkPersistence.markProcessed(linkKey);
    debugPrint('WIDGET_LOG: Processing new deep link: $linkKey');

    if (amountStr != null) {
      final amount = double.tryParse(amountStr) ?? 0.0;
      var categoryId = 'other_expense';
      if (categoryParam == 'Food') {
        categoryId = (note == 'Kahve') ? 'food_cafe' : 'food_restaurant';
      } else if (categoryParam == 'Shopping') {
        categoryId = 'food_grocery';
      } else if (categoryParam == 'Transport') {
        categoryId = 'transportation_fuel';
      }

      final newTransaction = WalletTransaction(
        id: const Uuid().v4(),
        categoryId: categoryId,
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        isPaid: true,
        note: note ?? 'Hızlı Ekleme',
      );

      // Perform action
      await ref.read(walletProvider.notifier).addTransaction(newTransaction);

      // Notify and redirect
      if (mounted) {
        _showNotification(note, amount);
        _redirectToHome();
      }
    } else {
      _redirectToHome();
    }
  }

  void _redirectToHome() {
    // Switch to wallet tab
    ref.read(bottomNavProvider.notifier).state = 1;
    // Go home
    context.go('/home');
  }

  void _showNotification(String? note, double amount) {
    snackbarKey.currentState?.clearSnackBars();
    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${note?.toUpperCase() ?? "HARCAMA"} EKLENDİ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${amount.toStringAsFixed(0)} ₺ cüzdanınıza işlendi.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 96, // Floating above bottom nav
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String news = '/news';
  static const String newsDetail = '/news-detail';
  static const String exchangeList = '/exchange-list';
  static const String exchangeDetail = '/exchange-detail';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultsPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return Consumer(builder: (context, ref, _) {
            final lc = ref.watch(languageProvider).code;
            final name = state.uri.queryParameters['name'] ??
                AppStrings.tr(AppStrings.categoryLabel, lc);

            if (id == 'pension_fund') {
              return const PensionFundPage();
            } else if (id == 'life_insurance') {
              return const LifeInsurancePage();
            }

            return CategoryPage(categoryId: id, categoryName: name);
          });
        },
      ),
      GoRoute(
        path: '/funds',
        builder: (context, state) => const FundListPage(),
      ),
      GoRoute(
        path: '/exchanges/:assetId',
        builder: (context, state) {
          final assetId = state.pathParameters['assetId']!;
          return AssetDetailPage(assetId: assetId);
        },
      ),
      GoRoute(
        path: exchangeList,
        builder: (context, state) {
          final asset = state.extra as Asset;
          return ExchangeListPage(asset: asset);
        },
      ),
      GoRoute(
        path: '$exchangeDetail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return Consumer(builder: (context, ref, _) {
            final lc = ref.watch(languageProvider).code;
            final name = state.uri.queryParameters['name'] ??
                AppStrings.tr(AppStrings.exchangeLabel, lc);
            final country = state.uri.queryParameters['country'] ?? '';
            final volume =
                double.tryParse(state.uri.queryParameters['volume'] ?? '0') ??
                    0.0;
            final trust =
                int.tryParse(state.uri.queryParameters['trust'] ?? '0') ?? 0;
            return ExchangeDetailPage(
              exchangeId: id,
              exchangeName: name,
              country: country,
              volume24h: volume,
              trustScore: trust,
            );
          });
        },
      ),
      GoRoute(
        path: news,
        builder: (context, state) => const NewsListPage(),
      ),
      GoRoute(
        path: newsDetail,
        builder: (context, state) {
          final newsItem = state.extra as Map<String, dynamic>;
          return NewsDetailPage(newsItem: newsItem);
        },
      ),
      GoRoute(
        path: '/tools',
        builder: (context, state) => const ToolsPage(),
        routes: [
          GoRoute(
            path: 'compound_interest',
            builder: (context, state) => const CompoundInterestPage(),
          ),
          GoRoute(
            path: 'loan_kmh',
            builder: (context, state) => const LoanKmhCalculatorPage(),
          ),
          GoRoute(
            path: 'credit_card_assistant',
            builder: (context, state) => const CreditCardAssistantPage(),
          ),
          GoRoute(
            path: 'retirement',
            builder: (context, state) => const RetirementCalculatorPage(),
          ),
          GoRoute(
            path: 'scenario_planner',
            builder: (context, state) => const ScenarioPlannerPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/investment_wizard',
        builder: (context, state) => const InvestmentWizardPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
      // Deep link dummy routes
      GoRoute(
        path: '/navwallet',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(bottomNavProvider.notifier).state = 1;
              context.go('/home');
            });
            return const SizedBox();
          },
        ),
      ),
      GoRoute(
        path: '/nav-wallet',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(bottomNavProvider.notifier).state = 1;
              context.go('/home');
            });
            return const SizedBox();
          },
        ),
      ),
      GoRoute(
        path: '/quickadd',
        builder: (context, state) => QuickAddProcessor(state: state),
      ),
      GoRoute(
        path: '/addexpense',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(bottomNavProvider.notifier).state = 1;
              context.push('/add-transaction');
            });
            return const HomePage();
          },
        ),
      ),
    ],
    errorBuilder: (context, state) => Consumer(builder: (context, ref, _) {
      final lc = ref.watch(languageProvider).code;
      return Scaffold(
        body: Center(
          child: Text(
              '${AppStrings.tr(AppStrings.pageNotFound, lc)}: ${state.uri.path}'),
        ),
      );
    }),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (mounted) {
      if (hasSeenOnboarding) {
        context.go(AppRouter.home);
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final lc = ref.watch(languageProvider).code;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.tr(AppStrings.investmentGuideLabel, lc),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    });
  }
}
