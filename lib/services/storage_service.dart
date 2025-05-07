// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drink.dart';

class StorageService {
  static const String _drinksKey = 'drinks';

  // Save a drink to storage
  Future<void> saveDrink(Drink drink) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing drinks
    List<Drink> drinks = await getDrinks();

    // Add new drink
    drinks.add(drink);

    // Convert to JSON
    List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

    // Save to storage
    await prefs.setStringList(_drinksKey, drinksJson);
  }

  // Get all drinks from storage
  Future<List<Drink>> getDrinks() async {
    final prefs = await SharedPreferences.getInstance();

    // Get saved drinks JSON strings
    List<String>? drinksJson = prefs.getStringList(_drinksKey);

    if (drinksJson == null) {
      return [];
    }

    // Convert JSON to Drink objects
    return drinksJson
        .map((drinkJson) => Drink.fromJson(jsonDecode(drinkJson)))
        .toList();
  }

  // Get drinks for a specific date
  Future<List<Drink>> getDrinksForDate(DateTime date) async {
    List<Drink> allDrinks = await getDrinks();

    return allDrinks.where((drink) {
      return drink.timestamp.year == date.year &&
          drink.timestamp.month == date.month &&
          drink.timestamp.day == date.day;
    }).toList();
  }

  // Get drinks for a date range
  Future<List<Drink>> getDrinksForDateRange(DateTime start, DateTime end) async {
    List<Drink> allDrinks = await getDrinks();

    return allDrinks.where((drink) {
      return drink.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          drink.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Delete a drink
  Future<void> deleteDrink(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing drinks
    List<Drink> drinks = await getDrinks();

    // Remove the drink with matching ID
    drinks.removeWhere((drink) => drink.id == id);

    // Convert to JSON
    List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

    // Save to storage
    await prefs.setStringList(_drinksKey, drinksJson);
  }

  // Clear all drinks
  Future<void> clearAllDrinks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_drinksKey);
  }
}