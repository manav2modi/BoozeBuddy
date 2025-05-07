// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _costTrackingKey = 'cost_tracking_enabled';
  static const String _currencySymbolKey = 'currency_symbol';

  // Get cost tracking setting
  Future<bool> getCostTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_costTrackingKey) ?? false; // Default to disabled
  }

  // Set cost tracking setting
  Future<bool> setCostTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_costTrackingKey, enabled);
  }

  // Get currency symbol
  Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencySymbolKey) ?? '\$'; // Default to USD
  }

  // Set currency symbol
  Future<bool> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_currencySymbolKey, symbol);
  }
}