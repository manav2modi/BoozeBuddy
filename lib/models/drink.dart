// lib/models/drink.dart
import 'package:flutter/cupertino.dart';

enum DrinkType {
  beer,
  wine,
  cocktail,
  shot,
  other
}

class Drink {
  final String id;
  final DrinkType type;
  final double standardDrinks; // Alcohol content in standard drinks
  final DateTime timestamp;
  final String? note;
  final double? cost; // Optional cost field

  Drink({
    required this.id,
    required this.type,
    required this.standardDrinks,
    required this.timestamp,
    this.note,
    this.cost, // Optional cost
  });

  // Helper method to get emoji for drink type
  static String getEmojiForType(DrinkType type) {
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
    }
  }

  // Helper method to get color for drink type - optimized for dark mode
  static Color getColorForType(DrinkType type) {
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
      'cost': cost, // Include cost in JSON
    };
  }

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'] as String,
      type: DrinkType.values[json['type'] as int],
      standardDrinks: (json['standardDrinks'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null, // Parse cost if available
    );
  }
}