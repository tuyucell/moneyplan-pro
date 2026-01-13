import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../providers/investment_plan_provider.dart';
import 'steps/welcome_step.dart';
import 'steps/income_expense_step.dart';
import 'steps/debt_step.dart';
import 'steps/investment_amount_step.dart';
import 'steps/results_step.dart';
import 'steps/recommendations_step.dart';

import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';

class InvestmentWizardPage extends ConsumerStatefulWidget {
  const InvestmentWizardPage({super.key});

  @override
  ConsumerState<InvestmentWizardPage> createState() =>
      _InvestmentWizardPageState();
}

class _InvestmentWizardPageState extends ConsumerState<InvestmentWizardPage> {
  late PageController _pageController;
  int _currentPage = 0;

  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _debtAmountController = TextEditingController();
  final TextEditingController _debtPaymentController = TextEditingController();
  final TextEditingController _investmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    _expensesController.dispose();
    _debtAmountController.dispose();
    _debtPaymentController.dispose();
    _investmentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int page) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _resetWizard() {
    ref.read(investmentPlanProvider.notifier).reset();
    _pageController.jumpToPage(0);
    _incomeController.clear();
    _expensesController.clear();
    _debtAmountController.clear();
    _debtPaymentController.clear();
    _investmentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Listen for state changes to restore saved session
    ref.listen(investmentPlanProvider, (previous, next) {
      if ((previous == null || !previous.isCompleted) && next.isCompleted) {
        if (_currentPage == 0 && _pageController.hasClients) {
          _pageController.jumpToPage(5);
          setState(() {
            _currentPage = 5;
          });
        }
      }
    });

    // Check initial state locally
    final plan = ref.read(investmentPlanProvider);
    if (plan.isCompleted && _currentPage == 0) {
      Future.microtask(() {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(5);
          setState(() {
            _currentPage = 5;
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.surface(context),
        title: Text(AppStrings.tr(AppStrings.investmentPlanTitle, lc)),
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface(context),
              child: Row(
                children: List.generate(6, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : AppColors.grey600.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                  if (page == 5) {
                    ref.read(investmentPlanProvider.notifier).completeWizard();
                  }
                },
                children: [
                  WelcomeStep(onNext: _nextPage),
                  IncomeExpenseStep(
                    incomeController: _incomeController,
                    expensesController: _expensesController,
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                  ),
                  DebtStep(
                    debtAmountController: _debtAmountController,
                    debtPaymentController: _debtPaymentController,
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                  ),
                  InvestmentAmountStep(
                    investmentController: _investmentController,
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                    onJumpToIncome: () => _goToStep(1),
                  ),
                  ResultsStep(
                    onNext: _nextPage,
                    onPrevious: _previousPage,
                  ),
                  RecommendationsStep(onReset: _resetWizard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
