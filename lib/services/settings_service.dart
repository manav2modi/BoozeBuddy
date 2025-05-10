// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _costTrackingKey = 'cost_tracking_enabled';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _settingsInitializedKey = 'settings_initialized';

  // Initialize default settings for first-time users
  Future<void> initializeDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_settingsInitializedKey) ?? false;

    // Only set defaults if this is the first time initializing settings
    if (!initialized) {
      // Set cost tracking to enabled by default
      await prefs.setBool(_costTrackingKey, true);

      // Set default currency to USD
      await prefs.setString(_currencySymbolKey, '\$');

      // Mark settings as initialized
      await prefs.setBool(_settingsInitializedKey, true);
    }
  }

  // Get cost tracking setting
  Future<bool> getCostTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_costTrackingKey) ?? true; // Default to enabled
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