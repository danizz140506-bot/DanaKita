import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Lightweight wrapper around [LocalAuthentication] for biometric / PIN auth.
class BiometricService {
  BiometricService._();
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Returns `true` if the device has any biometric or device-credential
  /// authentication available (fingerprint, face, PIN, pattern, etc.).
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user to authenticate with biometrics or device credentials.
  ///
  /// Returns `true` if authentication succeeded, `false` otherwise.
  static Future<bool> authenticate({String reason = 'Verify your identity to continue'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN/pattern as fallback
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
