import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D9488),
        brightness: Brightness.dark,
        surface: const Color(0xFF1F2937),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      cardColor: const Color(0xFF1F2937),
    );
  }
}
