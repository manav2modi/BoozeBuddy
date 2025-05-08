// lib/models/drink.dart
import 'package:flutter/cupertino.dart';
import 'custom_drink.dart';

enum DrinkType {
  beer,
  wine,
  cocktail,
  shot,
  other,
  custom // New type for custom drinks
}

class Drink {
  final String id;
  final DrinkType type;
  final double standardDrinks;
  final DateTime timestamp;
  final String? note;
  final double? cost;
  final String? location;
  final String? customDrinkId; // Reference to custom drink if type is custom

  Drink({
    required this.id,
    required this.type,
    required this.standardDrinks,
    required this.timestamp,
    this.note,
    this.cost,
    this.location,
    this.customDrinkId, // Optional custom drink ID
  });

  // Helper method to get emoji for drink type
  static String getEmojiForType(DrinkType type, {String? customEmoji}) {
    // If it's a custom drink with provided emoji, use that
    if (type == DrinkType.custom && customEmoji != null) {
      return customEmoji;
    }

    // Otherwise fall back to default emojis
    switch (type) {
      case DrinkType.beer:
        return '🍺';
      case DrinkType.wine:
        return '🍷';
      case DrinkType.cocktail:
        return '🍹';
      case DrinkType.shot:
        return '🥃';
      case DrinkType.other:
        return '🍸';
      case DrinkType.custom:
        return '🍻'; // Default for custom drinks with no emoji
    }
  }

  // Helper method to get color for drink type - optimized for dark mode
  static Color getColorForType(DrinkType type, {Color? customColor}) {
    // If it's a custom drink with provided color, use that
    if (type == DrinkType.custom && customColor != null) {
      return customColor;
    }

    // Otherwise fall back to default colors
    switch (type) {
      case DrinkType.beer:
        return const Color(0xFFFFC107); // Brighter amber for dark theme
      case DrinkType.wine:
        return const Color(0xFFFF5252); // Brighter red for dark theme
      case DrinkType.cocktail:
        return const Color(0xFFFF4081); // Brighter pink for dark theme
      case DrinkType.shot:
        return const Color(0xFFFF9800); // Brighter orange for dark theme
      case DrinkType.other:
        return const Color(0xFFB388FF); // Brighter purple for dark theme
      case DrinkType.custom:
        return const Color(0xFF64B5F6); // Default blue for custom drinks
    }
  }

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'standardDrinks': standardDrinks,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'cost': cost,
      'location': location,
      'customDrinkId': customDrinkId,
    };
  }

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'] as String,
      type: DrinkType.values[json['type'] as int],
      standardDrinks: (json['standardDrinks'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      location: json['location'] as String?,
      customDrinkId: json['customDrinkId'] as String?,
    );
  }
}