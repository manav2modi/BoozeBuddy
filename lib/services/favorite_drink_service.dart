// lib/services/favorite_drink_service.dart
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/favorite_drink.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';

class FavoriteDrinkService {
  static const String _favoritesKey = 'favorite_drinks';

  // Get all favorite drinks
  Future<List<FavoriteDrink>> getFavoriteDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? favoritesJson = prefs.getStringList(_favoritesKey);

      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }

      return favoritesJson
          .map((drinkJson) => FavoriteDrink.fromJson(jsonDecode(drinkJson)))
          .toList();
    } catch (e) {
      print('Error getting favorite drinks: $e');
      return [];
    }
  }

  // Save a new favorite drink
  Future<bool> addFavoriteDrink(FavoriteDrink drink) async {
    try {
      // Get existing favorites
      final favorites = await getFavoriteDrinks();

      // Check if an EXACT duplicate already exists
      bool exactDuplicateExists = favorites.any((fav) =>
      fav.type == drink.type &&
          fav.customDrinkId == drink.customDrinkId &&
          fav.standardDrinks == drink.standardDrinks &&
          fav.name == drink.name);

      if (exactDuplicateExists) {
        return true; // Already a favorite, no need to add again
      }

      // Generate a unique name for the favorite if needed
      String uniqueName = drink.name;
      if (favorites.any((fav) =>
      fav.type == drink.type &&
          fav.name == drink.name)) {
        // Add the standard drinks to the name to differentiate
        uniqueName = "${drink.name} (${drink.standardDrinks})";
      }

      // Create a drink with the possibly updated name
      final drinkToAdd = FavoriteDrink(
        id: drink.id,
        name: uniqueName,
        emoji: drink.emoji,
        type: drink.type,
        standardDrinks: drink.standardDrinks,
        color: drink.color,
        customDrinkId: drink.customDrinkId,
        note: drink.note,
        cost: drink.cost,
        location: drink.location,
      );

      // Add the favorite
      favorites.add(drinkToAdd);

      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      List<String> favoritesJson = favorites.map((drink) => jsonEncode(drink.toJson())).toList();
      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error adding favorite drink: $e');
      return false;
    }
  }

  // Remove a favorite drink
  Future<bool> removeFavoriteDrink(String id) async {
    try {
      // Get existing favorites
      final favorites = await getFavoriteDrinks();

      // Remove the drink with matching ID
      favorites.removeWhere((drink) => drink.id == id);

      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      List<String> favoritesJson = favorites.map((drink) => jsonEncode(drink.toJson())).toList();
      return await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error removing favorite drink: $e');
      return false;
    }
  }

  // Check if a drink is a favorite
  Future<FavoriteDrink?> findSimilarFavorite(Drink drink) async {
    final favorites = await getFavoriteDrinks();

    for (var favorite in favorites) {
      if (favorite.type == drink.type &&
          favorite.customDrinkId == drink.customDrinkId &&
          favorite.standardDrinks == drink.standardDrinks) {
        return favorite;
      }
    }

    return null;
  }

  // Helper to create a FavoriteDrink from a Drink
  Future<FavoriteDrink> createFavoriteFromDrink(
      Drink drink,
      Map<String, CustomDrink> customDrinksMap
      ) async {
    String name;
    String emoji;
    Color color;

    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      // Use custom drink info if available
      final customDrink = customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        name = customDrink.name;
        emoji = customDrink.emoji;
        color = customDrink.color;
      } else {
        name = 'Custom Drink';
        emoji = '🍻';
        color = Drink.getColorForType(drink.type);
      }
    } else {
      // Use standard drink info
      switch (drink.type) {
        case DrinkType.beer:
          name = 'Beer';
          break;
        case DrinkType.wine:
          name = 'Wine';
          break;
        case DrinkType.cocktail:
          name = 'Cocktail';
          break;
        case DrinkType.shot:
          name = 'Shot';
          break;
        case DrinkType.other:
          name = 'Other';
          break;
        default:
          name = 'Drink';
      }

      emoji = Drink.getEmojiForType(drink.type);
      color = Drink.getColorForType(drink.type);
    }

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
}