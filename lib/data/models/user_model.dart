/// User model representing app user (female or male)
class UserModel {
  final int? id;
  final String userType; // 'female' or 'male'
  final String contentLocale;
  final String pinHash;
  final String pinSalt;
  final DateTime createdAt;
  final String? partnerDeviceId;
  final DateTime? lastSyncedAt;

  UserModel({
    this.id,
    required this.userType,
    this.contentLocale = 'en',
    required this.pinHash,
    required this.pinSalt,
    required this.createdAt,
    this.partnerDeviceId,
    this.lastSyncedAt,
  });

  /// Check if user is female
  bool get isFemale => userType == 'female';

  /// Check if user is male
  bool get isMale => userType == 'male';

  /// Check if paired with partner
  bool get isPaired => partnerDeviceId != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_type': userType,
      'content_locale': contentLocale,
      'pin_hash': pinHash,
      'pin_salt': pinSalt,
      'created_at': createdAt.toIso8601String(),
      'partner_device_id': partnerDeviceId,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      userType: map['user_type'] as String,
      contentLocale: map['content_locale'] as String? ?? 'en',
      pinHash: map['pin_hash'] as String,
      pinSalt: map['pin_salt'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      partnerDeviceId: map['partner_device_id'] as String?,
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
    );
  }

  UserModel copyWith({
    int? id,
    String? userType,
    String? contentLocale,
    String? pinHash,
    String? pinSalt,
    DateTime? createdAt,
    String? partnerDeviceId,
    DateTime? lastSyncedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userType: userType ?? this.userType,
      contentLocale: contentLocale ?? this.contentLocale,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      createdAt: createdAt ?? this.createdAt,
      partnerDeviceId: partnerDeviceId ?? this.partnerDeviceId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
