import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color creamBackground = Color(0xFFF4F4F6);
  static const Color deepDark = Color(0xFF1A1A1A);
  static const Color accentNeon = Color(0xFFFF2D55); // Original Moody Red Neon
  static const Color neonCyan = Color(0xFF00F2FF);
  static const Color neonPurple = Color(0xFFBD00FF);
  static const Color neonPink = Color(0xFFFF00E5);
  static const Color secondaryGrey = Color(0xFF8E8E93);
  static const Color white = Colors.white;

  // Pathfinder / Neumorphic Colors
  static const Color pathfinderBase = Color(0xFFE0E5EC);
  static const Color pathfinderShadow = Color(0xFFA3B1C6);
  static const Color pathfinderHighlight = Color(0xFFFFFFFF);
  static const Color pathfinderDark = Color(0xFF1D1D21);
  static const Color surfaceDark = Color(0xFF1D1D21);
  static const Color surfaceLight = Color(0xFFF4F4F6); // Creamy light surface

  static BoxDecoration glowDecoration({
    required Color color,
    double blurRadius = 20,
    double spreadRadius = 2,
    double opacity = 0.3,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }

  static BoxDecoration neumorphicDecoration({
    double borderRadius = 20,
    bool isPressed = false,
    Color baseColor = pathfinderBase,
  }) {
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: const Offset(4, 4),
                blurRadius: 10,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: pathfinderShadow.withOpacity(0.5),
                offset: const Offset(-4, -4),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ]
          : [
              BoxShadow(
                color: pathfinderShadow,
                offset: const Offset(8, 8),
                blurRadius: 16,
              ),
              BoxShadow(
                color: pathfinderHighlight,
                offset: const Offset(-8, -8),
                blurRadius: 16,
              ),
            ],
    );
  }

  static BoxDecoration pathfinderDarkDecoration({
    bool isSelected = false,
    bool isCircular = false,
    double borderWidth = 2.2,
    double borderRadius = 16.0,
    Color? rimColor,
    Color backgroundColor = const Color(0xFF1D1D21),
  }) {
    return BoxDecoration(
      color: backgroundColor,
      shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
      border: Border.all(
        color: rimColor ?? const Color(0xFF6F5F4B).withValues(alpha: 0.6), // Premium Golden-Brownish rim
        width: borderWidth,
      ),
      boxShadow: [
        // Whitish Steaming / Top-Left Highlight
        BoxShadow(
          color: Colors.white.withOpacity(0.08),
          offset: const Offset(-4, -4),
          blurRadius: 20,
        ),
        // Deeper Outer Shadow (Bottom-Right)
        BoxShadow(
          color: Colors.black.withOpacity(0.7),
          offset: const Offset(6, 6),
          blurRadius: 18,
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: white,
        secondary: neonCyan,
        surface: surfaceDark,
        onSurface: white,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: white,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: white,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: secondaryGrey.withValues(alpha: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: white),
        centerTitle: true,
      ),
    );
  }
}
