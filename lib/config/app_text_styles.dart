import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized text styles for Saathi app
/// All text styles defined in ONE place for consistency
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();
  
  // Serif font for reading (Literata)
  static String get _serifFont => GoogleFonts.literata().fontFamily!;
  
  // Sans-serif font for UI (Poppins)
  static String get _sansFont => GoogleFonts.poppins().fontFamily!;
  
  // ========== Chapter Screens ==========
  
  /// Chapter title on detail screen (e.g., "Little Women")
  static TextStyle get chapterTitle => TextStyle(
        fontFamily: _sansFont,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: AppColors.textPrimary,
      );
  
  /// Subtitle/Author name
  static TextStyle get subtitle => TextStyle(
        fontFamily: _sansFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
  
  /// Section headings (e.g., "Description")
  static TextStyle get sectionHeading => TextStyle(
        fontFamily: _sansFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
  
  // ========== Reader Screen ==========
  
  /// Chapter number in reader (e.g., "Chapter 2")
  static TextStyle get readerChapterNumber => TextStyle(
        fontFamily: _serifFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );
  
  /// Chapter title in reader
  static TextStyle get readerChapterTitle => TextStyle(
        fontFamily: _serifFont,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
  
  /// Body text for reading - CRITICAL: High line-height for readability
  static TextStyle get bodyText => TextStyle(
        fontFamily: _serifFont,
        fontSize: 16,
        height: 1.8, // Critical for comfortable reading
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      );
  
  // ========== UI Elements ==========
  
  /// Button text
  static TextStyle get button => TextStyle(
        fontFamily: _sansFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );
  
  /// Small button text
  static TextStyle get buttonSmall => TextStyle(
        fontFamily: _sansFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );
  
  /// Card title
  static TextStyle get cardTitle => TextStyle(
        fontFamily: _sansFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
  
  /// Card subtitle
  static TextStyle get cardSubtitle => TextStyle(
        fontFamily: _sansFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );
  
  /// Label text
  static TextStyle get label => TextStyle(
        fontFamily: _sansFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );
  
  /// Caption text
  static TextStyle get caption => TextStyle(
        fontFamily: _sansFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
      );
  
  // ========== Special Cases ==========
  
  /// Monospace text for diagrams/code blocks
  static TextStyle get monoText => const TextStyle(
        fontFamily: 'Courier',
        fontSize: 14,
        height: 1.5,
        color: AppColors.textPrimary,
      );
  
  /// PIN input
  static TextStyle get pinInput => TextStyle(
        fontFamily: _sansFont,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
}
