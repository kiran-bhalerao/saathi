import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/user_model.dart';
import '../../core/database/database_service.dart';

/// User repository - handles user profile database operations
class UserRepository {
  final DatabaseService _databaseService = DatabaseService.instance;

  /// Create new user profile
  Future<void> createUser(UserModel user) async {
    final db = await _databaseService.database;
    await db.insert(
      'user_profile',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user profile (should only be one)
  Future<UserModel?> getUser() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return UserModel.fromMap(maps.first);
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    final db = await _databaseService.database;
    await db.update(
      'user_profile',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Delete user profile
  Future<void> deleteUser() async {
    final db = await _databaseService.database;
    await db.delete('user_profile');
  }

  /// Check if user exists
  Future<bool> userExists() async {
    final user = await getUser();
    return user != null;
  }
}
