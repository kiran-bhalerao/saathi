import '../models/chapter_model.dart';
import '../models/sync_models.dart';
import '../../core/database/database_service.dart';
import '../../config/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing chapter discussion messages
class DiscussionRepository {
  final DatabaseService _databaseService = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Send a message to a chapter discussion
  Future<void> sendMessage({
    required int chapterNumber,
    required String sender,
    required String messageText,
  }) async {
    final db = await _databaseService.database;
    
    // Auto-delete after configured retention period
    final autoDeleteAt = DateTime.now().add(Duration(days: AppConstants.messageRetentionDays));
    
    final message = DiscussionMessage(
      id: _uuid.v4(),
      chapterNumber: chapterNumber,
      sender: sender,
      messageText: messageText,
      sentAt: DateTime.now(),
      synced: false,
      autoDeleteAt: autoDeleteAt,
    );

    await db.insert(
      'discussion_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all messages for a specific chapter
  Future<List<DiscussionMessage>> getMessagesForChapter(int chapterNumber) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'discussion_messages',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
      orderBy: 'sent_at ASC',
    );

    return maps.map((map) => DiscussionMessage.fromMap(map)).toList();
  }

  /// Delete old messages (auto-delete after 7 days)
  Future<void> deleteOldMessages() async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    
    await db.delete(
      'discussion_messages',
      where: 'auto_delete_at IS NOT NULL AND auto_delete_at < ?',
      whereArgs: [now],
    );
  }

  /// Delete all messages for a specific chapter
  Future<void> deleteChapterMessages(int chapterNumber) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'discussion_messages',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
    );
  }

  /// Get message count for a chapter
  Future<int> getMessageCount(int chapterNumber) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM discussion_messages WHERE chapter_number = ?',
      [chapterNumber],
    );
    
    return result.first['count'] as int;
  }

  /// Delete all messages (for complete data wipe)
  Future<void> deleteAllMessages() async {
    final db = await _databaseService.database;
    await db.delete('discussion_messages');
  }

  /// Get chapter discussion thread (messages + pinged sections merged chronologically)
  Future<List<Map<String, dynamic>>> getChapterThread(int chapterNumber) async {
    final db = await _databaseService.database;
    
    // Get messages
    final messages = await getMessagesForChapter(chapterNumber);
    
    // Get pinged sections for this chapter
    final pingsResult = await db.query(
      'pinged_sections',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
      orderBy: 'pinged_at ASC',
    );
    
    // Combine and sort chronologically
    final thread = <Map<String, dynamic>>[];
    
    // Add messages
    for (final message in messages) {
      thread.add({
        'type': 'message',
        'data': message,
        'timestamp': message.sentAt,
      });
    }
    
    // Add pinged sections
    for (final ping in pingsResult) {
      thread.add({
        'type': 'ping',
        'data': ping,
        'timestamp': DateTime.parse(ping['pinged_at'] as String),
      });
    }
    
    // Sort by timestamp
    thread.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
    
    return thread;
  }

  /// Get chapters that have discussions or pings (for male home screen)
  Future<List<Map<String, dynamic>>> getChaptersWithActivity() async {
    final db = await _databaseService.database;
    
    final results = await db.rawQuery('''
      SELECT DISTINCT chapter_number 
      FROM (
        SELECT chapter_number FROM discussion_messages
        UNION
        SELECT chapter_number FROM pinged_sections
      )
      ORDER BY chapter_number
    ''');
    
    return results;
  }
}
