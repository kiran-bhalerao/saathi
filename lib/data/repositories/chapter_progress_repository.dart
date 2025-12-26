import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/chapter_progress_model.dart';
import '../../core/database/database_service.dart';

/// Chapter progress repository - handles reading progress tracking
class ChapterProgressRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  /// Get progress for a specific chapter
  Future<ChapterProgress?> getChapterProgress(int chapterNumber) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapter_progress',
      where: 'chapter_number = ?',
      whereArgs: [chapterNumber],
    );

    if (maps.isEmpty) {
      return null;
    }

    return ChapterProgress.fromMap(maps.first);
  }

  /// Get all chapter progress
  Future<List<ChapterProgress>> getAllProgress() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapter_progress',
      orderBy: 'chapter_number ASC',
    );

    return List.generate(maps.length, (i) {
      return ChapterProgress.fromMap(maps[i]);
    });
  }

  /// Update or create chapter progress
  Future<void> updateProgress(ChapterProgress progress) async {
    final db = await _databaseService.database;
    await db.insert(
      'chapter_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mark chapter as completed
  Future<void> markChapterCompleted(int chapterNumber) async {
    final db = await _databaseService.database;
    final existing = await getChapterProgress(chapterNumber);

    if (existing != null) {
      await updateProgress(existing.copyWith(
        completed: true,
        lastReadAt: DateTime.now(),
      ));
    } else {
      await updateProgress(ChapterProgress(
        chapterNumber: chapterNumber,
        completed: true,
        lastReadAt: DateTime.now(),
      ));
    }
  }

  /// Get completed chapter count
  Future<int> getCompletedCount() async {
    final db = await _databaseService.database;
    final result = await db.query(
      'chapter_progress',
      columns: ['COUNT(*) as count'],
      where: 'completed = ?',
      whereArgs: [1],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all progress (for data deletion feature)
  Future<void> deleteAllProgress() async {
    final db = await _databaseService.database;
    await db.delete('chapter_progress');
  }
}
