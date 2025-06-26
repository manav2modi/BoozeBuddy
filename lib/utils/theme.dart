// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // Fun color palette for BoozeBuddy
  static const Color primaryColor = Color(0xFF7E57C2);      // Vibrant purple
  static const Color secondaryColor = Color(0xFFFF9F43);    // Warm amber
  static const Color backgroundColor = Color(0xFF121212);   // Dark background
  static const Color surfaceColor = Color(0xFF1E1E1E);      // Dark surface
  static const Color accentColor = Color(0xFF26C6DA);       // Teal accent

  // Text colors
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFFBBBBBB); // Slightly brighter than before

  // Card colors
  static const Color cardColor = Color(0xFF2C2C2C);
  static const Color dividerColor = Color(0xFF3D3D3D);

  // Button colors
  static const Color buttonColor = primaryColor;

  // BoozeBuddy signature gradient
  static const LinearGradient boozeBuddyGradient = LinearGradient(
    colors: [secondaryColor, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fun category colors (more vibrant than before)
  static const Map<String, Color> drinkCategoryColors = {
    'Beer': Color(0xFFFFD54F),     // Bright amber
    'Wine': Color(0xFFFF5252),     // Vibrant red
    'Cocktail': Color(0xFFEC407A), // Pink
    'Shot': Color(0xFFFF9F43),     // Orange
    'Other': Color(0xFF7E57C2),    // Purple
  };

  // iOS-like dark theme but with the fun colors
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: primaryColor,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
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
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: Color(0xFFFF3B30),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
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
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  // Helper method to get the gradient decoration
  static BoxDecoration get gradientDecoration {
    return BoxDecoration(
      gradient: boozeBuddyGradient,
      borderRadius: BorderRadius.circular(10),
    );
  }

  // Helper method for card decoration with slightly improved shadow
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: dividerColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Get a color for a drink type
  static Color getColorForDrinkType(String type) {
    return drinkCategoryColors[type] ?? primaryColor;
  }
}

extension TextStyleExtensions on TextStyle {
  TextStyle get noUnderline => copyWith(
    decoration: TextDecoration.none,
    decorationColor: null,
    decorationStyle: null,
    decorationThickness: 0,
  );
}