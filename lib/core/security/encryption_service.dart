import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Encryption service for Bluetooth data transfer (Phase 2)
class EncryptionService {
  /// Encrypt data using AES-256-GCM
  Future<EncryptedPacket> encryptData(
    Map<String, dynamic> data,
    String sharedKey,
  ) async {
    // Convert to JSON
    final plaintext = jsonEncode(data);

    // Generate random IV (12 bytes for GCM)
    final iv = _generateIV();

    // Encrypt using AES-256-GCM
    final cipher = GCMBlockCipher(AESEngine());
    final keyBytes = utf8.encode(sharedKey.substring(0, 32));

    cipher.init(
      true, // encrypt mode
      AEADParameters(
        KeyParameter(keyBytes),
        128, // MAC size in bits
        iv,
        Uint8List(0), // additional authenticated data
      ),
    );

    final plaintextBytes = utf8.encode(plaintext);
    final ciphertext = cipher.process(plaintextBytes);

    // Generate HMAC for authentication
    final hmac = _generateHMAC(ciphertext, sharedKey);

    return EncryptedPacket(
      ciphertext: base64.encode(ciphertext),
      iv: base64.encode(iv),
      hmac: hmac,
    );
  }

  /// Decrypt Bluetooth packet
  Future<Map<String, dynamic>> decryptData(
    EncryptedPacket packet,
    String sharedKey,
  ) async {
    // Verify HMAC (detect tampering)
    final ciphertextBytes = base64.decode(packet.ciphertext);
    final isValid = _verifyHMAC(ciphertextBytes, packet.hmac, sharedKey);

    if (!isValid) {
      throw SecurityException('Data integrity check failed - possible tampering');
    }

    // Decrypt
    final cipher = GCMBlockCipher(AESEngine());
    final keyBytes = utf8.encode(sharedKey.substring(0, 32));
    final iv = base64.decode(packet.iv);

    cipher.init(
      false, // decrypt mode
      AEADParameters(
        KeyParameter(keyBytes),
        128,
        iv,
        Uint8List(0),
      ),
    );

    final plaintext = cipher.process(ciphertextBytes);

    // Parse JSON
    return jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
  }

  // ========== Private Methods ==========

  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(12, (_) => random.nextInt(256)),
    );
  }

  String _generateHMAC(Uint8List data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(data);
    return base64.encode(digest.bytes);
  }

  bool _verifyHMAC(Uint8List data, String receivedHmac, String key) {
    final computed = _generateHMAC(data, key);
    return computed == receivedHmac;
  }
}

/// Encrypted packet for Bluetooth transfer
class EncryptedPacket {
  final String ciphertext;
  final String iv;
  final String hmac;

  EncryptedPacket({
    required this.ciphertext,
    required this.iv,
    required this.hmac,
  });

  Map<String, dynamic> toJson() {
    return {
      'ciphertext': ciphertext,
      'iv': iv,
      'hmac': hmac,
    };
  }

  factory EncryptedPacket.fromJson(Map<String, dynamic> json) {
    return EncryptedPacket(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
      hmac: json['hmac'] as String,
    );
  }
}

/// Security exception
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
