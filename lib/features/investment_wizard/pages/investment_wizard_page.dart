import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../providers/investment_plan_provider.dart';
import '../models/investment_plan_data.dart';
import 'steps/welcome_step.dart';
import 'steps/income_expense_step.dart';
import 'steps/debt_step.dart';
import 'steps/investment_amount_step.dart';
import 'steps/results_step.dart';
import 'steps/recommendations_step.dart';

import 'package:invest_guide/core/i18n/app_strings.dart';
import 'package:invest_guide/core/providers/language_provider.dart';
import 'package:invest_guide/services/analytics/analytics_service.dart';
import 'package:invest_guide/features/subscription/presentation/widgets/pro_feature_gate.dart';

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
  final TextEditingController _investmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final plan = ref.read(investmentPlanProvider);
    _currentPage = plan.isCompleted ? 5 : 0;
    _pageController = PageController(initialPage: _currentPage);

    // Initialize controllers with existing data
    _updateControllersFromPlan(plan);

    // Analytics: Start Wizard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent(
            name: 'investment_wizard_start',
            category: 'engagement',
            properties: {
              'source': 'direct',
              'is_resume': plan.monthlyIncome > 0
            },
            screenName: 'InvestmentWizardPage',
          );
    });
  }

  void _updateControllersFromPlan(InvestmentPlanData plan) {
    if (plan.monthlyIncome > 0) {
      _incomeController.text = plan.monthlyIncome.toStringAsFixed(0);
    }
    if (plan.monthlyExpenses > 0) {
      _expensesController.text = plan.monthlyExpenses.toStringAsFixed(0);
    }
    if (plan.debtAmount > 0) {
      _debtAmountController.text = plan.debtAmount.toStringAsFixed(0);
    }
    if (plan.monthlyInvestmentAmount > 0) {
      _investmentController.text =
          plan.monthlyInvestmentAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    _expensesController.dispose();
    _debtAmountController.dispose();
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
    _investmentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final lc = language.code;

    // Listen for state changes to restore saved session or update controllers
    ref.listen(investmentPlanProvider, (previous, next) {
      // If data was just loaded (previous was initial empty state, next has data)
      if (previous != null &&
          previous.monthlyIncome == 0 &&
          next.monthlyIncome > 0) {
        _updateControllersFromPlan(next);
      }

      if ((previous == null || !previous.isCompleted) && next.isCompleted) {
        if (_currentPage != 5 && _pageController.hasClients) {
          _pageController.animateToPage(
            5,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    return ProFeatureGate(
      featureName: AppStrings.tr(AppStrings.investmentPlanTitle, lc),
      isFullPage: true,
      child: Scaffold(
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
                      ref
                          .read(investmentPlanProvider.notifier)
                          .completeWizard();

                      // Analytics: Complete Wizard
                      ref.read(analyticsServiceProvider).logEvent(
                            name: 'investment_wizard_complete',
                            category: 'engagement',
                            properties: {
                              'income': _incomeController.text,
                              'expenses': _expensesController.text,
                              'debt': _debtAmountController.text,
                            },
                            screenName: 'InvestmentWizardPage',
                          );
                    } else {
                      // Analytics: Step change
                      ref.read(analyticsServiceProvider).logEvent(
                            name: 'investment_wizard_step',
                            category: 'engagement',
                            properties: {'step_index': page},
                            screenName: 'InvestmentWizardPage',
                          );
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
                    RecommendationsStep(
                      onReset: _resetWizard,
                      onPrevious: _previousPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
