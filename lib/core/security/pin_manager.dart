import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/constants.dart';

/// PIN manager with PBKDF2 hashing for secure authentication
class PINManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';

  /// Check if PIN is configured
  Future<bool> isPINConfigured() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Setup new PIN (first-time setup)
  Future<void> setupPIN(String pin) async {
    // Validate PIN length
    if (pin.length < AppConstants.minPinLength || pin.length > AppConstants.maxPinLength) {
      throw Exception('PIN must be ${AppConstants.minPinLength}-${AppConstants.maxPinLength} digits');
    }

    // Validate PIN contains only digits
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw Exception('PIN must contain only digits');
    }

    // Generate random salt
    final salt = _generateSalt();

    // Hash PIN using PBKDF2
    final hash = await _hashPIN(pin, salt);

    // Store securely (never store plain PIN!)
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
  }

  /// Verify PIN for authentication
  Future<bool> verifyPIN(String inputPIN) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || salt == null) {
      throw Exception('PIN not configured. Please setup PIN first.');
    }

    // Hash input PIN with same salt
    final inputHash = await _hashPIN(inputPIN, salt);

    // Compare hashes (constant-time comparison to prevent timing attacks)
    return _constantTimeCompare(inputHash, storedHash);
  }

  /// Change existing PIN
  Future<void> changePIN(String oldPIN, String newPIN) async {
    // Verify old PIN first
    final isValid = await verifyPIN(oldPIN);
    if (!isValid) {
      throw Exception('Current PIN is incorrect');
    }

    // Setup new PIN
    await setupPIN(newPIN);
  }

  /// Reset PIN (requires clearing all app data)
  Future<void> resetPIN() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
  }

  /// Get PIN hash and salt for database storage
  Future<Map<String, String>> getPINCredentials() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _pinSaltKey);

    if (hash == null || salt == null) {
      throw Exception('PIN not configured');
    }

    return {
      'hash': hash,
      'salt': salt,
    };
  }

  // ========== Private Methods ==========

  /// Hash PIN using PBKDF2 with SHA-256
  Future<String> _hashPIN(String pin, String salt) async {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(
        utf8.encode(salt),
        AppConstants.pbkdf2Iterations, // 10,000 iterations
        AppConstants.aesKeyLength, // 32 bytes (256 bits)
      ));

    final key = derivator.process(utf8.encode(pin));
    return base64.encode(key);
  }

  /// Generate cryptographically secure random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(
      AppConstants.saltLength,
      (_) => random.nextInt(256),
    );
    return base64.encode(saltBytes);
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}
