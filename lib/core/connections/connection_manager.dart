import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../../data/models/sync_result.dart';
import '../../data/repositories/discussion_repository.dart';
import '../../data/repositories/pairing_repository.dart';
import '../../data/repositories/ping_repository.dart';
import '../bluetooth/bluetooth_protocol.dart';
import '../bluetooth/sync_processor.dart';

/// Core Connection service for device pairing and data synchronization
/// Uses Google's Nearby Connections API for reliable P2P discovery
class ConnectionManager {
  // Nearby Connections instance
  final Nearby _nearby = Nearby();

  // Strategy for connections (1:1 pairing)
  static const Strategy _strategy = Strategy.P2P_POINT_TO_POINT;

  // Service ID for app identification
  static const String _serviceId = 'com.example.saathi';

  // Connection state
  String? _connectedEndpointId;
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  // Dependencies for sync
  final PairingRepository _pairingRepo;
  final PingRepository _pingRepo;
  final DiscussionRepository _discussionRepo;
  late final SyncProcessor _syncProcessor;

  // Callbacks
  Function(String endpointId)? onConnectionSuccess;
  Function()? onDisconnected;
  Function(Map<String, dynamic> data)? onDataReceived;

  ConnectionManager({
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

  /// Female: Start advertising with pairing code
  Future<void> startAdvertising(String pairingCode) async {
    try {
      _isAdvertising = true;

      await _nearby.startAdvertising(
        'Saathi_User', // User display name
        _strategy,
        onConnectionInitiated: (String endpointId, ConnectionInfo info) {
          print('Connection initiated from: ${info.endpointName}');

          // Verify pairing code matches
          if (info.endpointName.contains(pairingCode)) {
            print('Pairing code match! Accepting connection.');
            _nearby.acceptConnection(
              endpointId,
              onPayLoadRecieved: _onPayloadReceived,
              onPayloadTransferUpdate: _onPayloadTransferUpdate,
            );
          } else {
            print('Pairing code mismatch. Rejecting connection.');
            _nearby.rejectConnection(endpointId);
          }
        },
        onConnectionResult: (String endpointId, Status status) {
          if (status == Status.CONNECTED) {
            print('Connected to endpoint: $endpointId');
            _connectedEndpointId = endpointId;
            _isAdvertising = false;
            onConnectionSuccess?.call(endpointId);
          } else {
            print('Connection failed with status: $status');
          }
        },
        onDisconnected: (String endpointId) {
          print('Disconnected from: $endpointId');
          _handleDisconnection();
        },
        serviceId: _serviceId,
      );

      print('Started advertising with code: $pairingCode');
    } catch (e) {
      _isAdvertising = false;
      throw Exception('Failed to start advertising: ${e.toString()}');
    }
  }

  /// Male: Start discovery to find female device
  Future<void> startDiscovery(String pairingCode) async {
    try {
      _isDiscovering = true;

      await _nearby.startDiscovery(
        'Saathi_M_$pairingCode', // Male user name with code
        _strategy,
        onEndpointFound:
            (String endpointId, String endpointName, String serviceId) {
          print('Found endpoint: $endpointName');

          // Check if this is a Saathi advertiser
          if (serviceId == _serviceId && endpointName.contains('Saathi')) {
            print('Found partner device! Requesting connection.');
            _requestConnection(endpointId, pairingCode);
          }
        },
        onEndpointLost: (String? endpointId) {
          print('Lost endpoint: $endpointId');
        },
        serviceId: _serviceId,
      );

      print('Started discovery for code: $pairingCode');
    } catch (e) {
      _isDiscovering = false;
      throw Exception('Failed to start discovery: ${e.toString()}');
    }
  }

  /// Request connection to discovered endpoint
  void _requestConnection(String endpointId, String pairingCode) {
    _nearby.requestConnection(
      'Saathi_M_$pairingCode',
      endpointId,
      onConnectionInitiated: (String id, ConnectionInfo info) {
        print('Connection initiated to: ${info.endpointName}');
        // Auto-accept for now (verification done via pairing code)
        _nearby.acceptConnection(
          id,
          onPayLoadRecieved: _onPayloadReceived,
          onPayloadTransferUpdate: _onPayloadTransferUpdate,
        );
      },
      onConnectionResult: (String id, Status status) {
        if (status == Status.CONNECTED) {
          print('Successfully connected to partner!');
          _connectedEndpointId = id;
          _isDiscovering = false;
          _nearby.stopDiscovery(); // Stop scanning
          onConnectionSuccess?.call(id);
        } else {
          print('Connection failed with status: $status');
        }
      },
      onDisconnected: (String id) {
        print('Disconnected from partner');
        _handleDisconnection();
      },
    );
  }

  /// Payload received callback
  void _onPayloadReceived(String endpointId, Payload payload) async {
    print('Received payload from: $endpointId');

    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final jsonString = utf8.decode(payload.bytes!);
        final Map<String, dynamic> data = jsonDecode(jsonString);

        print('Received data: ${data.keys}');

        // Notify callback
        onDataReceived?.call(data);

        // Process through sync processor
        if (data.containsKey('type') && data.containsKey('payload')) {
          final packet = BluetoothPacket.create(
            dataType: data['type'],
            payload: data['payload'],
            messageId: data['messageId'],
          );

          // Process the packet
          await _syncProcessor.processPacket(packet);

          // Send ACK back to confirm receipt (unless it's already an ACK)
          if (data['type'] != 'ack') {
            try {
              final ackPacket = BluetoothPacket.createAck(data['messageId']);
              final ackData = {
                'type': 'ack',
                'payload': ackPacket.payload,
                'messageId': ackPacket.messageId,
              };
              await sendData(ackData);
              print('Sent ACK for message: ${data['messageId']}');
            } catch (e) {
              print('Failed to send ACK: $e');
            }
          }
        }
      } catch (e) {
        print('Error processing received data: $e');
      }
    }
  }

