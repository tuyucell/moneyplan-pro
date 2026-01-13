import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/constants/colors.dart';
import 'package:invest_guide/core/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingItem> _getItems(String lc) {
    return [
      _OnboardingItem(
        title: AppStrings.tr(AppStrings.onboarding1Title, lc),
        description: AppStrings.tr(AppStrings.onboarding1Desc, lc),
        icon: Icons.pie_chart_outline,
        color: AppColors.primary,
      ),
      _OnboardingItem(
        title: AppStrings.tr(AppStrings.onboarding2Title, lc),
        description: AppStrings.tr(AppStrings.onboarding2Desc, lc),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _OnboardingItem(
        title: AppStrings.tr(AppStrings.onboarding3Title, lc),
        description: AppStrings.tr(AppStrings.onboarding3Desc, lc),
        icon: Icons.auto_awesome_outlined,
        color: Colors.purple,
      ),
      _OnboardingItem(
        title: AppStrings.tr(AppStrings.onboarding4Title, lc),
        description: AppStrings.tr(AppStrings.onboarding4Desc, lc),
        icon: Icons.show_chart,
        color: AppColors.warning,
      ),
    ];
  }

  void _onNext(int itemCount) {
    if (_currentPage < itemCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go(AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;
    final items = _getItems(lc);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(AppStrings.tr(AppStrings.btnSkip, lc), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 100,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.grey900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.grey600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(
                       items.length,
                       (index) => AnimatedContainer(
                         duration: const Duration(milliseconds: 300),
                         margin: const EdgeInsets.symmetric(horizontal: 4),
                         height: 8,
                         width: _currentPage == index ? 24 : 8,
                         decoration: BoxDecoration(
                           color: _currentPage == index ? AppColors.primary : AppColors.grey300,
                           borderRadius: BorderRadius.circular(4),
                         ),
                       ),
                     ),
                   ),
                   const Spacer(),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                     child: SizedBox(
                       width: double.infinity,
                       height: 56,
                       child: ElevatedButton(
                         onPressed: () => _onNext(items.length),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.primary,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                           elevation: 0,
                         ),
                         child: Text(
                           _currentPage == items.length - 1 ? AppStrings.tr(AppStrings.btnStart, lc) : AppStrings.tr(AppStrings.btnContinue, lc),
                           style: const TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                             color: Colors.white,
                           ),
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _OnboardingItem({required this.title, required this.description, required this.icon, required this.color});
}
