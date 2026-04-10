import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color creamBackground = Color(0xFFF4F4F6);
  static const Color deepDark = Color(0xFF1A1A1A);
  static const Color accentNeon = Color(0xFFFF2D55); // Moody Red Neon
  static const Color secondaryGrey = Color(0xFF8E8E93);
  static const Color white = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      colorScheme: const ColorScheme.light(
        primary: deepDark,
        secondary: accentNeon,
        surface: creamBackground,
        onSurface: deepDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: deepDark,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: deepDark,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: deepDark,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: secondaryGrey,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: deepDark),
        centerTitle: true,
      ),
    );
  }
}
