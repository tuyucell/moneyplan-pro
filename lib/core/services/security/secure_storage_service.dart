import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keyBiometricEnabled = 'biometric_enabled';

  Future<void> saveCredentials(String email, String password) async {
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
      debugPrint('SECURE_STORAGE: Credentials saved for $email');
    } catch (e) {
      debugPrint('SECURE_STORAGE_ERROR (saveCredentials): $e');
      rethrow;
    }
  }

  Future<Map<String, String?>> getCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      debugPrint('SECURE_STORAGE: Credentials read for $email');
      return {'email': email, 'password': password};
    } catch (e) {
      debugPrint('SECURE_STORAGE_ERROR (getCredentials): $e');
      return {'email': null, 'password': null};
    }
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
    debugPrint('SECURE_STORAGE: Credentials cleared');
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
          key: _keyBiometricEnabled, value: enabled.toString());
      debugPrint('SECURE_STORAGE: Biometric enabled set to $enabled');
    } catch (e) {
      debugPrint('SECURE_STORAGE_ERROR (setBiometricEnabled): $e');
      rethrow;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: _keyBiometricEnabled);
      debugPrint('SECURE_STORAGE: Biometric enabled check: $val');
      return val == 'true';
    } catch (e) {
      debugPrint('SECURE_STORAGE_ERROR (isBiometricEnabled): $e');
      return false;
    }
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
