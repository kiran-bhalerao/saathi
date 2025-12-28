import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Data packet structure for Nearby Connections transmission
/// Simplified from BLE version - no chunking needed
class BluetoothPacket {
  final String messageId;
  final String dataType;
  final Map<String, dynamic> payload;
  final String checksum;

  BluetoothPacket({
    required this.messageId,
    required this.dataType,
    required this.payload,
    required this.checksum,
  });

  /// Create packet from JSON
  factory BluetoothPacket.fromJson(Map<String, dynamic> json) {
    return BluetoothPacket(
      messageId: json['messageId'] as String,
      dataType: json['dataType'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      checksum: json['checksum'] as String,
    );
  }

  /// Convert packet to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'dataType': dataType,
      'payload': payload,
      'checksum': checksum,
    };
  }

  /// Validate checksum
  bool validateChecksum() {
    final payloadString = jsonEncode(payload);
    final calculatedChecksum = BluetoothPacket.calculateChecksum(payloadString);
    return calculatedChecksum == checksum;
  }

  /// Calculate MD5 checksum for data integrity
  static String calculateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Create a data packet (ping, message, etc.)
  static BluetoothPacket create({
    required String dataType,
    required Map<String, dynamic> payload,
    String? messageId,
  }) {
    final id = messageId ?? const Uuid().v4();
    final payloadString = jsonEncode(payload);
    final checksum = calculateChecksum(payloadString);

    return BluetoothPacket(
      messageId: id,
      dataType: dataType,
      payload: payload,
      checksum: checksum,
    );
  }

  /// Create an acknowledgment packet
  static BluetoothPacket createAck(String originalMessageId) {
    final payload = {'ackFor': originalMessageId};
    return create(
      dataType: 'ack',
      payload: payload,
    );
  }

  /// Validate packet data type
  static bool isValidDataType(String dataType) {
    return ['ping', 'message', 'read_status', 'ack'].contains(dataType);
  }
}
