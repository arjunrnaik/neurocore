import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeuroCoreTheme {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111411);
  static const Color darkSurface = Color(0xFF111411);
  static const Color darkSurfaceLow = Color(0xFF1A1C19);
  static const Color darkSurfaceContainer = Color(0xFF1D211D);
  static const Color darkSurfaceHigh = Color(0xFF282B27);
  static const Color darkPrimary = Color(0xFFAFCEB5);
  static const Color darkPrimaryContainer = Color(0xFF314D3A);
  static const Color darkOnPrimaryContainer = Color(0xFFCAEAD0);
  static const Color darkSecondary = Color(0xFFFAB899);
  static const Color darkSecondaryContainer = Color(0xFF693B24);
  static const Color darkTertiary = Color(0xFFCBC1EC);
  static const Color darkTertiaryContainer = Color(0xFF494266);
  static const Color darkOnSurface = Color(0xFFE1E3DE);
  static const Color darkOnSurfaceVariant = Color(0xFFC2C8C1);
  static const Color darkOutline = Color(0xFF8C938C);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFBF9F4);
  static const Color lightSurface = Color(0xFFFBF9F4);
  static const Color lightSurfaceLow = Color(0xFFF0EEE9);
  static const Color lightSurfaceContainer = Color(0xFFEAE7E1);
  static const Color lightSurfaceHigh = Color(0xFFE4E1DA);
  static const Color lightPrimary = Color(0xFF496550);
  static const Color lightPrimaryContainer = Color(0xFF7D9B84);
  static const Color lightOnPrimaryContainer = Color(0xFFFFFFFF);
  static const Color lightSecondary = Color(0xFF845239);
  static const Color lightSecondaryContainer = Color(0xFFF2BB9A);
  static const Color lightTertiary = Color(0xFF61597F);
  static const Color lightTertiaryContainer = Color(0xFFEDC2D2);
  static const Color lightOnSurface = Color(0xFF1B1C19);
  static const Color lightOnSurfaceVariant = Color(0xFF4F524E);
  static const Color lightOutline = Color(0xFF757874);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: darkPrimary,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: Color(0xFF23351E),
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: darkOnPrimaryContainer,
      secondary: darkSecondary,
      onSecondary: Color(0xFF482914),
      secondaryContainer: darkSecondaryContainer,
      tertiary: darkTertiary,
      tertiaryContainer: darkTertiaryContainer,
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      outline: darkOutline,
    ),
    textTheme: _buildTextTheme(Brightness.dark, darkOnSurface),
    cardTheme: CardTheme(
      color: darkSurfaceLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: lightPrimary,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: lightOnPrimaryContainer,
      secondary: lightSecondary,
      onSecondary: Colors.white,
      secondaryContainer: lightSecondaryContainer,
      tertiary: lightTertiary,
      tertiaryContainer: lightTertiaryContainer,
      surface: lightSurface,
      onSurface: lightOnSurface,
      onSurfaceVariant: lightOnSurfaceVariant,
      outline: lightOutline,
    ),
    textTheme: _buildTextTheme(Brightness.light, lightOnSurface),
    cardTheme: CardTheme(
      color: lightSurfaceLow,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );

  static TextTheme _buildTextTheme(Brightness brightness, Color baseColor) {
    return TextTheme(
      headlineLarge: GoogleFonts.literata(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.literata(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
    );
  }
}
