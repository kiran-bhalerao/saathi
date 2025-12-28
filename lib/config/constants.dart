/// App-wide constants for Saathi
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();
  
  // ========== App Info ==========
  static const String appName = 'Saathi';
  static const String appNameDisguised = 'Wellness Guide'; // For decoy screen
  
  // ========== Database ==========
  static const String databaseName = 'saathi.db';
  
  // ========== Security ==========
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const int pbkdf2Iterations = 10000;
  static const int saltLength = 16;
  static const int aesKeyLength = 32; // 256 bits
  
  // ========== Messages ==========
  static const int messageRetentionDays = 100;  // Auto-delete messages after this period
  
  // ========== Content ==========
  static const int totalChapters = 12;
  static const int averageWordsPerMinute = 200; // For reading time estimation
  
  // ========== Timeouts ==========
  static const Duration splashDuration = Duration(seconds: 2);
  
  // ========== Asset Paths ==========
  static const String chaptersPathEn = 'assets/content/chapters/en/chapters/';
  static const String chaptersPathHi = 'assets/content/chapters/hi/chapters/';
}
