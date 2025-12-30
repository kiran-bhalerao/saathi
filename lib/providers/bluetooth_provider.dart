import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../core/connections/connection_manager.dart';
import '../data/models/bluetooth_enums.dart';
import '../data/repositories/pairing_repository.dart';
import '../data/repositories/user_repository.dart';

/// Connection state management provider (formerly BluetoothProvider)
/// Manages device pairing and data sync using Nearby Connections
class BluetoothProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PairingRepository _pairingRepository;
  final UserRepository _userRepository;
  final ConnectionManager _connectionManager;

  PairingStatus _pairingStatus = PairingStatus.notPaired;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _pairingCode;
  String? _errorMessage;
  int _pendingSyncItems = 0;
  bool _isBluetoothAvailable = false;

  // Auto-reconnect state
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int maxReconnectAttempts = 3;
  bool _isReconnecting = false;

  BluetoothProvider({
    required PairingRepository pairingRepository,
    required UserRepository userRepository,
    required ConnectionManager connectionManager,
  })  : _pairingRepository = pairingRepository,
        _userRepository = userRepository,
        _connectionManager = connectionManager {
    // Set up connection callbacks
    _connectionManager.onConnectionSuccess = _handleConnectionSuccess;
    _connectionManager.onDisconnected = _handleDisconnection;

    _initialize();
  }

  // Getters
  PairingStatus get pairingStatus => _pairingStatus;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get pairingCode => _pairingCode;
  String? get errorMessage => _errorMessage;
  int get pendingSyncItems => _pendingSyncItems;
  bool get isPaired => _pairingStatus == PairingStatus.paired;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isBluetoothAvailable => _isBluetoothAvailable;

  Future<void> _initialize() async {
    // Mark as available (Nearby Connections handles availability internally)
    _isBluetoothAvailable = true;

    // Load pairing status and user type from database
    final pairing = await _pairingRepository.getPairing();
    final user = await _userRepository.getUser();

    if (pairing != null && pairing.isPaired) {
      _pairingStatus = PairingStatus.paired;
      _pairingCode = pairing.pairingCode;
    }

    // Load pending sync count
    _pendingSyncItems = await _pairingRepository.getPendingSyncCount();

    // Start connection monitoring if paired
    if (isPaired && _pairingCode != null) {
      _startConnectionMonitoring();

      // Attempt immediate reconnection on app launch
      Future.delayed(const Duration(seconds: 2), () async {
        if (isPaired && !isConnected) {
          print('App launched: Attempting auto-reconnect...');

          // Determine role and reconnect accordingly
          if (user?.userType == 'female') {
            // Female: Restart advertising
            print('Female: Restarting advertising with code: $_pairingCode');
            await ensurePermissionsGranted();
            await _connectionManager.startAdvertising(_pairingCode!);
          } else {
            // Male: Start discovery
            reconnect();
          }
        }
      });
    }

    notifyListeners();
  }

  /// Check and request required permissions for Nearby Connections
  Future<bool> ensurePermissionsGranted() async {
    try {
      // Request location services (required for Nearby Connections)
      Location location = Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _errorMessage = 'Location services required for device discovery';
          notifyListeners();
          return false;
        }
      }

      // Request all required permissions
      Map<ph.Permission, ph.PermissionStatus> statuses = await [
        ph.Permission.location,
        ph.Permission.bluetoothAdvertise,
        ph.Permission.bluetoothConnect,
        ph.Permission.bluetoothScan,
        if (defaultTargetPlatform == TargetPlatform.android)
          ph.Permission.nearbyWifiDevices,
      ].request();

      // Check if all granted
      bool allGranted = statuses.values
          .every((status) => status == ph.PermissionStatus.granted);

      if (!allGranted) {
        _errorMessage =
            'Required permissions denied. Please grant all permissions.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Permission error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Generate new pairing code and start advertising (Female onboarding)
  Future<String> generatePairingCode() async {
    final code = _generateCode();
    _pairingCode = code;

    // Save to database
    await _pairingRepository.createPairing(code);

    // Request permissions and start advertising
    if (await ensurePermissionsGranted()) {
      try {
        await _connectionManager.startAdvertising(code);

        // Set status to pairing (waiting for Male to connect)
        // DO NOT mark as paired here - that happens in _handleConnectionSuccess
        _pairingStatus = PairingStatus.pairing;
        _connectionStatus =
            ConnectionStatus.disconnected; // Advertise but not yet connected
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Failed to start advertising: ${e.toString()}';
        debugPrint('Advertising failed: $e');
        notifyListeners();
      }
    }

    notifyListeners();
    return code;
  }

  // Completer to wait for connection
  Completer<bool>? _connectionCompleter;

  /// Enter pairing code and connect (Male onboarding)
  Future<bool> connectWithCode(String code) async {
    // Ensure all permissions are granted
    if (!await ensurePermissionsGranted()) {
      return false;
    }

    _pairingStatus = PairingStatus.pairing;
    _connectionStatus = ConnectionStatus.scanning;
    _errorMessage = null;
    _pairingCode = code; // Store the code

    // Persist code immediately so we have a DB record
    await _pairingRepository.savePairingCode(code);

    notifyListeners();

    try {
      // Create completer to wait for connection
      _connectionCompleter = Completer<bool>();

      // Start discovery for device with matching pairing code
      await _connectionManager.startDiscovery(code);

      // Wait for connection (with timeout)
      final connected = await _connectionCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _connectionCompleter = null;
          throw Exception('Connection timeout - partner device not found');
        },
      );

      _connectionCompleter = null;
      return connected;
    } catch (e) {
      _errorMessage = e.toString();
      _pairingStatus = PairingStatus.notPaired;
      _connectionStatus = ConnectionStatus.disconnected;
      _connectionCompleter = null;
      notifyListeners();
      return false;
    }
  }

  /// Connection success callback
  void _handleConnectionSuccess(String endpointId) async {
    print('Connection success callback: $endpointId');

    _pairingStatus = PairingStatus.paired;
    _connectionStatus = ConnectionStatus.connected;

    // Save to database
    await _pairingRepository.completePairing(
      _pairingCode!,
      endpointId,
    );

    // Complete the connection completer if waiting (Male side)
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(true);
    }

    // Load pending sync count
    _pendingSyncItems = await _pairingRepository.getPendingSyncCount();

    // Auto-trigger sync if there are pending items
    if (_pendingSyncItems > 0) {
      print('Auto-triggering sync for $_pendingSyncItems pending items');
      // Trigger sync after a short delay to ensure connection is stable
      Future.delayed(const Duration(seconds: 1), () {
        if (isConnected) {
          syncNow();
        }
      });
    }

    notifyListeners();
  }

  /// Disconnection callback
  void _handleDisconnection() {
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Manual sync trigger (from Home screen icon)
  Future<void> syncNow() async {
    if (!isPaired) {
      _errorMessage = 'Not paired with partner';
      notifyListeners();
      return;
    }

    if (!_connectionManager.isConnected) {
      _errorMessage = 'Not connected to partner';
      notifyListeners();
      return;
    }

    _connectionStatus = ConnectionStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      // Perform sync via Nearby Connections
      final result = await _connectionManager.performSync();

      _pendingSyncItems = await _pairingRepository.getPendingSyncCount();
      _connectionStatus = ConnectionStatus.connected;

      // Log success (result available for future use)
      print('Sync completed: sent=${result.sent}, received=${result.received}');

      notifyListeners();
    } catch (e) {
      _connectionStatus = ConnectionStatus.disconnected;
      _errorMessage = 'Sync failed: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Reconnect to paired device (for auto-reconnect)
  Future<void> reconnect() async {
    // Strict validation: Must be paired AND have a valid pairing code
    if (!isPaired) {
      print('Reconnect blocked: Device not paired');
      _errorMessage = 'Device not paired. Please pair first.';
      notifyListeners();
      return;
    }

    if (_pairingCode == null || _pairingCode!.isEmpty) {
      print('Reconnect blocked: No pairing code found');
      _errorMessage = 'No pairing code found. Please pair first.';
      _connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
      return;
    }

    if (!await ensurePermissionsGranted()) {
      return;
    }

    _connectionStatus = ConnectionStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      // Start discovery to reconnect
      await _connectionManager.startDiscovery(_pairingCode!);
      // Connection will be handled by callback

      // The success/failure of connection will be handled by _handleConnectionSuccess/_handleDisconnection
      // For now, we assume discovery started successfully.
      // The connection status will be updated via callbacks.

      // No direct 'success' return from startDiscovery for connection establishment here.
      // The logic for updating connection status is in _handleConnectionSuccess.

      // If we reach here, discovery was initiated.
      // We don't set _connectionStatus to connected immediately, as it's async.
      // The callback will do that.

      // If there was an error starting discovery, it would be caught.

      // We might want to add a timeout for discovery here if needed,
      // but for now, relying on callbacks.
    } catch (e) {
      _connectionStatus = ConnectionStatus.disconnected;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Disconnect from partner device
  Future<void> disconnect() async {
    await _connectionManager.disconnect();
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Unpair device (from Settings)
  Future<void> unpairDevice() async {
    // Cancel any ongoing reconnection attempts
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _reconnectAttempts = 0;

    // Get user type to ensure proper cleanup
    final user = await _userRepository.getUser();

    // Disconnect from active connection
    // This handles both advertising (female) and discovery (male)
    await _connectionManager.disconnect();

    // Additional explicit cleanup based on user role
    // Female users may have been advertising, ensure it's stopped
    // Male users may have been discovering, ensure it's stopped
    if (user?.userType == 'female') {
      print('Unpair: Ensuring advertising is stopped for female user');
      // The disconnect() call above should handle this, but we log it for clarity
    } else {
      print('Unpair: Ensuring discovery is stopped for male user');
      // The disconnect() call above should handle this, but we log it for clarity
    }

    // Clear pairing from database
    await _pairingRepository.unpairDevice();

    // Clear all state
    _pairingStatus = PairingStatus.notPaired;
    _connectionStatus = ConnectionStatus.disconnected;
    _pairingCode = null;
    _pendingSyncItems = 0;
    _errorMessage = null;

    notifyListeners();
  }

  /// Queue data for sync
  Future<void> queueForSync({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    await _pairingRepository.queueForSync(type: type, payload: payload);
    _pendingSyncItems = await _pairingRepository.getPendingSyncCount();
    notifyListeners();
  }

  /// Generate 4-digit random code
  String _generateCode() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // ========== Phase 6: Auto-Reconnect System ==========

  /// Start connection monitoring
  void _startConnectionMonitoring() {
    // Periodic check every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isPaired) {
        timer.cancel();
        return;
      }

      if (!isConnected && !_isReconnecting) {
        _attemptAutoReconnect();
      }
    });
  }

  /// Attempt auto-reconnect with exponential backoff
  Future<void> _attemptAutoReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _errorMessage =
          'Failed to reconnect after $maxReconnectAttempts attempts';
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    // Exponential backoff: 2s, 4s, 8s
    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        await reconnect();
        _reconnectAttempts = 0; // Reset on success
        _isReconnecting = false;
      } catch (e) {
        _isReconnecting = false;
        // Will retry on next periodic check
      }
    });
  }

  /// App lifecycle state handler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isPaired) {
      // App came to foreground - check connection
      _checkAndReconnect();
    } else if (state == AppLifecycleState.paused) {
      // App going to background - cancel pending reconnects
      _reconnectTimer?.cancel();
    }
  }

  /// Check connection and reconnect if needed
  Future<void> _checkAndReconnect() async {
    if (!isConnected && isPaired && !_isReconnecting) {
      _reconnectAttempts = 0; // Reset attempts when app resumes
      await reconnect();
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _connectionManager.dispose();
    super.dispose();
  }
}
