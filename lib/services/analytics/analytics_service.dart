import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moneyplan_pro/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsService {
  final SupabaseClient _supabase;
  String? _currentSessionId;
  final Set<String> _verifiedUserIds = {};

  AnalyticsService(this._supabase);

  Future<void> logEvent({
    required String name,
    required String category,
    Map<String, dynamic>? properties,
    String? screenName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if user exists in public.users to avoid FK error
      if (!_verifiedUserIds.contains(user.id)) {
        final userExists = await _supabase
            .from('users')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (userExists == null) {
          return;
        }
        _verifiedUserIds.add(user.id);
      }

      await _supabase.from('user_events').insert({
        'user_id': user.id,
        'session_id': _currentSessionId,
        'event_name': name,
        'event_category': category,
        'properties': properties ?? {},
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Analytics Error: $e');
    }
  }

  Future<void> logPageEngagement({
    required String pagePath,
    required int durationSeconds,
  }) async {
    await logEvent(
      name: 'page_view',
      category: 'navigation',
      properties: {
        'page_path': pagePath,
        'duration_seconds': durationSeconds,
      },
      screenName: pagePath,
    );
  }

  Future<void> startSession(Map<String, dynamic> deviceInfo) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if user exists in public.users to avoid FK error
      if (!_verifiedUserIds.contains(user.id)) {
        final userExists = await _supabase
            .from('users')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();

        if (userExists == null) {
          debugPrint(
              'Analytics: User ${user.id} not found in public.users, skipping session start.');
          return;
        }
        _verifiedUserIds.add(user.id);
      }

      final response = await _supabase
          .from('user_sessions')
          .insert({
            'user_id': user.id,
            'device_info': deviceInfo,
            'platform': kIsWeb
                ? 'web'
                : (defaultTargetPlatform == TargetPlatform.iOS
                    ? 'ios'
                    : 'android'),
            'session_start': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _currentSessionId = response['id'];
    } catch (e) {
      debugPrint('Session Start Error: $e');
    }
  }

  Future<void> endSession() async {
    if (_currentSessionId == null) return;

    try {
      await _supabase.from('user_sessions').update({
        'session_end': DateTime.now().toIso8601String(),
      }).eq('id', _currentSessionId!);

      _currentSessionId = null;
    } catch (e) {
      debugPrint('Session End Error: $e');
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AnalyticsService(supabase);
});
