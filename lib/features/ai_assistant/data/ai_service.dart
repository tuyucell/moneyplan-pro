import 'package:flutter/foundation.dart';
import 'package:moneyplan_pro/services/api/supabase_service.dart';
import '../domain/models/purchase_advice.dart';

class AiService {
  static final _client = SupabaseService.client;

  /// Checks if user has remaining AI limit and increments usage if allowed
  /// Returns a map with 'allowed', 'message', 'remaining' etc.
  Future<Map<String, dynamic>> checkAndIncrementUsage(
      {required String userId, required String type}) async {
    try {
      final response =
          await _client.rpc('check_and_increment_ai_usage', params: {
        'p_user_id': userId,
        'p_type': type, // 'purchase_advice'
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI Usage Check Error: $e');
      rethrow;
    }
  }

  /// Calls the Purchase Analysis AI logic
  Future<PurchaseAdvice> analyzePurchase({
    required double amount,
    required int installments,
    required double installmentAmount,
    double? customRate,
  }) async {
    try {
      final response = await _client.rpc('analyze_purchase_decision', params: {
        'p_amount': amount,
        'p_installments': installments,
        'p_installment_amount': installmentAmount,
        if (customRate != null) 'p_custom_rate': customRate,
      });

      return PurchaseAdvice.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      rethrow;
    }
  }
}
