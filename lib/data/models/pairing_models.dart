import 'dart:convert';

/// Partner pairing data model
class PartnerPairing {
  final int? id;
  final String? partnerDeviceId;
  final String pairingCode;
  final DateTime? pairedAt;
  final bool isPaired;
  final DateTime? lastConnectedAt;
  final String? encryptionKeyHash;
  final DateTime createdAt;

  PartnerPairing({
    this.id,
    this.partnerDeviceId,
    required this.pairingCode,
    this.pairedAt,
    this.isPaired = false,
    this.lastConnectedAt,
    this.encryptionKeyHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_device_id': partnerDeviceId,
      'pairing_code': pairingCode,
      'paired_at': pairedAt?.toIso8601String(),
      'is_paired': isPaired ? 1 : 0,
      'last_connected_at': lastConnectedAt?.toIso8601String(),
      'encryption_key_hash': encryptionKeyHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PartnerPairing.fromMap(Map<String, dynamic> map) {
    return PartnerPairing(
      id: map['id'] as int?,
      partnerDeviceId: map['partner_device_id'] as String?,
      pairingCode: map['pairing_code'] as String,
      pairedAt: map['paired_at'] != null 
          ? DateTime.parse(map['paired_at'] as String)
          : null,
      isPaired: (map['is_paired'] as int) == 1,
      lastConnectedAt: map['last_connected_at'] != null
          ? DateTime.parse(map['last_connected_at'] as String)
          : null,
      encryptionKeyHash: map['encryption_key_hash'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PartnerPairing copyWith({
    int? id,
    String? partnerDeviceId,
    String? pairingCode,
    DateTime? pairedAt,
    bool? isPaired,
    DateTime? lastConnectedAt,
    String? encryptionKeyHash,
    DateTime? createdAt,
  }) {
    return PartnerPairing(
      id: id ?? this.id,
      partnerDeviceId: partnerDeviceId ?? this.partnerDeviceId,
      pairingCode: pairingCode ?? this.pairingCode,
      pairedAt: pairedAt ?? this.pairedAt,
      isPaired: isPaired ?? this.isPaired,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      encryptionKeyHash: encryptionKeyHash ?? this.encryptionKeyHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Sync queue item
class SyncQueueItem {
  final String id;
  final String dataType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    required this.id,
    required this.dataType,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_type': dataType,
      'payload_json': jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      dataType: map['data_type'] as String,
      payload: jsonDecode(map['payload_json'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }
}

/// Sync log entry
class SyncLog {
  final int? id;
  final String syncType; // 'manual' or 'auto'
  final DateTime startedAt;
  final DateTime? completedAt;
  final int itemsSent;
  final int itemsReceived;
  final String? status; // 'success', 'failed', 'partial'
  final String? errorMessage;

  SyncLog({
    this.id,
    required this.syncType,
    required this.startedAt,
    this.completedAt,
    this.itemsSent = 0,
    this.itemsReceived = 0,
    this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sync_type': syncType,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'items_sent': itemsSent,
      'items_received': itemsReceived,
      'status': status,
      'error_message': errorMessage,
    };
  }

  factory SyncLog.fromMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id'] as int?,
      syncType: map['sync_type'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      itemsSent: map['items_sent'] as int? ?? 0,
      itemsReceived: map['items_received'] as int? ?? 0,
      status: map['status'] as String?,
      errorMessage: map['error_message'] as String?,
    );
  }
}
