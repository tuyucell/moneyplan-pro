import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Biometric Service
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();

      debugPrint(
          'BIOMETRIC_CHECK: Supported: $isDeviceSupported, CanCheck: $canCheckBiometrics, AvailableTypes: $availableBiometrics');

      return isDeviceSupported &&
          canCheckBiometrics &&
          availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('BIOMETRIC_CHECK_ERROR: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Authenticate user via biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool stickyAuth = true,
    bool biometricOnly = true,
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric Authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected Biometric error: $e');
      return false;
    }
  }
}

// Provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
