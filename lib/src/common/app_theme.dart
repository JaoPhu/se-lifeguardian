import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Palette
  static const Color primaryColor = Color(0xFF0D9488);
  static const Color scaffoldLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF3F4F6); // Light gray surface
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // Dark Palette
  static const Color scaffoldDark = Color(0xFF111827); // Slate 900
  static const Color cardDark = Color(0xFF1F2937); // Slate 800
  static const Color surfaceDark = Color(0xFF374151); // Slate 700
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF9CA3AF); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: scaffoldLight,
        onSurface: textPrimaryLight,
        secondaryContainer: surfaceLight,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      scaffoldBackgroundColor: scaffoldLight,
      cardColor: cardLight,
      dividerColor: Colors.grey.shade200,
      iconTheme: const IconThemeData(color: textPrimaryLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondaryLight),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: cardDark,
        onSurface: textPrimaryDark,
        secondaryContainer: surfaceDark, // Used for inputs/cards
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),
      scaffoldBackgroundColor: scaffoldDark,
      cardColor: cardDark,
      dividerColor: Colors.white.withOpacity(0.05),
      iconTheme: const IconThemeData(color: textPrimaryDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondaryDark),
      ),
    );
  }
}
