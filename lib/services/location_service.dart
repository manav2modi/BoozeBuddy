// lib/services/location_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _locationsKey = 'saved_locations';
  static const int _maxSavedLocations = 20; // Limit the number of saved locations

  // Get all saved locations
  Future<List<String>> getSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> locations = prefs.getStringList(_locationsKey) ?? [];

    // If no saved locations, provide some default ones for better testing
    if (locations.isEmpty) {
      locations = [
        'New York, NY',
        'Brooklyn Bar',
        'Home',
        'The Local Pub',
        'Manhattan',
        'Queens',
        'Bronx',
        'Friends Home'
      ];
      // Save these defaults
      await prefs.setStringList(_locationsKey, locations);
    }

    return locations;
  }

  // Save a new location
  Future<bool> saveLocation(String location) async {
    if (location.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final locations = await getSavedLocations();

    // Don't add duplicates - but move to top if exists
    if (locations.contains(location)) {
      locations.remove(location);
      locations.insert(0, location); // Move to the top
    } else {
      // Add new location at the top
      locations.insert(0, location);

      // Limit the number of saved locations
      if (locations.length > _maxSavedLocations) {
        locations.removeLast();
      }
    }

    return prefs.setStringList(_locationsKey, locations);
  }

  // Get location suggestions based on query
  Future<List<String>> getLocationSuggestions(String query) async {
    if (query.isEmpty) return [];

    final locations = await getSavedLocations();

    // Filter locations that contain the query (case insensitive)
    return locations
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Clear all saved locations
  Future<bool> clearSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_locationsKey);
  }
}