/// App-wide constants for Saathi
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();
  
  // ========== App Info ==========
  static const String appName = 'Saathi';
  static const String appNameDisguised = 'Wellness Guide'; // For decoy screen
  static const String appVersion = '1.0.0';
  
  // ========== Database ==========
  static const String databaseName = 'saathi.db';
  static const int databaseVersion = 1;
  
  // ========== Security ==========
  static const int minPinLength = 4;
  static const int maxPinLength = 6;
  static const int pbkdf2Iterations = 10000;
  static const int saltLength = 16;
  static const int aesKeyLength = 32; // 256 bits
  
  // ========== Bluetooth (Phase 2) ==========
  static const String bluetoothServiceUUID = 'your-saathi-service-uuid-here';
  static const String bluetoothCharacteristicUUID = 'your-characteristic-uuid-here';
  static const int pairingCodeLength = 6;
  static const Duration pairingCodeExpiry = Duration(minutes: 5);
  static const Duration syncTimeout = Duration(seconds: 30);
  
  // ========== Content ==========
  static const int totalChapters = 12;
  static const String defaultLocale = 'en';
  static const int averageWordsPerMinute = 200; // For reading time estimation
  
  // ========== Ping System ==========
  static const int maxActivePings = 3; // Maximum sections that can be shared at once
  
  // ========== Messages ==========
  static const Duration messageAutoDeleteAfter = Duration(days: 7);
  static const int maxMessageLength = 500;
  
  // ========== UI ==========
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double maxContentWidth = 600.0; // For tablets
  
  // ========== Animations ==========
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // ========== Timeouts ==========
  static const Duration appLockTimeout = Duration(minutes: 5); // Lock app after 5 mins in background
  static const Duration splashDuration = Duration(seconds: 2);
  
  // ========== Feature Flags ==========
  static const bool enableBluetoothSync = false; // Phase 2 - set to false initially
  static const bool enableGamification = true;
  static const bool enableExportImport = true;
  
  // ========== Asset Paths ==========
  static const String chaptersPathEn = 'assets/content/chapters/en/chapters/';
  static const String chaptersPathHi = 'assets/content/chapters/hi/chapters/';
  static const String imagesPath = 'assets/images/';
}
