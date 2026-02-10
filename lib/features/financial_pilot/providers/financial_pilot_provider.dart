import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/services/api/supabase_service.dart';
import '../data/financial_pilot_repository.dart';
import '../domain/models/financial_pilot_data.dart';

// Repository Provider
final financialPilotRepositoryProvider =
    Provider<FinancialPilotRepository>((ref) {
  return FinancialPilotRepository(SupabaseService.client);
});

// State classes
abstract class FinancialPilotState {}

class PilotInitial extends FinancialPilotState {}

class PilotLoading extends FinancialPilotState {}

class PilotError extends FinancialPilotState {
  final String message;
  PilotError(this.message);
}

class PilotLoaded extends FinancialPilotState {
  final FinancialPilotData data;
  final double simulatedAmount;
  final int simulatedInstallments;

  PilotLoaded(this.data,
      {this.simulatedAmount = 0, this.simulatedInstallments = 1});
}

// Logic Provider
class FinancialPilotNotifier extends StateNotifier<FinancialPilotState> {
  final FinancialPilotRepository _repository;

  FinancialPilotNotifier(this._repository)
      : super(PilotInitial()); // Removed automatic loadForecast

  Future<void> loadForecast({
    double simulateAmount = 0,
    int simulateInstallments = 1,
    double? overrideCurrentBalance,
  }) async {
    state = PilotLoading();
    try {
      final data = await _repository.getForecast(
        months: 3,
        simulatePurchaseAmount: simulateAmount,
        simulatePurchaseInstallments: simulateInstallments,
        currentBalance: overrideCurrentBalance ?? 0,
      );
      state = PilotLoaded(data,
          simulatedAmount: simulateAmount,
          simulatedInstallments: simulateInstallments);
    } catch (e) {
      state = PilotError(e.toString());
    }
  }

  // Helper to reset simulation
  void clearSimulation() {
    // We need to keep the last known balance.
    // Ideally store it in a member variable.
    // For now simple reset.
    state = PilotInitial();
  }
}

final financialPilotProvider =
    StateNotifierProvider<FinancialPilotNotifier, FinancialPilotState>((ref) {
  final repo = ref.watch(financialPilotRepositoryProvider);
  return FinancialPilotNotifier(repo);
});
