import '../models/chapter_model.dart';
import '../models/sync_models.dart';
import '../../core/database/database_service.dart';
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
    
    // Auto-delete after 7 days (optional feature)
    final autoDeleteAt = DateTime.now().add(const Duration(days: 7));
    
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
}
