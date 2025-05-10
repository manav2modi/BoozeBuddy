// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drink.dart';

class StorageService {
  static const String _drinksKey = 'drinks';

  // Save a drink to storage
  Future<bool> saveDrink(Drink drink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing drinks
      List<Drink> drinks = await getDrinks();

      // Add new drink
      drinks.add(drink);

      // Convert to JSON
      List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

      // Save to storage
      return await prefs.setStringList(_drinksKey, drinksJson);
    } catch (e) {
      print('Error saving drink: $e');
      return false;
    }
  }

  // Get all drinks from storage
  Future<List<Drink>> getDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get saved drinks JSON strings
      List<String>? drinksJson = prefs.getStringList(_drinksKey);

      if (drinksJson == null || drinksJson.isEmpty) {
        return [];
      }

      // Convert JSON to Drink objects
      return drinksJson
          .map((drinkJson) => Drink.fromJson(jsonDecode(drinkJson)))
          .toList();
    } catch (e) {
      print('Error getting drinks: $e');
      return [];
    }
  }

  // Get drinks for a specific date
  Future<List<Drink>> getDrinksForDate(DateTime date) async {
    try {
      List<Drink> allDrinks = await getDrinks();

      return allDrinks.where((drink) {
        return drink.timestamp.year == date.year &&
            drink.timestamp.month == date.month &&
            drink.timestamp.day == date.day;
      }).toList();
    } catch (e) {
      print('Error getting drinks for date: $e');
      return [];
    }
  }

  // Get drinks for a date range
  Future<List<Drink>> getDrinksForDateRange(DateTime start, DateTime end) async {
    try {
      List<Drink> allDrinks = await getDrinks();

      return allDrinks.where((drink) {
        return drink.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
            drink.timestamp.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('Error getting drinks for date range: $e');
      return [];
    }
  }

  // Delete a drink
  Future<bool> deleteDrink(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing drinks
      List<Drink> drinks = await getDrinks();

      // Remove the drink with matching ID
      drinks.removeWhere((drink) => drink.id == id);

      // Convert to JSON
      List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

      // Save to storage
      return await prefs.setStringList(_drinksKey, drinksJson);
    } catch (e) {
      print('Error deleting drink: $e');
      return false;
    }
  }

  // Update an existing drink
  // Add to lib/services/storage_service.dart
  Future<bool> updateDrink(Drink updatedDrink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing drinks
      List<Drink> drinks = await getDrinks();

      // Find the index of the drink to update
      final index = drinks.indexWhere((drink) => drink.id == updatedDrink.id);

      if (index != -1) {
        // Replace the drink at the found index
        drinks[index] = updatedDrink;

        // Convert to JSON
        List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

        // Save to storage
        return await prefs.setStringList(_drinksKey, drinksJson);
      }

      return false; // Drink not found
    } catch (e) {
      print('Error updating drink: $e');
      return false;
    }
  }

  // Clear all drinks
  Future<bool> clearAllDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_drinksKey);
    } catch (e) {
      print('Error clearing drinks: $e');
      return false;
    }
  }
}