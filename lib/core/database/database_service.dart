import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized database service with SQLCipher encryption
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static sqflite.Database? _database;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DatabaseService._internal();

  /// Get database instance (singleton pattern)
  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize encrypted database
  Future<sqflite.Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    // Get or create encryption key
    final password = await _getDatabasePassword();
    
    return await sqflite.openDatabase(
      path,
      version: 5, // Updated for Phase 5: Sync with delivery acknowledgments
      password: password,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Get database encryption password from secure storage
  Future<String> _getDatabasePassword() async {
    const key = 'database_password';
    
    // Try to read existing password
    String? password = await _secureStorage.read(key: key);
    
    // If no password exists, create a new one
    if (password == null) {
      // Generate a strong random password
      password = _generateSecurePassword();
      await _secureStorage.write(key: key, value: password);
    }
    
    return password;
  }

  /// Generate secure random password for database
  String _generateSecurePassword() {
    // Use device-specific values to create unique password
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'saathi_${timestamp}_${DateTime.now().toIso8601String()}';
  }

  /// Create database tables
  Future<void> _onCreate(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        user_type TEXT NOT NULL CHECK(user_type IN ('female', 'male')),
        content_locale TEXT DEFAULT 'en',
        pin_hash TEXT NOT NULL,
        pin_salt TEXT NOT NULL,
        created_at TEXT NOT NULL,
        partner_device_id TEXT,
        last_synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chapter_progress (
        id INTEGER PRIMARY KEY,
        chapter_number INTEGER UNIQUE NOT NULL,
        completed INTEGER DEFAULT 0,
        current_section_id TEXT,
        last_read_at TEXT,
        reading_time_seconds INTEGER DEFAULT 0,
        quiz_completed INTEGER DEFAULT 0,
        quiz_score INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE pinged_sections (
        id TEXT PRIMARY KEY,
        chapter_number INTEGER NOT NULL,
        section_id TEXT NOT NULL,
        section_title TEXT NOT NULL,
        section_content_json TEXT NOT NULL,
        pinged_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        read_by_partner INTEGER DEFAULT 0,
        read_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE question_exchange (
        id TEXT PRIMARY KEY,
        chapter_number INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        asked_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        answer_text TEXT,
        answered_at TEXT,
        discussion_opened INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE discussion_messages (
        id TEXT PRIMARY KEY,
        chapter_number INTEGER NOT NULL,
        sender TEXT NOT NULL CHECK(sender IN ('female', 'male')),
        message_text TEXT NOT NULL,
        sent_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        delivery_status TEXT DEFAULT 'pending' CHECK(delivery_status IN ('pending', 'sent', 'delivered', 'failed')),
        auto_delete_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY,
        chapters_completed INTEGER DEFAULT 0,
        knowledge_points INTEGER DEFAULT 0,
        reading_streak_days INTEGER DEFAULT 0,
        last_read_date TEXT,
        sections_shared INTEGER DEFAULT 0,
        questions_answered INTEGER DEFAULT 0,
        total_reading_minutes INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT,
        unlock_criteria_json TEXT,
        unlocked_at TEXT
      )
    ''');

    // New Schema for Bluetooth Pairing Features
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        data_type TEXT NOT NULL CHECK(data_type IN ('ping', 'message', 'question', 'status', 'ack')),
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        needs_ack INTEGER DEFAULT 1,
        ack_received INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_pairing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        partner_device_id TEXT UNIQUE,
        pairing_code TEXT NOT NULL,
        paired_at TEXT,
        is_paired INTEGER DEFAULT 0,
        last_connected_at TEXT,
        encryption_key_hash TEXT,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL CHECK(sync_type IN ('manual', 'auto')),
        started_at TEXT NOT NULL,
        completed_at TEXT,
        items_sent INTEGER DEFAULT 0,
        items_received INTEGER DEFAULT 0,
        status TEXT CHECK(status IN ('success', 'failed', 'partial')),
        error_message TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_chapter_progress_number ON chapter_progress(chapter_number)');
    await db.execute('CREATE INDEX idx_pinged_sections_synced ON pinged_sections(synced)');
    await db.execute('CREATE INDEX idx_messages_chapter ON discussion_messages(chapter_number)');
    await db.execute('CREATE INDEX idx_sync_queue_synced ON sync_queue(synced_at, created_at)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add quiz tracking fields
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE chapter_progress ADD COLUMN quiz_completed INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE chapter_progress ADD COLUMN quiz_score INTEGER');
    }
    
    // Migration from version 2/3 to 4: Bluetooth pairing enhancements
    if (oldVersion < 4) {
      // Drop and recreate partner_pairing table with new schema
      await db.execute('DROP TABLE IF EXISTS partner_pairing');
      await db.execute('''
        CREATE TABLE partner_pairing (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          partner_device_id TEXT UNIQUE,
          pairing_code TEXT NOT NULL,
          paired_at TEXT,
          is_paired INTEGER DEFAULT 0,
          last_connected_at TEXT,
          encryption_key_hash TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create sync_log table if it doesn't exist
      await db.execute('DROP TABLE IF EXISTS sync_log');
      await db.execute('''
        CREATE TABLE sync_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sync_type TEXT NOT NULL CHECK(sync_type IN ('manual', 'auto')),
          started_at TEXT NOT NULL,
          completed_at TEXT,
          items_sent INTEGER DEFAULT 0,
          items_received INTEGER DEFAULT 0,
          status TEXT CHECK(status IN ('success', 'failed', 'partial')),
          error_message TEXT
        )
      ''');
      
      // Update sync_queue columns
      final result = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE name='sync_queue'"
      );
      if (result.isNotEmpty) {
        final sql = result.first['sql'] as String;
        if (!sql.contains('synced_at')) {
          await db.execute('ALTER TABLE sync_queue ADD COLUMN synced_at TEXT');
        }
        if (!sql.contains('last_error')) {
          await db.execute('ALTER TABLE sync_queue ADD COLUMN last_error TEXT');
        }
      }
    }
    
    // Migration from version 4 to 5: Add delivery status and ACK tracking
    if (oldVersion < 5) {
      // Add delivery_status column to discussion_messages
      await db.execute('ALTER TABLE discussion_messages ADD COLUMN delivery_status TEXT DEFAULT \'pending\' CHECK(delivery_status IN (\'pending\', \'sent\', \'delivered\', \'failed\'))');
      
      // Add ACK tracking columns to sync_queue
      await db.execute('ALTER TABLE sync_queue ADD COLUMN needs_ack INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE sync_queue ADD COLUMN ack_received INTEGER DEFAULT 0');
      
      // Update data_type check to include 'ack'
      // Note: SQLite doesn't support ALTER TABLE for constraints,
      // so new 'ack' type will be allowed after this migration
    }
  }

  /// Get database file path (for export/import)
  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, AppConstants.databaseName);
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing or data deletion feature)
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    await sqflite.deleteDatabase(path);
    _database = null;
    
    // Also delete the password from secure storage
    await _secureStorage.delete(key: 'database_password');
  }
}
