import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Bluetooth packet structure for BLE data transfer
class BluetoothPacket {
  final String messageId;
  final String dataType;
  final int chunkIndex;
  final int totalChunks;
  final Map<String, dynamic> payload;
  final String checksum;

  BluetoothPacket({
    required this.messageId,
    required this.dataType,
    required this.chunkIndex,
    required this.totalChunks,
    required this.payload,
    required this.checksum,
  });

  /// Create packet from JSON
  factory BluetoothPacket.fromJson(Map<String, dynamic> json) {
    return BluetoothPacket(
      messageId: json['messageId'] as String,
      dataType: json['dataType'] as String,
      chunkIndex: json['chunkIndex'] as int,
      totalChunks: json['totalChunks'] as int,
      payload: json['payload'] as Map<String, dynamic>,
      checksum: json['checksum'] as String,
    );
  }

  /// Convert packet to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'dataType': dataType,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
      'payload': payload,
      'checksum': checksum,
    };
  }

  /// Serialize packet to bytes (for BLE transmission)
  List<int> toBytes() {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }

  /// Deserialize packet from bytes
  static BluetoothPacket fromBytes(List<int> bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BluetoothPacket.fromJson(json);
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
}

/// Protocol helper for creating and managing packets
class BluetoothProtocol {
  static const int maxChunkSize = 480; // Leave headroom in 512-byte MTU
  static final _uuid = const Uuid();

  /// Create a data packet (ping, message, etc.)
  static List<BluetoothPacket> createDataPackets({
    required String dataType,
    required Map<String, dynamic> payload,
  }) {
    final messageId = _uuid.v4();
    final payloadString = jsonEncode(payload);
    final payloadBytes = utf8.encode(payloadString);

    // Calculate number of chunks needed
    final totalChunks = (payloadBytes.length / maxChunkSize).ceil();

    final packets = <BluetoothPacket>[];
    for (int i = 0; i < totalChunks; i++) {
      final start = i * maxChunkSize;
      final end = (start + maxChunkSize < payloadBytes.length)
          ? start + maxChunkSize
          : payloadBytes.length;

      final chunkBytes = payloadBytes.sublist(start, end);
      final chunkString = utf8.decode(chunkBytes);

      // For multi-chunk, payload is partial JSON string
      // For single chunk, payload is the full data
      final chunkPayload = totalChunks == 1
          ? payload
          : {'chunk': chunkString};

      final checksum = BluetoothPacket.calculateChecksum(
        totalChunks == 1 ? payloadString : chunkString,
      );

      packets.add(BluetoothPacket(
        messageId: messageId,
        dataType: dataType,
        chunkIndex: i,
        totalChunks: totalChunks,
        payload: chunkPayload,
        checksum: checksum,
      ));
    }

    return packets;
  }

  /// Create an acknowledgment packet
  static BluetoothPacket createAckPacket(String originalMessageId) {
    final payload = {'ackFor': originalMessageId};
    final payloadString = jsonEncode(payload);
    final checksum = BluetoothPacket.calculateChecksum(payloadString);

    return BluetoothPacket(
      messageId: _uuid.v4(),
      dataType: 'ack',
      chunkIndex: 0,
      totalChunks: 1,
      payload: payload,
      checksum: checksum,
    );
  }

  /// Reassemble chunked packets into original data
  static Map<String, dynamic>? reassembleChunks(List<BluetoothPacket> packets) {
    if (packets.isEmpty) return null;

    // Sort by chunk index
    packets.sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));

    // Verify all packets have same messageId and totalChunks
    final messageId = packets.first.messageId;
    final totalChunks = packets.first.totalChunks;

    for (final packet in packets) {
      if (packet.messageId != messageId || packet.totalChunks != totalChunks) {
        return null; // Mismatched packets
      }
      if (!packet.validateChecksum()) {
        return null; // Corrupted chunk
      }
    }

    // Verify we have all chunks
    if (packets.length != totalChunks) {
      return null; // Missing chunks
    }

    // If single chunk, return payload directly
    if (totalChunks == 1) {
      return packets.first.payload;
    }

    // Reassemble multi-chunk payload
    final chunks = <String>[];
    for (final packet in packets) {
      chunks.add(packet.payload['chunk'] as String);
    }

    final reassembledString = chunks.join();
    try {
      return jsonDecode(reassembledString) as Map<String, dynamic>;
    } catch (e) {
      return null; // Failed to decode
    }
  }

  /// Validate packet data type
  static bool isValidDataType(String dataType) {
    return ['ping', 'message', 'read_status', 'ack'].contains(dataType);
  }
}

/// Model for chunked message reassembly tracking
class ChunkBuffer {
  final String messageId;
  final int totalChunks;
  final Map<int, BluetoothPacket> receivedChunks = {};
  final DateTime createdAt = DateTime.now();

  ChunkBuffer({
    required this.messageId,
    required this.totalChunks,
  });

  void addChunk(BluetoothPacket packet) {
    if (packet.messageId == messageId && !receivedChunks.containsKey(packet.chunkIndex)) {
      receivedChunks[packet.chunkIndex] = packet;
    }
  }

  bool isComplete() => receivedChunks.length == totalChunks;

  List<BluetoothPacket> getSortedChunks() {
    final sorted = receivedChunks.values.toList();
    sorted.sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return sorted;
  }

  bool isExpired({Duration timeout = const Duration(minutes: 5)}) {
    return DateTime.now().difference(createdAt) > timeout;
  }
}
