import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/financial_pilot_data.dart';

class FinancialPilotRepository {
  final SupabaseClient _client;

  FinancialPilotRepository(this._client);

  Future<FinancialPilotData> getForecast({
    int months = 3,
    double simulatePurchaseAmount = 0,
    int simulatePurchaseInstallments = 1,
    double currentBalance = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      final response = await _client.rpc('calculate_financial_pilot', params: {
        'p_user_id': userId,
        'p_months': months,
        'p_simulate_purchase_amount': simulatePurchaseAmount,
        'p_simulate_purchase_installments': simulatePurchaseInstallments,
        'p_current_balance': currentBalance,
      });

      return FinancialPilotData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to calculate forecast: $e');
    }
  }
}
