// lib/services/custom_drinks_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../models/custom_drink.dart';

class CustomDrinksService {
  static const String _customDrinksKey = 'custom_drinks';

  // Get all custom drinks
  Future<List<CustomDrink>> getCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get saved drinks JSON strings
      List<String>? drinksJson = prefs.getStringList(_customDrinksKey);

      if (drinksJson == null || drinksJson.isEmpty) {
        return [];
      }

      // Convert JSON to CustomDrink objects
      return drinksJson
          .map((drinkJson) => CustomDrink.fromJson(jsonDecode(drinkJson)))
          .toList();
    } catch (e) {
      print('Error getting custom drinks: $e');
      return [];
    }
  }

  // Save a custom drink
  Future<bool> saveCustomDrink(String name, String emoji, double standardDrinks, Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate a new ID
      final id = const Uuid().v4();

      // Create the custom drink
      final customDrink = CustomDrink(
        id: id,
        name: name,
        emoji: emoji,
        defaultStandardDrinks: standardDrinks,
        color: color,
      );

      // Get existing custom drinks
      List<CustomDrink> drinks = await getCustomDrinks();

      // Add new drink
      drinks.add(customDrink);

      // Convert to JSON
      List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

      // Save to storage
      return await prefs.setStringList(_customDrinksKey, drinksJson);
    } catch (e) {
      print('Error saving custom drink: $e');
      return false;
    }
  }

  // Update an existing custom drink
  Future<bool> updateCustomDrink(CustomDrink updatedDrink) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing custom drinks
      List<CustomDrink> drinks = await getCustomDrinks();

      // Find the index of the drink to update
      final index = drinks.indexWhere((drink) => drink.id == updatedDrink.id);

      if (index != -1) {
        // Replace the drink at the found index
        drinks[index] = updatedDrink;

        // Convert to JSON
        List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

        // Save to storage
        return await prefs.setStringList(_customDrinksKey, drinksJson);
      }

      return false; // Drink not found
    } catch (e) {
      print('Error updating custom drink: $e');
      return false;
    }
  }

  // Delete a custom drink
  Future<bool> deleteCustomDrink(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing custom drinks
      List<CustomDrink> drinks = await getCustomDrinks();

      // Remove the drink with matching ID
      drinks.removeWhere((drink) => drink.id == id);

      // Convert to JSON
      List<String> drinksJson = drinks.map((drink) => jsonEncode(drink.toJson())).toList();

      // Save to storage
      return await prefs.setStringList(_customDrinksKey, drinksJson);
    } catch (e) {
      print('Error deleting custom drink: $e');
      return false;
    }
  }

  // Get a single custom drink by ID
  Future<CustomDrink?> getCustomDrinkById(String id) async {
    try {
      // Get all custom drinks
      List<CustomDrink> drinks = await getCustomDrinks();

      // Find the drink with matching ID
      for (var drink in drinks) {
        if (drink.id == id) {
          return drink;
        }
      }

      return null; // Not found
    } catch (e) {
      print('Error getting custom drink by ID: $e');
      return null;
    }
  }
}