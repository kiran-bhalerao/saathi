import 'dart:convert';
import '../../../data/repositories/ping_repository.dart';
import '../../../data/repositories/discussion_repository.dart';
import '../../../data/repositories/pairing_repository.dart';
import 'bluetooth_protocol.dart';

/// Processes and validates received sync data
class SyncProcessor {
  final PingRepository _pingRepo;
  final DiscussionRepository _discussionRepo;
  final PairingRepository _pairingRepo;

  SyncProcessor({
    required PingRepository pingRepo,
    required DiscussionRepository discussionRepo,
    required PairingRepository pairingRepo,
  })  : _pingRepo = pingRepo,
        _discussionRepo = discussionRepo,
        _pairingRepo = pairingRepo;

  /// Process ping data (female shares section)
  Future<void> processPing(Map<String, dynamic> data) async {
    if (!validatePingData(data)) {
      throw Exception('Invalid ping data structure');
    }

    final chapterNumber = data['chapterNumber'] as int;
    final sectionId = data['sectionId'] as String;
    final sectionTitle = data['sectionTitle'] as String;
    final sectionContentJson = jsonEncode(data['sectionContent']);
    final pingedAt = DateTime.parse(data['pingedAt'] as String);

    // Check for duplicates by querying all pings
    final existingPings = await _pingRepo.getAllPings();
    if (existingPings.any((ping) => ping.sectionId == sectionId)) {
      return; // Already processed
    }
    
    // Use saveReceivedPing instead of pingSection to avoid sync queue loop
    await _pingRepo.saveReceivedPing(
      chapterNumber: chapterNumber,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      sectionContentJson: sectionContentJson,
      pingedAt: pingedAt,
    );
  }

  /// Process discussion message
  Future<void> processMessage(Map<String, dynamic> data) async {
    if (!validateMessageData(data)) {
      throw Exception('Invalid message data structure');
    }

    final messageId = data['messageId'] as String;
    final chapterNumber = data['chapterNumber'] as int;
    final sender = data['sender'] as String;
    final messageText = data['messageText'] as String;
    final sentAt = DateTime.parse(data['sentAt'] as String);

    // Check for duplicates by querying messages for this chapter
    final existing = await _discussionRepo.getMessagesForChapter(chapterNumber);
    if (existing.any((msg) => msg.id == messageId)) {
      return; // Already processed
    }

    // Use saveReceivedMessage instead of sendMessage to avoid sync queue loop
    await _discussionRepo.saveReceivedMessage(
      messageId: messageId,
      chapterNumber: chapterNumber,
      sender: sender,
      messageText: messageText,
      sentAt: sentAt,
    );
  }

  /// Process read status update (male marks ping as read)
  Future<void> processReadStatus(Map<String, dynamic> data) async {
    if (!data.containsKey('pingId') || !data.containsKey('readAt')) {
      throw Exception('Invalid read status data');
    }

    final pingId = data['pingId'] as String;

    await _pingRepo.markAsRead(pingId);
  }

  /// Process acknowledgment (delivery confirmation)
  Future<void> processAcknowledgment(Map<String, dynamic> ack) async {
    if (!ack.containsKey('ackFor')) {
      throw Exception('Invalid ACK data');
    }

    final originalMessageId = ack['ackFor'] as String;

    // Mark item as acknowledged in sync_queue
    await _pairingRepo.markAsAcknowledged(originalMessageId);

    // Update message delivery status
    await _pairingRepo.updateMessageDeliveryStatus(originalMessageId, 'delivered');
  }

  /// Validate ping data structure
  bool validatePingData(Map<String, dynamic> data) {
    return data.containsKey('chapterNumber') &&
        data.containsKey('sectionId') &&
        data.containsKey('sectionTitle') &&
        data.containsKey('sectionContent') &&
        data.containsKey('pingedAt');
  }

  /// Validate message data structure
  bool validateMessageData(Map<String, dynamic> data) {
    return data.containsKey('messageId') &&
        data.containsKey('chapterNumber') &&
        data.containsKey('sender') &&
        data.containsKey('messageText') &&
        data.containsKey('sentAt');
  }

  /// Validate checksum for data integrity
  bool validateChecksum(String data, String checksum) {
    final calculatedChecksum = _calculateChecksum(data);
    return calculatedChecksum == checksum;
  }

  /// Calculate checksum (delegate to protocol)
  String _calculateChecksum(String data) {
    // Use same logic as BluetoothPacket
    return BluetoothPacket.calculateChecksum(data);
  }

  /// Generate acknowledgment for received message
  Map<String, dynamic> generateAck(String messageId) {
    return {
      'ackFor': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Process received data packet based on type
  Future<void> processPacket(BluetoothPacket packet) async {
    if (!packet.validateChecksum()) {
      throw Exception('Checksum validation failed for packet ${packet.messageId}');
    }

    switch (packet.dataType) {
      case 'ping':
        await processPing(packet.payload);
        break;
      case 'message':
        await processMessage(packet.payload);
        break;
      case 'read_status':
        await processReadStatus(packet.payload);
        break;
      case 'ack':
        await processAcknowledgment(packet.payload);
        break;
      default:
        throw Exception('Unknown data type: ${packet.dataType}');
    }
  }
}
