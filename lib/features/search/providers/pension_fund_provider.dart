import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/core/config/api_config.dart';
import 'package:moneyplan_pro/features/search/data/models/pension_fund.dart';
import 'package:moneyplan_pro/services/api/pension_fund_service.dart';

/// Provider for all pension funds
final pensionFundsProvider = FutureProvider<ApiResponse<List<PensionFund>>>((ref) async {
  return await PensionFundService.getFunds();
});

/// Provider for interest-based funds only
final interestFundsProvider = FutureProvider<ApiResponse<List<PensionFund>>>((ref) async {
  return await PensionFundService.getFunds(type: 'interest');
});

/// Provider for participation funds only
final participationFundsProvider = FutureProvider<ApiResponse<List<PensionFund>>>((ref) async {
  return await PensionFundService.getFunds(type: 'participation');
});

/// Provider to refresh pension funds
final refreshPensionFundsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(pensionFundsProvider);
    ref.invalidate(interestFundsProvider);
    ref.invalidate(participationFundsProvider);
  };
});
