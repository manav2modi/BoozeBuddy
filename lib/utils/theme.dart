// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // iOS-style colors
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color secondaryColor = Color(0xFFFF9500);
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Colors.white;
  static const Color accentColor = Color(0xFF5AC8FA);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF000000);
  static const Color textSecondaryColor = Color(0xFF8E8E93);

  // Card colors
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE5E5EA);

  // Button colors
  static const Color buttonColor = primaryColor;

  // Create the iOS-like theme
  static ThemeData get iosTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      brightness: Brightness.light,
      dividerColor: dividerColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Text',
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Display',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Display',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Text',
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Text',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
          fontFamily: '.SF Pro Text',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
          fontFamily: '.SF Pro Text',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: const Color(0xFFFF3B30),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: '.SF Pro Text',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: '.SF Pro Text',
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.2),
        thumbColor: Colors.white,
        overlayColor: primaryColor.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: primaryColor,
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
        ),
      ),
    );
  }
}