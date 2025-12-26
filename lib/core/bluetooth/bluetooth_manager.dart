import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:archive/archive.dart';
import 'bluetooth_protocol.dart';
import 'sync_processor.dart';
import '../../data/repositories/pairing_repository.dart';
import '../../data/repositories/ping_repository.dart';
import '../../data/repositories/discussion_repository.dart';
import '../../data/models/sync_result.dart';
import '../../data/models/pairing_models.dart';

/// Core Bluetooth service for device pairing and data synchronization
/// Uses BLE for device discovery and connection
class BluetoothManager {
  // BLE Service and Characteristic UUIDs for Saathi
  static const String serviceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';
  static const String pairingCharUuid = '0000FFF1-0000-1000-8000-00805F9B34FB';
  static const String dataCharUuid = '0000FFF2-0000-1000-8000-00805F9B34FB';

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  // Dependencies for sync
  final PairingRepository _pairingRepo;
  final PingRepository _pingRepo;
  final DiscussionRepository _discussionRepo;
  late final SyncProcessor _syncProcessor;
  
  // Chunk buffers for reassembly
  final Map<String, ChunkBuffer> _chunkBuffers = {};
  
  BluetoothManager({
    required PairingRepository pairingRepo,
    required PingRepository pingRepo,
    required DiscussionRepository discussionRepo,
  })  : _pairingRepo = pairingRepo,
        _pingRepo = pingRepo,
        _discussionRepo = discussionRepo {
    _syncProcessor = SyncProcessor(
      pingRepo: _pingRepo,
      discussionRepo: _discussionRepo,
      pairingRepo: _pairingRepo,
    );
  }
  
  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      // Check if Bluetooth adapter is available
      if (await FlutterBluePlus.isSupported == false) {
        return false;
      }
      
