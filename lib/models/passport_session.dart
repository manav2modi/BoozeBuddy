// lib/models/passport_session.dart (enhanced)
import 'package:flutter/material.dart';
import 'drink.dart';

class PassportSession {
  final String id;
  final String sessionName; // Add a custom name field
  final DateTime startTime;
  final DateTime endTime;
  final List<String> locationNames; // Changed to list for multiple locations
  final List<Drink> drinks;
  final String? photoPath;
  final List<PassportStamp> stamps; // Changed to PassportStamp objects

  // Calculated fields
  double get totalStandardDrinks => drinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  double get totalCost => drinks.fold(0, (sum, drink) => sum + (drink.cost ?? 0));
  int get uniqueLocations => drinks.map((d) => d.location).where((l) => l != null).toSet().length;
  int get uniqueDrinkTypes => drinks.map((d) => d.type).toSet().length;

  // Duration of drinking
  Duration get sessionDuration => drinks.isEmpty
      ? Duration.zero
      : drinks.map((d) => d.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)
      .difference(drinks.map((d) => d.timestamp).reduce((a, b) => a.isBefore(b) ? a : b));

  // Favorite drink (most consumed type)
  DrinkType get favoriteDrinkType {
    if (drinks.isEmpty) return DrinkType.other;

    Map<DrinkType, int> typeCounts = {};
    for (var drink in drinks) {
      typeCounts[drink.type] = (typeCounts[drink.type] ?? 0) + 1;
    }

    return typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  PassportSession({
    required this.id,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.locationNames,
    required this.drinks,
    this.photoPath,
    required this.stamps,
  });
}

// Add a class for passport stamps (achievements)
class PassportStamp {
  final String id;
  final String name;
  final String description;
  final String emoji;

  const PassportStamp({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
  });

  // Predefined stamps
  static const PassportStamp explorer = PassportStamp(
    id: 'explorer',
    name: 'Explorer',
    description: 'Visited multiple locations',
    emoji: '🧭',
  );

  static const PassportStamp mixologist = PassportStamp(
    id: 'mixologist',
    name: 'Mixologist',
    description: 'Tried multiple types of drinks',
    emoji: '🍹',
  );

  static const PassportStamp photographer = PassportStamp(
    id: 'photographer',
    name: 'Photographer',
    description: 'Added a photo to your passport',
    emoji: '📸',
  );

  static const PassportStamp socialButterfly = PassportStamp(
    id: 'social_butterfly',
    name: 'Social Butterfly',
    description: 'Had 5+ drinks in one session',
    emoji: '🦋',
  );

  static const PassportStamp moderateDrinker = PassportStamp(
    id: 'moderate_drinker',
    name: 'Moderate Drinker',
    description: 'Kept your drinking under 3 standard drinks',
    emoji: '👍',
  );
}