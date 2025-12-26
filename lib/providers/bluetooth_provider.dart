import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../data/models/bluetooth_enums.dart';
import '../data/repositories/pairing_repository.dart';
import '../core/bluetooth/bluetooth_manager.dart';

/// Bluetooth state management provider
/// Phase 6: Auto-reconnect and lifecycle management
class BluetoothProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PairingRepository _pairingRepository;
  final BluetoothManager _bluetoothManager;

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
    required BluetoothManager bluetoothManager,
  })  : _pairingRepository = pairingRepository,
        _bluetoothManager = bluetoothManager {
    _initialize();
    WidgetsBinding.instance.addObserver(this);
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
    // Check Bluetooth availability
    _isBluetoothAvailable = await _bluetoothManager.isBluetoothAvailable();
    
    // Load pairing status from database
    final pairing = await _pairingRepository.getPairing();
    if (pairing != null && pairing.isPaired) {
      _pairingStatus = PairingStatus.paired;
      _pairingCode = pairing.pairingCode;
    }
    
    // Load pending sync count
    _pendingSyncItems = await _pairingRepository.getPendingSyncCount();
    
    // Start connection monitoring if paired
    if (isPaired) {
      _startConnectionMonitoring();
    }
    
    notifyListeners();
  }

  /// Check and request Bluetooth permissions
  Future<bool> ensureBluetoothReady() async {
    _isBluetoothAvailable = await _bluetoothManager.isBluetoothAvailable();
    
    if (!_isBluetoothAvailable) {
      try {
        await _bluetoothManager.turnOnBluetooth();
        _isBluetoothAvailable = true;
      } catch (e) {
        _errorMessage = 'Bluetooth is required. Please enable it in Settings.';
        notifyListeners();
        return false;
      }
    }
    
    notifyListeners();
    return true;
  }

  /// Generate new pairing code and start advertising (Female onboarding)
  Future<String> generatePairingCode() async {
    final code = _generateCode();
    _pairingCode = code;
    
    // Save to database
    await _pairingRepository.createPairing(code);
    
    // Start BLE advertising if Bluetooth is available
    if (await ensureBluetoothReady()) {
      try {
        await _bluetoothManager.advertiseWithCode(code);
      } catch (e) {
        // Advertising may fail on iOS - that's okay, scanning still works
        debugPrint('Advertising failed: $e');
      }
    }
    
    notifyListeners();
    return code;
  }

  /// Enter pairing code and connect (Male onboarding)
  /// Phase 3: Now with real Bluetooth scanning and connection
  Future<bool> connectWithCode(String code) async {
    // Ensure Bluetooth is ready
    if (!await ensureBluetoothReady()) {
      return false;
    }

    _pairingStatus = PairingStatus.pairing;
    _connectionStatus = ConnectionStatus.scanning;
    _errorMessage = null;
    notifyListeners();

    try {
      // Scan for device with matching pairing code
      final device = await _bluetoothManager.scanForDevice(code);
      
      if (device == null) {
        throw Exception('Device not found. Make sure your partner has the pairing screen open.');
      }

      // Update status to connecting
      _connectionStatus = ConnectionStatus.connecting;
      notifyListeners();

      // Connect and verify pairing
      final success = await _bluetoothManager.connectAndPair(device, code);
      
      if (success) {
        _pairingStatus = PairingStatus.paired;
        _connectionStatus = ConnectionStatus.connected;
        _pairingCode = code;
        
        // Save to database with real device ID
        await _pairingRepository.completePairing(
          code,
          _bluetoothManager.connectedDeviceId ?? 'unknown',
        );
        
        notifyListeners();
        return true;
      } else {
        throw Exception('Pairing verification failed. Please check the code and try again.');
      }
    } catch (e) {
      _pairingStatus = PairingStatus.failed;
      _connectionStatus = ConnectionStatus.disconnected;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Manual sync trigger (from Home screen icon)
  Future<void> syncNow() async {
    if (!isPaired) {
      _errorMessage = 'Not paired with partner';
      notifyListeners();
      return;
    }

    if (!await ensureBluetoothReady()) {
      return;
    }

    _connectionStatus = ConnectionStatus.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      // Perform Bluetooth sync
      final result = await _bluetoothManager.performSync();
      
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
    if (!isPaired || _pairingCode == null) {
      return;
    }

    if (!await ensureBluetoothReady()) {
      return;
    }

    _connectionStatus = ConnectionStatus.scanning;
    notifyListeners();

    try {
      final device = await _bluetoothManager.scanForDevice(
        _pairingCode!,
        timeout: const Duration(seconds: 10),
      );
      
      if (device != null) {
        _connectionStatus = ConnectionStatus.connecting;
        notifyListeners();

        final success = await _bluetoothManager.connectAndPair(device, _pairingCode!);
        
        if (success) {
          _connectionStatus = ConnectionStatus.connected;
          await _pairingRepository.updateLastConnected();
        } else {
          _connectionStatus = ConnectionStatus.disconnected;
        }
      } else {
        _connectionStatus = ConnectionStatus.disconnected;
      }
      
      notifyListeners();
    } catch (e) {
      _connectionStatus = ConnectionStatus.disconnected;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Disconnect from partner device
  Future<void> disconnect() async {
    await _bluetoothManager.disconnect();
    _connectionStatus = ConnectionStatus.disconnected;
    notifyListeners();
  }

  /// Unpair device (from Settings)
  Future<void> unpairDevice() async {
    await _bluetoothManager.disconnect();
    await _pairingRepository.unpairDevice();
    
    _pairingStatus = PairingStatus.notPaired;
    _connectionStatus = ConnectionStatus.disconnected;
    _pairingCode = null;
    _pendingSyncItems = 0;
    
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

  /// Handle connection state changes
  Future<void> _handleConnectionStateChange(ConnectionStatus newStatus) async {
    if (newStatus == ConnectionStatus.disconnected && isPaired && !_isReconnecting) {
      // Device disconnected - attempt auto-reconnect
      await _attemptAutoReconnect();
    } else if (newStatus == ConnectionStatus.connected && _pendingSyncItems > 0) {
      // Just reconnected with pending items - auto-trigger sync
      await syncNow();
    }
  }

  /// Attempt auto-reconnect with exponential backoff
  Future<void> _attemptAutoReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _errorMessage = 'Failed to reconnect after $maxReconnectAttempts attempts';
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
    _bluetoothManager.dispose();
    super.dispose();
  }
}
