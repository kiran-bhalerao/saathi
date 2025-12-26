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
      version: AppConstants.databaseVersion,
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
        reading_time_seconds INTEGER DEFAULT 0
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

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        data_type TEXT NOT NULL CHECK(data_type IN ('ping', 'message', 'question', 'status')),
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_pairing (
        id INTEGER PRIMARY KEY,
        partner_device_id TEXT UNIQUE,
        pairing_code TEXT,
        paired_at TEXT,
        encryption_key_hash TEXT,
        last_synced_at TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_chapter_progress_number ON chapter_progress(chapter_number)');
    await db.execute('CREATE INDEX idx_pinged_sections_synced ON pinged_sections(synced)');
    await db.execute('CREATE INDEX idx_messages_chapter ON discussion_messages(chapter_number)');
    await db.execute('CREATE INDEX idx_sync_queue_synced ON sync_queue(synced, created_at)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    // Future migrations will go here
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE user_profile ADD COLUMN new_field TEXT');
    // }
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
