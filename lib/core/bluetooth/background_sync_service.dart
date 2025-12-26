import 'dart:async';
import '../../data/repositories/pairing_repository.dart';
import '../../providers/bluetooth_provider.dart';

/// Background service for monitoring and auto-trigger sync
/// Runs periodic checks for pending items and triggers sync when appropriate
class BackgroundSyncService {
  final PairingRepository _pairingRepo;
  final BluetoothProvider _bluetoothProvider;
  
  Timer? _syncCheckTimer;
  static const Duration syncCheckInterval = Duration(minutes: 5);
  static const Duration lowBatteryInterval = Duration(minutes: 10);
  
  bool _isMonitoring = false;
  bool _isLowBattery = false;

  BackgroundSyncService({
    required PairingRepository pairingRepo,
    required BluetoothProvider bluetoothProvider,
  })  : _pairingRepo = pairingRepo,
        _bluetoothProvider = bluetoothProvider;

  /// Start background monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _scheduleNextCheck();
  }

  /// Stop background monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _syncCheckTimer?.cancel();
    _syncCheckTimer = null;
  }

  /// Schedule next sync check
  void _scheduleNextCheck() {
    _syncCheckTimer?.cancel();
    
    final interval = _isLowBattery ? lowBatteryInterval : syncCheckInterval;
    
    _syncCheckTimer = Timer(interval, () async {
      if (_isMonitoring) {
        await _checkAndSync();
        _scheduleNextCheck(); // Schedule next check
      }
    });
  }

  /// Check for pending items and trigger sync if needed
  Future<void> _checkAndSync() async {
    try {
      // Only sync if connected
      if (!_bluetoothProvider.isConnected) return;
      
      // Check if there are pending items
      final pendingCount = await _pairingRepo.getPendingSyncCount();
      
      if (pendingCount > 0) {
        // Trigger sync
        await _bluetoothProvider.syncNow();
      }
    } catch (e) {
      // Log error but don't stop monitoring
      print('Background sync check failed: $e');
    }
  }

  /// Update battery status (call from app when battery state changes)
  void updateBatteryStatus(bool isLowBattery) {
    if (_isLowBattery != isLowBattery) {
      _isLowBattery = isLowBattery;
      
      if (_isMonitoring) {
        // Reschedule with new interval
        _scheduleNextCheck();
      }
    }
  }

  /// Get current monitoring status
  bool get isMonitoring => _isMonitoring;

  /// Dispose and cleanup
  void dispose() {
    stopMonitoring();
  }
}
