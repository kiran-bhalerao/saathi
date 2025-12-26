import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_service.dart';
import '../models/pairing_models.dart';

/// Repository for Bluetooth pairing operations
class PairingRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  /// Create new pairing record with code
  Future<String> createPairing(String code) async {
    final db = await _dbService.database;
    
    final pairing = PartnerPairing(
      pairingCode: code,
      createdAt: DateTime.now(),
    );

    await db.insert('partner_pairing', pairing.toMap());
    return code;
  }

  /// Complete pairing after successful connection
  Future<void> completePairing(String code, String deviceId) async {
    final db = await _dbService.database;
    
    await db.update(
      'partner_pairing',
      {
        'partner_device_id': deviceId,
        'is_paired': 1,
        'paired_at': DateTime.now().toIso8601String(),
        'last_connected_at': DateTime.now().toIso8601String(),
      },
      where: 'pairing_code = ?',
      whereArgs: [code],
    );
  }

  /// Get current pairing
  Future<PartnerPairing?> getPairing() async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'partner_pairing',
      where: 'is_paired = ?',
      whereArgs: [1],
      orderBy: 'paired_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return PartnerPairing.fromMap(results.first);
  }

  /// Check if currently paired
  Future<bool> isPaired() async {
    final pairing = await getPairing();
    return pairing != null && pairing.isPaired;
  }

  /// Update last connected timestamp
  Future<void> updateLastConnected() async {
    final db = await _dbService.database;
    
    await db.update(
      'partner_pairing',
      {'last_connected_at': DateTime.now().toIso8601String()},
      where: 'is_paired = ?',
      whereArgs: [1],
    );
  }

  /// Unpair device
  Future<void> unpairDevice() async {
    final db = await _dbService.database;
    
    await db.update(
      'partner_pairing',
      {
        'is_paired': 0,
        'partner_device_id': null,
        'paired_at': null,
        'last_connected_at': null,
      },
      where: 'is_paired = ?',
      whereArgs: [1],
    );
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    final db = await _dbService.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE synced_at IS NULL',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Add item to sync queue
  Future<void> queueForSync({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _dbService.database;
    
    final item = SyncQueueItem(
      id: const Uuid().v4(),
      dataType: type,
      payload: payload,
      createdAt: DateTime.now(),
    );

    await db.insert('sync_queue', item.toMap());
  }

  /// Get unsent sync items
  Future<List<SyncQueueItem>> getUnsentItems() async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'sync_queue',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
    );

    return results.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  /// Mark items as synced
  Future<void> markSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    
    final db = await _dbService.database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    
    await db.update(
      'sync_queue',
      {'synced_at': DateTime.now().toIso8601String()},
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Mark item as failed
  Future<void> markFailed(String id, String error) async {
    final db = await _dbService.database;
    
    await db.update(
      'sync_queue',
      {
        'retry_count': 'retry_count + 1',
        'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Log sync session
  Future<int> createSyncLog(String syncType) async {
    final db = await _dbService.database;
    
    final log = SyncLog(
      syncType: syncType,
      startedAt: DateTime.now(),
    );

    return await db.insert('sync_log', log.toMap());
  }

  /// Update sync log on completion
  Future<void> completeSyncLog(
    int logId, {
    required String status,
    required int itemsSent,
    required int itemsReceived,
    String? errorMessage,
  }) async {
    final db = await _dbService.database;
    
    await db.update(
      'sync_log',
      {
        'completed_at': DateTime.now().toIso8601String(),
        'status': status,
        'items_sent': itemsSent,
        'items_received': itemsReceived,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [logId],
    );
  }

  /// Get recent sync logs
  Future<List<SyncLog>> getRecentSyncs({int limit = 10}) async {
    final db = await _dbService.database;
    
    final results = await db.query(
      'sync_log',
      orderBy: 'started_at DESC',
      limit: limit,
    );

    return results.map((map) => SyncLog.fromMap(map)).toList();
  }

  /// Delete old sync logs (keep only last 30 days)
  Future<void> cleanupOldSyncLogs() async {
    final db = await _dbService.database;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    
    await db.delete(
      'sync_log',
      where: 'started_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }
}
