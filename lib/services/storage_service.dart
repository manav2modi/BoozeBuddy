// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drink.dart';

class StorageService {
  static const _drinksKey = 'drinks';

  Future<List> getDrinks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_drinksKey);
    if (jsonString == null) return [];
    final List decoded = json.decode(jsonString);
    return decoded.map((item) => Drink.fromMap(item)).toList();
  }

  Future saveDrinks(List drinks) async {
    final prefs = await SharedPreferences.getInstance();
    final List maps = drinks.map((d) => d.toMap()).toList();
    await prefs.setString(_drinksKey, json.encode(maps));
  }

  Future addDrink(Drink drink) async {
    final drinks = await getDrinks();
    drinks.add(drink);
    await saveDrinks(drinks);
  }
}