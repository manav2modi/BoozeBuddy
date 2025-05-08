// lib/models/custom_drink.dart
import 'package:flutter/material.dart';

class CustomDrink {
  final String id;
  final String name;
  final String emoji;
  final double defaultStandardDrinks;
  final Color color;

  CustomDrink({
    required this.id,
    required this.name,
    required this.emoji,
    required this.defaultStandardDrinks,
    required this.color,
  });

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'defaultStandardDrinks': defaultStandardDrinks,
      'color': color.value, // Store color as int
    };
  }

  factory CustomDrink.fromJson(Map<String, dynamic> json) {
    return CustomDrink(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      defaultStandardDrinks: (json['defaultStandardDrinks'] as num).toDouble(),
      color: Color(json['color'] as int),
    );
  }
}