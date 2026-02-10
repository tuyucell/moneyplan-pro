import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailIntegrationNotifier extends StateNotifier<EmailIntegrationState> {
  EmailIntegrationNotifier() : super(const EmailIntegrationState()) {
    _loadState();
  }

  static const String _gmailConnectedKey = 'gmail_connected';
  static const String _outlookConnectedKey = 'outlook_connected';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = EmailIntegrationState(
      isGmailConnected: prefs.getBool(_gmailConnectedKey) ?? false,
      isOutlookConnected: prefs.getBool(_outlookConnectedKey) ?? false,
    );
  }

  Future<void> setGmailConnected(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gmailConnectedKey, connected);
    state = state.copyWith(isGmailConnected: connected);
  }

  Future<void> setOutlookConnected(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_outlookConnectedKey, connected);
    state = state.copyWith(isOutlookConnected: connected);
  }

  bool get hasEmailIntegration =>
      state.isGmailConnected || state.isOutlookConnected;
}

class EmailIntegrationState {
  final bool isGmailConnected;
  final bool isOutlookConnected;

  const EmailIntegrationState({
    this.isGmailConnected = false,
    this.isOutlookConnected = false,
  });

  EmailIntegrationState copyWith({
    bool? isGmailConnected,
    bool? isOutlookConnected,
  }) {
    return EmailIntegrationState(
      isGmailConnected: isGmailConnected ?? this.isGmailConnected,
      isOutlookConnected: isOutlookConnected ?? this.isOutlookConnected,
    );
  }
}

final emailIntegrationProvider =
    StateNotifierProvider<EmailIntegrationNotifier, EmailIntegrationState>(
        (ref) {
  return EmailIntegrationNotifier();
});
