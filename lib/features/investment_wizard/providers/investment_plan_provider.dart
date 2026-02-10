import 'dart:async';
import 'dart:convert';
import 'dart:math'
    as math; // Use 'as math' to avoid conflict if 'pow' was custom
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/investment_plan_data.dart';
import 'package:moneyplan_pro/core/i18n/app_strings.dart';
import 'package:moneyplan_pro/features/wallet/services/ai_processing_service.dart';

const String _planKey = 'investment_plan_data';

class InvestmentPlanNotifier extends StateNotifier<InvestmentPlanData> {
  // Cache SharedPreferences instance
  SharedPreferences? _prefsCache;
  bool _isInitialized = false;

  InvestmentPlanNotifier() : super(InvestmentPlanData()) {
    unawaited(_loadPlan());
  }

  /// Get cached SharedPreferences instance or create new one
  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  Future<void> _loadPlan() async {
    if (_isInitialized) return;

    try {
      final prefs = await _prefs;
      final planJson = prefs.getString(_planKey);

      if (planJson != null && planJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(planJson);
        state = InvestmentPlanData.fromJson(decoded);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading investment plan: $e');
      // Start with empty state on error
      state = InvestmentPlanData();
      _isInitialized = true;
    }
  }

  Future<void> _savePlan() async {
    try {
      final prefs = await _prefs;
      final jsonString = jsonEncode(state.toJson());
      await prefs.setString(_planKey, jsonString);
    } catch (e) {
      debugPrint('Error saving investment plan: $e');
    }
  }

  void updateMonthlyIncome(double value) {
    state = state.copyWith(monthlyIncome: value);
    if (state.hasDebt) {
      state = state.copyWith(monthlyDebtPayment: state.monthlyAvailable);
    }
    unawaited(_savePlan());
  }

  void updateMonthlyExpenses(double value) {
    state = state.copyWith(monthlyExpenses: value);
    if (state.hasDebt) {
      state = state.copyWith(monthlyDebtPayment: state.monthlyAvailable);
    }
    unawaited(_savePlan());
  }

  void updateCurrencyCode(String code) {
    state = state.copyWith(currencyCode: code);
    unawaited(_savePlan());
  }

  void updateHasDebt(bool value) {
    state = state.copyWith(hasDebt: value);
    if (value) {
      state = state.copyWith(monthlyDebtPayment: state.monthlyAvailable);
    } else {
      // Reset debt values if no debt
      state = state.copyWith(debtAmount: 0, monthlyDebtPayment: 0);
    }
    unawaited(_savePlan());
  }

  void updateDebtAmount(double value) {
    state = state.copyWith(debtAmount: value);
    if (state.hasDebt) {
      state = state.copyWith(monthlyDebtPayment: state.monthlyAvailable);
    }
    unawaited(_savePlan());
  }

  void updateMonthlyDebtPayment(double value) {
    state = state.copyWith(monthlyDebtPayment: value);
    unawaited(_savePlan());
  }

  void updateMonthlyInvestmentAmount(double value) {
    var profile = 'muhafazakar';
    if (value >= 5000 && value < 25000) {
      profile = 'dengeli';
    } else if (value >= 25000) {
      profile = 'agresif';
    }
    state =
        state.copyWith(monthlyInvestmentAmount: value, riskProfile: profile);
    unawaited(_savePlan());
  }

  void completeWizard() {
    state = state.copyWith(isCompleted: true);
    unawaited(_savePlan());
  }

  void updateRiskProfile(String profile) {
    state = state.copyWith(riskProfile: profile);
    unawaited(_savePlan());
  }

  void reset() {
    state = InvestmentPlanData();
    unawaited(_savePlan());
  }

  // Investment calculation methods
  double calculateYearlyReturn(
      double monthlyAmount, double annualRate, int years) {
    // Monthly compounding formula: FV = P * [((1 + r)^n - 1) / r]
    // where P = monthly payment, r = monthly interest rate, n = number of months
    final monthlyRate = annualRate / 12 / 100;
    final months = years * 12;

    if (monthlyRate == 0) {
      return monthlyAmount * months;
    }

    return monthlyAmount *
        ((math.pow(1 + monthlyRate, months) - 1) / monthlyRate);
  }

  Map<String, dynamic> calculateInvestmentPlan() {
    final available = state.monthlyAvailable;
    final monthsToPayDebt = state.monthsToPayOffDebt;
    final yearsToPayDebt = state.yearsToPayOffDebt;

    // Conservative estimates for different asset classes (Real Returns - Inflation Adjusted)
    // These are estimated REAL returns (above inflation)
    const conservativeReturn = 3.0; // 3% real return (bonds, defensive assets)
    const moderateReturn = 6.0; // 6% real return (balanced global portfolio)
    const aggressiveReturn =
        9.0; // 9% real return (growth stocks, emerging markets)

    // Monthly compounding with a potential step-up when debt is paid off
    double calculateYearlyReturnWithDebt(
        double initialMonthly,
        double boostAmount,
        int boostAfterMonths,
        double annualRate,
        int totalYears) {
      final monthlyRate = annualRate / 12 / 100;
      final totalMonths = totalYears * 12;
      double balance = 0;

      // Realistic current investment is limited by actual cash left after debt
      final cappedInitial =
          math.max(0.0, math.min(initialMonthly, state.monthlyAfterDebt));

      // Future monthly is the new investment amount after debt payoff,
      // capped by the total available surplus (monthlyAvailable)
      final cappedFuture = math.max(cappedInitial,
          math.min(initialMonthly + boostAmount, state.monthlyAvailable));

      for (var i = 0; i < totalMonths; i++) {
        var currentMonthly = (state.hasDebt && i >= boostAfterMonths)
            ? cappedFuture
            : cappedInitial;

        balance = (balance + currentMonthly) * (1 + monthlyRate);
      }
      return balance;
    }

    // Calculate projections
    Map<String, dynamic> calculateProjection(int years) {
      final months = years * 12;
      final monthsToPayDebt = state.monthsToPayOffDebt;

      final cappedInitial = math.max(
          0.0, math.min(state.monthlyInvestmentAmount, state.monthlyAfterDebt));
      final cappedFuture = math.max(
          cappedInitial,
          math.min(state.monthlyInvestmentAmount + state.monthlyDebtPayment,
              state.monthlyAvailable));

      // Total invested calculation
      double totalInvested = 0;
      if (state.hasDebt && monthsToPayDebt < months) {
        totalInvested = (cappedInitial * monthsToPayDebt) +
            (cappedFuture * (months - monthsToPayDebt));
      } else {
        totalInvested = cappedInitial * months;
      }

      return {
        'totalInvested': totalInvested,
        'conservative': calculateYearlyReturnWithDebt(
            state.monthlyInvestmentAmount,
            state.monthlyDebtPayment,
            monthsToPayDebt,
            conservativeReturn,
            years),
        'moderate': calculateYearlyReturnWithDebt(state.monthlyInvestmentAmount,
            state.monthlyDebtPayment, monthsToPayDebt, moderateReturn, years),
        'aggressive': calculateYearlyReturnWithDebt(
            state.monthlyInvestmentAmount,
            state.monthlyDebtPayment,
            monthsToPayDebt,
            aggressiveReturn,
            years),
        'isSteppedUp': state.hasDebt && monthsToPayDebt < months,
      };
    }

    final projections = {
      '5_years': calculateProjection(5),
      '10_years': calculateProjection(10),
      '20_years': calculateProjection(20),
    };

    return {
      'monthlyAvailable': available,
      'monthsToPayDebt': monthsToPayDebt,
      'yearsToPayDebt': yearsToPayDebt,
      'projections': projections,
      'recommendedAllocation': _getRecommendedAllocation(),
    };
  }

  Future<void> generateAIRecommendations() async {
    // Determine profile text for prompt
    // Determine profile text for prompt based on user selection + amount
    var currentProfile = 'Balanced';
    final userProfile = state.riskProfile.toLowerCase();

    if (userProfile.contains('agresif') || userProfile.contains('aggressive')) {
      currentProfile = 'Aggressive';
    } else if (userProfile.contains('muhafazakar') ||
        userProfile.contains('conservative')) {
      currentProfile = 'Conservative';
    } else if (state.monthlyInvestmentAmount >= 25000) {
      currentProfile = 'Aggressive';
    } else if (state.monthlyInvestmentAmount < 5000) {
      currentProfile = 'Conservative';
    }

    final result = await AIProcessingService.getInvestmentRecommendations(
      monthlyIncome: state.monthlyIncome,
      monthlyExpenses: state.monthlyExpenses,
      totalDebt: state.debtAmount,
      monthlyInvestment: state.monthlyInvestmentAmount,
      currentProfile: currentProfile,
      currency: state.currencyCode,
    );

    if (result != null) {
      state = state.copyWith(aiRecommendation: result);
      await _savePlan();
    }
  }

  Map<String, dynamic> _getRecommendedAllocation() {
    // If AI recommendation exists, use it!
    if (state.aiRecommendation != null) {
      return state.aiRecommendation!;
    }

    // Based on user choice or default to investment amount
    final profile = state.riskProfile;

    if (profile == 'starter' || profile == 'muhafazakar') {
      return {
        'profile': AppStrings.profileStarter,
        'description': AppStrings.descStarter,
        'allocation': {
          AppStrings.allocGold: 30,
          AppStrings.allocMoneyMarket: 30,
          AppStrings.allocBist30: 20,
          AppStrings.allocForexBonds: 20,
        },
        'suggestedAssets': ['GLDTR', 'PPF', 'TI3', 'KRS'],
      };
    } else if (profile == 'balanced' || profile == 'dengeli') {
      return {
        'profile': AppStrings.profileBalanced,
        'description': AppStrings.descBalanced,
        'allocation': {
          AppStrings.allocForeignStocks: 30,
          AppStrings.allocNonBist100: 20,
          AppStrings.allocPreciousMetals: 20,
          AppStrings.allocEurobondFund: 20,
          AppStrings.allocMoneyMarketShort: 10,
        },
        'suggestedAssets': ['AFT', 'IDH', 'KZL', 'IPJ', 'KUB'],
      };
    } else {
      // Aggressive
      return {
        'profile': AppStrings.profileAggressive,
        'description': AppStrings.descAggressive,
        'allocation': {
          AppStrings.allocForeignTech: 30,
          AppStrings.allocBistPopular: 25,
          AppStrings.allocEurobond: 20,
          AppStrings.allocPreciousMetals: 15,
          AppStrings.allocVentureCapital: 10,
        },
        'suggestedAssets': ['YAY', 'TTE', 'IPB', 'TCD', 'AES'],
      };
    }
  }
}

final investmentPlanProvider =
    StateNotifierProvider<InvestmentPlanNotifier, InvestmentPlanData>((ref) {
  return InvestmentPlanNotifier();
});
