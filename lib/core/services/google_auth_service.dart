import 'package:google_sign_in/google_sign_in.dart';
import 'package:moneyplan_pro/core/config/env_config.dart';

class GoogleAuthService {
  // Use a singleton for the entire app to ensure consistent scope management
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: EnvConfig.googleIosClientId,
    // Start with ONLY the basic email scope
    scopes: ['email'],
  );

  GoogleSignIn get instance => _googleSignIn;

  /// Check if we have specific scopes and request them if not
  Future<bool> requestGmailScopes() async {
    const gmailScope = 'https://www.googleapis.com/auth/gmail.readonly';

    // Check if scopes are already granted
    final hasScope = await _googleSignIn.canAccessScopes([gmailScope]);
    if (hasScope) return true;

    // Request the extra scope
    final result = await _googleSignIn.requestScopes([gmailScope]);
    return result;
  }
}
