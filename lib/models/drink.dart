// lib/models/drink.dart
import 'package:flutter/material.dart';

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

  Drink({
    required this.id,
    required this.type,
    required this.standardDrinks,
    required this.timestamp,
    this.note,
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

  // Helper method to get color for drink type
  static Color getColorForType(DrinkType type) {
    switch (type) {
      case DrinkType.beer:
        return Colors.amber;
      case DrinkType.wine:
        return Colors.redAccent;
      case DrinkType.cocktail:
        return Colors.pinkAccent;
      case DrinkType.shot:
        return Colors.deepOrangeAccent;
      case DrinkType.other:
        return Colors.purpleAccent;
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
    };
  }

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      type: DrinkType.values[json['type']],
      standardDrinks: json['standardDrinks'],
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
}