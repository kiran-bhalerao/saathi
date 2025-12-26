import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  Future<void> performSync() async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to partner device');
    }

    try {
      // Discover services
      final services = await _connectedDevice!.discoverServices();
      
      final saathiService = services.firstWhere(
        (s) => s.uuid.toString().toUpperCase() == serviceUuid.toUpperCase(),
      );

      final dataChar = saathiService.characteristics.firstWhere(
        (c) => c.uuid.toString().toUpperCase() == dataCharUuid.toUpperCase(),
      );

      // TODO: Implement actual sync logic in Phase 5
      // 1. Get pending items from sync_queue
      // 2. Serialize and chunk data (BLE has 20-512 byte limit per write)
      // 3. Write chunks to characteristic
      // 4. Read partner's data chunks
      // 5. Process and merge received data
      // 6. Mark items as synced in database

      // Placeholder: simulate sync delay
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      throw Exception('Sync failed: ${e.toString()}');
    }
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
