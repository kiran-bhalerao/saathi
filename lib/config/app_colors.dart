import 'package:flutter/material.dart';

/// Centralized color palette for Saathi app
/// All colors defined in ONE place for consistency
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary Colors - Warm coral/salmon (safe, feminine)
  static const Color primary = Color(0xFFE57373);
  static const Color primaryLight = Color(0xFFFFC4C4);
  static const Color primaryDark = Color(0xFFD84848);
  static const Color accent = Color(0xFF9B3846); // Burgundy
  static const Color primaryGradientEnd = Color(0xFFEF5350);

  // Male Colors - Blue palette
  static const Color primaryMale = Color(0xFF2196F3);
  static const Color primaryMaleLight = Color(0xFF64B5F6);
  static const Color primaryMaleMedium = Color(0xFF42A5F5);

  // Backgrounds
  static const Color background = Color(0xFFFFF5F5); // Soft cream
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFBEBEB); // Soft pink

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Highlighting Colors (5 options for text selection)
  static const Color highlightCoral = Color(0xFFFF7B7B);
  static const Color highlightPurple = Color(0xFF9B7BFF);
  static const Color highlightYellow = Color(0xFFFFD97B);
  static const Color highlightGreen = Color(0xFF7BFFA5);
  static const Color highlightBlue = Color(0xFF7BC8FF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Utility Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Colors.black12;
  static const Color overlay = Colors.black26;

  // Gradient
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F5), Colors.white],
  );

  static const LinearGradient maleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMaleLight, primaryMaleMedium, primaryMale],
  );

  static const LinearGradient femaleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryGradientEnd, Color(0xFFEC407A)],
  );
}