      // Check if Bluetooth is turned on
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      return false;
    }
  }

  /// Request to turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      // iOS doesn't support programmatic BT enable
      throw Exception('Please enable Bluetooth in Settings');
    }
  }

  /// Female: Start advertising with pairing code embedded in device name
  /// Note: BLE peripheral mode has limitations, especially on iOS
  Future<void> advertiseWithCode(String pairingCode) async {
    try {
      // For BLE discovery, we'll use a naming convention
      // Device name format: Saathi_F_<code>
      final deviceName = 'Saathi_F_$pairingCode';
      
      // Start advertising by setting the device name
      // and ensuring it's discoverable during scanning
      await FlutterBluePlus.setLogLevel(LogLevel.info);
      
      // Note: Actual advertising requires platform-specific implementation
      // For now, we rely on the device being in scanning mode
      // which makes it discoverable by the male device
    } catch (e) {
      throw Exception('Failed to start advertising: ${e.toString()}');
    }
  }

  /// Male: Scan for female device with matching pairing code
  Future<BluetoothDevice?> scanForDevice(String pairingCode, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final targetName = 'Saathi_F_$pairingCode';
    final completer = Completer<BluetoothDevice?>();

    try {
      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final deviceName = result.device.platformName;
          if (deviceName == targetName || deviceName.contains(pairingCode)) {
            // Found matching device
            FlutterBluePlus.stopScan();
            if (!completer.isCompleted) {
              completer.complete(result.device);
            }
            return;
          }
        }
      });

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Set timeout
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          FlutterBluePlus.stopScan();
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      await FlutterBluePlus.stopScan();
      throw Exception('Scan failed: ${e.toString()}');
    } finally {
      await _scanSubscription?.cancel();
    }
  }

  /// Connect to device and verify pairing code
  Future<bool> connectAndPair(BluetoothDevice device, String pairingCode) async {
    try {
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services
      final services = await device.discoverServices();
      
      // Find Saathi service
      final saathiService = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase(),
        orElse: () => throw Exception('Saathi service not found. Make sure partner app is running.'),
      );

      // Find pairing characteristic
      final pairingChar = saathiService.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase() == pairingCharUuid.toUpperCase(),
        orElse: () => throw Exception('Pairing characteristic not found'),
      );

      // Write pairing code for verification
      await pairingChar.write(pairingCode.codeUnits, withoutResponse: false);
      
      // Read verification response
      final response = await pairingChar.read();
      final verified = String.fromCharCodes(response) == 'OK';

      if (!verified) {
        await device.disconnect();
        return false;
      }

      return true;
    } catch (e) {
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
      throw Exception('Connection failed: ${e.toString()}');
    }
  }

  /// Perform data synchronization with partner device
  Future<SyncResult> performSync() async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to partner device');
    }

    // Create sync log
    final logId = await _pairingRepo.createSyncLog('manual');
    int sentCount = 0;
    int receivedCount = 0;

    try {
      // Discover services
      final services = await _connectedDevice!.discoverServices();
      
      final saathiService = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase(),
      );

      final dataChar = saathiService.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase() == dataCharUuid.toUpperCase(),
      );

      // 1. Get pending items from local queue
      final pendingItems = await _pairingRepo.getPendingItems(limit: 20);

      // 2. Send local items to partner
      sentCount = await _sendItems(dataChar, pendingItems);

      // 3. Mark items as 'sent' (waiting for ACK)
      await _pairingRepo.markAsSent(pendingItems.map((item) => item.id).toList());

      // 4. Receive items from partner (data + ACKs)
      final (packets, acks) = await _receiveItems(dataChar);
      receivedCount = packets.length;

      // 5. Process received ACKs (mark as delivered)
      for (final ack in acks) {
        await _syncProcessor.processAcknowledgment(ack.payload);
      }

      // 6. Process received data items
      final receivedAckIds = <String>[];
      for (final packet in packets) {
        await _syncProcessor.processPacket(packet);
        receivedAckIds.add(packet.messageId);
      }

      // 7. Send ACKs for received items
      await _sendAcknowledgments(dataChar, receivedAckIds);

      // 8. Complete sync log
      await _pairingRepo.completeSyncLog(
        logId,
        status: 'success',
        itemsSent: sentCount,
        itemsReceived: receivedCount,
      );

      return SyncResult(sent: sentCount, received: receivedCount);
    } catch (e) {
      // Log failure
      await _pairingRepo.completeSyncLog(
        logId,
        status: 'failed',
        itemsSent: sentCount,
        itemsReceived: receivedCount,
        errorMessage: e.toString(),
      );
      throw Exception('Sync failed: ${e.toString()}');
    } finally {
      // Cleanup old chunk buffers
      _cleanupExpiredChunks();
    }
  }

  /// Send items to partner device
  Future<int> _sendItems(
    BluetoothCharacteristic dataChar,
    List<SyncQueueItem> items,
  ) async {
    int count = 0;

    for (final item in items) {
      try {
        // Create packets for this item
        final packets = BluetoothProtocol.createDataPackets(
          dataType: item.dataType,
          payload: item.payload,
        );

        // Send each packet (chunk)
        for (final packet in packets) {
          final bytes = packet.toBytes();
          
          // Write to characteristic (BLE supports up to 512 bytes MTU)
          await dataChar.write(bytes, withoutResponse: false);
          
          // Small delay between chunks to avoid overwhelming receiver
          await Future.delayed(const Duration(milliseconds: 50));
        }

        count++;
      } catch (e) {
        // Log error but continue with other items
        await _pairingRepo.incrementRetryCount(item.id, e.toString());
      }
    }

    return count;
  }

  /// Receive items from partner device
  Future<(List<BluetoothPacket> packets, List<BluetoothPacket> acks)> _receiveItems(
    BluetoothCharacteristic dataChar,
  ) async {
    final packets = <BluetoothPacket>[];
    final acks = <BluetoothPacket>[];

    try {
      // Read available data from characteristic
      // Note: In a real implementation, you'd need to subscribe to notifications
      // For now, we'll do a simple read
      final List<int> data = await dataChar.read();

      if (data.isEmpty) return (<BluetoothPacket>[], <BluetoothPacket>[]);

      // Deserialize packet
      final packet = BluetoothPacket.fromBytes(data);

      // Validate checksum
      if (!packet.validateChecksum()) {
        throw Exception('Checksum validation failed');
      }

      // Check if this is an ACK or data packet
      if (packet.dataType == 'ack') {
        acks.add(packet);
      } else {
        // Handle chunked data
        if (packet.totalChunks > 1) {
          // Multi-chunk message - add to buffer
          final buffer = _chunkBuffers.putIfAbsent(
            packet.messageId,
            () => ChunkBuffer(
              messageId: packet.messageId,
              totalChunks: packet.totalChunks,
            ),
          );

          buffer.addChunk(packet);

          // If complete, reassemble and add to packets
          if (buffer.isComplete()) {
            final reassembledData = BluetoothProtocol.reassembleChunks(
              buffer.getSortedChunks(),
            );

            if (reassembledData != null) {
              // Create a single packet with reassembled data
              final completePacket = BluetoothPacket(
                messageId: packet.messageId,
                dataType: packet.dataType,
                chunkIndex: 0,
                totalChunks: 1,
                payload: reassembledData,
                checksum: packet.checksum,
              );
              packets.add(completePacket);
            }

            // Remove from buffer
            _chunkBuffers.remove(packet.messageId);
          }
        } else {
          // Single chunk message
          packets.add(packet);
        }
      }
    } catch (e) {
      // Log error but don't fail entire sync
      print('Error receiving items: $e');
    }

    return (packets, acks);
  }

  /// Send acknowledgments for received items
  Future<void> _sendAcknowledgments(
    BluetoothCharacteristic dataChar,
    List<String> messageIds,
  ) async {
    for (final messageId in messageIds) {
      try {
        final ackPacket = BluetoothProtocol.createAckPacket(messageId);
        final bytes = ackPacket.toBytes();
        
        await dataChar.write(bytes, withoutResponse: false);
        await Future.delayed(const Duration(milliseconds: 30));
      } catch (e) {
        print('Error sending ACK for $messageId: $e');
      }
    }
  }

  /// Cleanup expired chunk buffers
  void _cleanupExpiredChunks() {
    _chunkBuffers.removeWhere((_, buffer) => buffer.isExpired());
  }

  // ========== Phase 6: Performance Optimization ==========

  /// Compress payload if size exceeds threshold
  List<int> _compressPayload(List<int> data) {
    // Don't compress small payloads (overhead not worth it)
    if (data.length < 100) return data;
    
    try {
      final encoder = GZipEncoder();
      final compressed = encoder.encode(data);
      
      // Only use compressed if it's actually smaller
      if (compressed != null && compressed.length < data.length) {
        return compressed;
      }
    } catch (e) {
      // Compression failed, use original
      print('Compression failed: $e');
    }
    
    return data;
  }

  /// Decompress payload
  List<int> _decompressPayload(List<int> data, {required bool isCompressed}) {
    if (!isCompressed) return data;
    
    try {
      final decoder = GZipDecoder();
      return decoder.decodeBytes(data);
    } catch (e) {
      print('Decompression failed: $e');
      return data;
    }
  }

  /// Estimate size of sync queue item
  int _estimateSize(SyncQueueItem item) {
    final jsonString = jsonEncode(item.payload);
    return jsonString.length;
  }

  /// Create batches of items for optimized sending
  List<List<SyncQueueItem>> _createBatches(
    List<SyncQueueItem> items, {
    int maxBatchSize = 5,
  }) {
    final batches = <List<SyncQueueItem>>[];
    final currentBatch = <SyncQueueItem>[];

    for (final item in items) {
      final itemSize = _estimateSize(item);

      if (itemSize > 200) {
        // Large item - send alone
        if (currentBatch.isNotEmpty) {
          batches.add(List.from(currentBatch));
          currentBatch.clear();
        }
        batches.add([item]);
      } else {
        // Small item - add to batch
        currentBatch.add(item);

        if (currentBatch.length >= maxBatchSize) {
          batches.add(List.from(currentBatch));
          currentBatch.clear();
        }
      }
    }

    if (currentBatch.isNotEmpty) {
      batches.add(currentBatch);
    }

    return batches;
  }

  /// Create batch packet from multiple items
  BluetoothPacket _createBatchPacket(List<SyncQueueItem> items) {
    final batchPayload = {
      'batch': true,
      'items': items.map((item) => {
        'type': item.dataType,
        'data': item.payload,
      }).toList(),
    };

    final packets = BluetoothProtocol.createDataPackets(
      dataType: 'batch',
      payload: batchPayload,
    );

    return packets.first; // Return first packet (batches should fit in one)
  }

  /// Disconnect from partner device
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    } finally {
      _connectedDevice = null;
      await _scanSubscription?.cancel();
      await _connectionSubscription?.cancel();
    }
  }

  /// Check if currently connected
  bool get isConnected => _connectedDevice != null;

  /// Get connected device ID
  String? get connectedDeviceId => _connectedDevice?.remoteId.toString();

  /// Handle disconnection event
  void _handleDisconnection() {
    _connectedDevice = null;
    // Listeners will be notified via BluetoothProvider
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
  }
}
