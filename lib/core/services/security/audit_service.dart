import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';

class AuditService {
  final SupabaseClient _supabase;

  AuditService(this._supabase);

  /// Log a critical action
  Future<void> logAction({
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('audit_logs').insert({
        'user_id': user.id,
        'action': action,
        'details': details ?? {},
        // IP address might be handled by Supabase edge functions or backend if needed for higher accuracy
        // For client-side logging, we often omit IP or let the server trigger handle it.
      });
      debugPrint('Audit Log: $action');
    } catch (e) {
      debugPrint('Audit Log Error: $e');
    }
  }
}

final auditServiceProvider = Provider<AuditService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuditService(supabase);
});
