import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_models.dart';
import '../../core/database/database_service.dart';

/// Ping repository - handles section sharing with partner
class PingRepository {
  final DatabaseService _databaseService = DatabaseService.instance;
  final Uuid _uuid = const Uuid();

  /// Create a new ping (share section with partner)
  Future<void> pingSection({
    required int chapterNumber,
    required String sectionId,
    required String sectionTitle,
    required String sectionContentJson,
  }) async {
    final db = await _databaseService.database;
    
    final ping = PingedSection(
      id: _uuid.v4(),
      chapterNumber: chapterNumber,
      sectionId: sectionId,
      sectionTitle: sectionTitle,
      sectionContentJson: sectionContentJson,
      pingedAt: DateTime.now(),
      synced: false, // Will be synced in Phase 2
    );
    
    await db.insert(
      'pinged_sections',
      ping.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all pinged sections
  Future<List<PingedSection>> getAllPings() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pinged_sections',
      orderBy: 'pinged_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PingedSection.fromMap(maps[i]);
    });
  }

  /// Get pinged sections for a specific chapter
  Future<List<PingedSection>> getPingsByChapter(int chapterNumber) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pinged_sections',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
      orderBy: 'pinged_at DESC',
    );

    return List.generate(maps.length, (i) {
      return PingedSection.fromMap(maps[i]);
    });
  }

  /// Check if a section is already pinged
  Future<bool> isSectionPinged(String sectionId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'pinged_sections',
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );

    return result.isNotEmpty;
  }

  /// Remove a ping
  Future<void> unpingSection(String pingId) async {
    final db = await _databaseService.database;
    await db.delete(
      'pinged_sections',
      where: 'id = ?',
      whereArgs: [pingId],
    );
  }

  /// Mark ping as read by partner
  Future<void> markAsRead(String pingId) async {
    final db = await _databaseService.database;
    await db.update(
      'pinged_sections',
      {
        'read_by_partner': 1,
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [pingId],
    );
  }

  /// Get unread ping count
  Future<int> getUnreadCount() async {
    final db = await _databaseService.database;
    final result = await db.query(
      'pinged_sections',
      columns: ['COUNT(*) as count'],
      where: 'read_by_partner = ?',
      whereArgs: [0],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all pings (for data deletion feature)
  Future<void> deleteAllPings() async {
    final db = await _databaseService.database;
    await db.delete('pinged_sections');
  }
}
