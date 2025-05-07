// lib/models/drink.dart
import 'package:flutter/foundation.dart';

enum DrinkType { beer, wine, cocktail, shot }

extension DrinkTypeEmoji on DrinkType {
  String get emoji {
    switch (this) {
      case DrinkType.beer:
        return '🍺';
      case DrinkType.wine:
        return '🍷';
      case DrinkType.cocktail:
        return '🍹';
      case DrinkType.shot:
        return '🥃';
    }
  }
}

class Drink {
  final String id;
  final DrinkType type;
  final DateTime dateTime;
  final double? cost;

  Drink({
    required this.id,
    required this.type,
    required this.dateTime,
    this.cost,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': describeEnum(type),
    'dateTime': dateTime.toIso8601String(),
    'cost': cost,
  };

  factory Drink.fromMap(Map<String, dynamic> map) => Drink(
    id: map['id'],
    type: DrinkType.values.firstWhere((e) => describeEnum(e) == map['type']),
    dateTime: DateTime.parse(map['dateTime']),
    cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
  );
}