import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Premium iOS-inspired colors
  static const Color accentGreen = Color(0xFF10B981); // Emerald pulse
  static const Color accentBlue = Color(0xFF007AFF); // iOS System Blue
  static const Color accentOrange = Color(0xFFFF9500); // System Orange
  static const Color accentRed = Color(0xFFFF3B30); // System Red
  static const Color accentPurple = Color(0xFFAF52DE);

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentGreen,
      surface: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFFE5E5EA),
      error: accentRed,
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS Grouped Background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F7),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: accentBlue),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E5EA), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5EA),
      thickness: 0.8,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentGreen,
      surface: Color(0xFF1C1C1E), // iOS Dark Card
      surfaceContainerHighest: Color(0xFF2C2C2E),
      error: accentRed,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000), // iOS Dark Background
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: accentBlue),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2C2C2E), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2C2C2E),
      thickness: 0.8,
    ),
  );
}
