// lib/models/favorite_drink.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'drink.dart';

class FavoriteDrink {
  final String id;
  final String name;
  final String emoji;
  final DrinkType type;
  final double standardDrinks;
  final Color color;
  final String? customDrinkId; // For custom drinks

  // Optional fields for complete drink entries
  final String? note;
  final double? cost;
  final String? location;

  FavoriteDrink({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.standardDrinks,
    required this.color,
    this.customDrinkId,
    this.note,
    this.cost,
    this.location,
  });

  // Create from a regular Drink
  factory FavoriteDrink.fromDrink(Drink drink, {required String name, required String emoji, required Color color}) {
    return FavoriteDrink(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      type: drink.type,
      standardDrinks: drink.standardDrinks,
      color: color,
      customDrinkId: drink.customDrinkId,
      note: drink.note,
      cost: drink.cost,
      location: drink.location,
    );
  }

  // Convert to a Drink object for adding
  Drink toDrink() {
    return Drink(
      id: const Uuid().v4(),
      type: type,
      standardDrinks: standardDrinks,
      timestamp: DateTime.now(),
      customDrinkId: customDrinkId,
      note: note,
      cost: cost,
      location: location,
    );
  }

  // JSON conversion methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'type': type.index,
      'standardDrinks': standardDrinks,
      'color': color.value,
      'customDrinkId': customDrinkId,
      'note': note,
      'cost': cost,
      'location': location,
    };
  }

  factory FavoriteDrink.fromJson(Map<String, dynamic> json) {
    return FavoriteDrink(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      type: DrinkType.values[json['type'] as int],
      standardDrinks: (json['standardDrinks'] as num).toDouble(),
      color: Color(json['color'] as int),
      customDrinkId: json['customDrinkId'] as String?,
      note: json['note'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      location: json['location'] as String?,
    );
  }
}