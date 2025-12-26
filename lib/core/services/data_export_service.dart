import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_service.dart';
import '../security/pin_manager.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Data export/import service - backup and restore database
class DataExportService {
  final DatabaseService _db = DatabaseService.instance;
  final PINManager _pinManager = PINManager();

  /// Export database to encrypted file
  /// Returns path to exported file or null if failed
  Future<String?> exportDatabase(String pin) async {
    try {
      // 1. Verify PIN first
      final isValid = await _pinManager.verifyPIN(pin);
      if (!isValid) {
        throw Exception('Invalid PIN');
      }

      // 2. Close database temporarily
      await _db.close();

      // 3. Get database path
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'saathi.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        await _db.database; // Reopen
        throw Exception('Database file not found');
      }

      // 4. Read database file
      final dbBytes = await dbFile.readAsBytes();

      // 5. Double encryption - add PIN-based layer
      final encryptedBytes = _encryptWithPIN(dbBytes, pin);

      // 6. Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'saathi_backup_$timestamp.saathi';

      // 7. Get downloads directory
      final downloadsDir = await getExternalStorageDirectory();
      final exportPath = join(downloadsDir!.path, fileName);

      // 8. Write encrypted file
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(encryptedBytes);

      // 9. Reopen database
      await _db.database;

      return exportPath;
    } catch (e) {
      // Ensure database is reopened even on error
      await _db.database;
      rethrow;
    }
  }

  /// Import database from encrypted file
  Future<void> importDatabase(String filePath, String pin) async {
    try {
      // 1. Verify PIN first
      final isValid = await _pinManager.verifyPIN(pin);
      if (!isValid) {
        throw Exception('Invalid PIN');
      }

      // 2. Read encrypted file
      final importFile = File(filePath);
      if (!await importFile.exists()) {
        throw Exception('Import file not found');
      }

      final encryptedBytes = await importFile.readAsBytes();

      // 3. Decrypt with PIN
      final decryptedBytes = _decryptWithPIN(encryptedBytes, pin);

      // 4. Close current database
      await _db.close();

      // 5. Backup current database (in case import fails)
      final documentsDir = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDir.path, 'saathi.db');
      final dbFile = File(dbPath);
      final backupPath = join(documentsDir.path, 'saathi_backup_temp.db');
      
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
      }

      // 6. Replace database file with imported data
      await dbFile.writeAsBytes(decryptedBytes);

      // 7. Try to open the new database
      try {
        await _db.database;
        
        // 8. Delete temporary backup if successful
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      } catch (e) {
        // 9. Restore from backup if import failed
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.copy(dbPath);
          await backupFile.delete();
        }
        
        await _db.database; // Reopen original
        throw Exception('Import failed - database restored from backup');
      }
    } catch (e) {
      // Ensure database is reopened even on error
      await _db.database;
      rethrow;
    }
  }

  /// Share exported file using system share dialog
  Future<void> shareExportedFile(String filePath) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: 'Saathi App Backup');
  }

  /// Pick file for import
  Future<String?> pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['saathi', 'db'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }

    return null;
  }

  // ========== Private Methods ==========

  /// Encrypt data with PIN (simple XOR + HMAC for additional layer)
  List<int> _encryptWithPIN(List<int> data, String pin) {
    // Create key from PIN using SHA-256
    final keyBytes = sha256.convert(utf8.encode(pin)).bytes;
    
    // XOR encryption (simple but effective as second layer)
    final encrypted = <int>[];
    for (int i = 0; i < data.length; i++) {
      encrypted.add(data[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    // Add HMAC for integrity check
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(encrypted);
    
    // Prepend HMAC to encrypted data
    return [...digest.bytes, ...encrypted];
  }

  /// Decrypt data with PIN
  List<int> _decryptWithPIN(List<int> encryptedData, String pin) {
    // Create key from PIN
    final keyBytes = sha256.convert(utf8.encode(pin)).bytes;
    
    // Extract HMAC (first 32 bytes)
    final receivedHmac = encryptedData.sublist(0, 32);
    final encrypted = encryptedData.sublist(32);
    
    // Verify HMAC
    final hmac = Hmac(sha256, keyBytes);
    final computedHmac = hmac.convert(encrypted).bytes;
    
    if (!_listEquals(receivedHmac, computedHmac)) {
      throw Exception('Data integrity check failed - file may be corrupted or wrong PIN');
    }
    
    // XOR decryption
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return decrypted;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
