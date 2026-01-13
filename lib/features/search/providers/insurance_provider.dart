import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invest_guide/core/config/api_config.dart';
import 'package:invest_guide/features/search/data/models/insurance_product.dart';
import 'package:invest_guide/services/api/life_insurance_service.dart';

/// Provider for all insurance products
final insuranceProductsProvider = FutureProvider<ApiResponse<List<InsuranceProduct>>>((ref) async {
  return await LifeInsuranceService.getProducts();
});

/// Provider for savings products only
final savingsProductsProvider = FutureProvider<ApiResponse<List<InsuranceProduct>>>((ref) async {
  return await LifeInsuranceService.getProducts(type: 'savings');
});

/// Provider for term insurance products only
final termProductsProvider = FutureProvider<ApiResponse<List<InsuranceProduct>>>((ref) async {
  return await LifeInsuranceService.getProducts(type: 'term');
});

/// Provider to refresh insurance products
final refreshInsuranceProductsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(insuranceProductsProvider);
    ref.invalidate(savingsProductsProvider);
    ref.invalidate(termProductsProvider);
  };
});
