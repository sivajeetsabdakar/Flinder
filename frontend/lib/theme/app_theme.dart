import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryPurple = Color(0xFF7E22CE); // Deep purple
  static const Color darkerPurple = Color(0xFF581C87); // Darker purple
  static const Color lightPurple = Color(0xFFD8B4FE); // Light purple

  // Neutral colors
  static const Color darkBackground = Color(0xFF121212); // Almost black
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);
  static const Color lightGrey = Color(0xFFBBBBBB);

  // Accent colors
  static const Color accentPink = Color(0xFFEC4899);

  // Gradients
  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, darkerPurple],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackground, Color(0xFF1A1A1A)],
  );

  // Text styles
  static TextStyle get headingStyle => GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.12,
    color: Colors.white,
  );

  static TextStyle get subheadingStyle => GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.2,
    color: Colors.white,
  );

  static TextStyle get bodyStyle => GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.45,
    color: Colors.white,
  );

  static TextStyle get buttonTextStyle => GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
    color: Colors.white,
  );

  // Input decoration
  static InputDecoration inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: lightGrey.withOpacity(0.7), fontSize: 14),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: lightGrey) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: darkGrey,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: mediumGrey.withOpacity(0.3), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryPurple, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }

  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: primaryPurple, width: 2),
    ),
    elevation: 0,
  );

  // Theme data
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: darkBackground,
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentPink,
      background: darkBackground,
      surface: darkGrey,
    ),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 30,
        height: 1.12,
        color: Colors.white,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.2,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.45,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 15,
        height: 1.45,
        color: Colors.white,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        height: 1.2,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkGrey,
      hintStyle: TextStyle(color: lightGrey.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: mediumGrey.withOpacity(0.3), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryPurple, width: 2.0),
      ),
    ),
  );
}