  /// Payload transfer update callback
  void _onPayloadTransferUpdate(
      String endpointId, PayloadTransferUpdate update) {
    if (update.status == PayloadStatus.SUCCESS) {
      print('Payload sent successfully to: $endpointId');
    } else if (update.status == PayloadStatus.FAILURE) {
      print('Payload transfer failed');
    } else if (update.status == PayloadStatus.IN_PROGRESS) {
      final progress = (update.bytesTransferred / update.totalBytes * 100)
          .toStringAsFixed(1);
      print('Transfer progress: $progress%');
    }
  }

  /// Send data to connected partner
  Future<void> sendData(Map<String, dynamic> data) async {
    if (_connectedEndpointId == null) {
      throw Exception('Not connected to any device');
    }

    try {
      final jsonString = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));

      await _nearby.sendBytesPayload(_connectedEndpointId!, bytes);
      print('Sent ${bytes.length} bytes to partner');
    } catch (e) {
      throw Exception('Failed to send data: ${e.toString()}');
    }
  }

  /// Perform data synchronization with partner device
  Future<SyncResult> performSync() async {
    if (_connectedEndpointId == null) {
      throw Exception('Not connected to partner device');
    }

    final logId = await _pairingRepo.createSyncLog('manual');
    int sentCount = 0;
    int receivedCount = 0;

    try {
      // Get pending items from local queue
      final pendingItems = await _pairingRepo.getPendingItems(limit: 20);

      // Send each item
      for (final item in pendingItems) {
        try {
          final data = {
            'type': item.dataType,
            'payload': item.payload,
            'messageId': item.id,
          };

          await sendData(data);
          await _pairingRepo.markAsSent([item.id]);
          sentCount++;
        } catch (e) {
          print('Error sending item: $e');
          await _pairingRepo.incrementRetryCount(item.id, e.toString());
        }
      }

      // Complete sync log
      await _pairingRepo.completeSyncLog(
        logId,
        status: 'success',
        itemsSent: sentCount,
        itemsReceived: receivedCount,
      );

      return SyncResult(sent: sentCount, received: receivedCount);
    } catch (e) {
      await _pairingRepo.completeSyncLog(
        logId,
        status: 'failed',
        itemsSent: sentCount,
        itemsReceived: receivedCount,
        errorMessage: e.toString(),
      );
      throw Exception('Sync failed: ${e.toString()}');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _connectedEndpointId = null;
    _isAdvertising = false;
    _isDiscovering = false;
    onDisconnected?.call();
  }

  /// Disconnect from partner
  Future<void> disconnect() async {
    try {
      if (_connectedEndpointId != null) {
        await _nearby.disconnectFromEndpoint(_connectedEndpointId!);
      }

      if (_isAdvertising) {
        await _nearby.stopAdvertising();
      }

      if (_isDiscovering) {
        await _nearby.stopDiscovery();
      }
    } catch (e) {
      print('Error during disconnect: $e');
    } finally {
      _handleDisconnection();
    }
  }

  /// Check if currently connected
  bool get isConnected => _connectedEndpointId != null;

  /// Get connected endpoint ID
  String? get connectedEndpointId => _connectedEndpointId;

  /// Cleanup resources
  void dispose() {
    disconnect();
  }
}
