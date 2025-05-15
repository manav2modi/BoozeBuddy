// // lib/services/google_places_service.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class PlacePrediction {
//   final String placeId;
//   final String description;
//   final String? mainText;
//   final String? secondaryText;
//   double? lat;
//   double? lng;
//
//   PlacePrediction({
//     required this.placeId,
//     required this.description,
//     this.mainText,
//     this.secondaryText,
//     this.lat,
//     this.lng,
//   });
// }
//
// class GooglePlacesService {
//   // You should store this in a secure place like .env file
//   static const String _apiKey = "YOUR_GOOGLE_API_KEY";
//
//   // Cache for recently used places
//   static const String _savedPlacesKey = 'saved_places';
//
//   // Get predictions from Google Places API
//   Future<List<PlacePrediction>> getPlacePredictions(String input) async {
//     if (input.isEmpty) {
//       return [];
//     }
//
//     // First, try to get from local cache
//     final localPredictions = await _getLocalSuggestions(input);
//     if (localPredictions.isNotEmpty) {
//       return localPredictions;
//     }
//
//     // Then, try Google API
//     final String url =
//         'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&types=establishment&language=en';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['status'] == 'OK') {
//           final List<dynamic> predictions = data['predictions'];
//
//           return predictions.map((prediction) {
//             return PlacePrediction(
//               placeId: prediction['place_id'],
//               description: prediction['description'],
//               mainText: prediction['structured_formatting']['main_text'],
//               secondaryText: prediction['structured_formatting']['secondary_text'],
//             );
//           }).toList();
//         }
//       }
//       return [];
//     } catch (e) {
//       debugPrint('Error fetching place predictions: $e');
//       return [];
//     }
//   }
//
//   // Get place details including latitude and longitude
//   Future<PlacePrediction?> getPlaceDetails(String placeId) async {
//     final String url =
//         'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey&fields=geometry,formatted_address';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['status'] == 'OK') {
//           final result = data['result'];
//           final location = result['geometry']['location'];
//
//           final PlacePrediction place = PlacePrediction(
//             placeId: placeId,
//             description: result['formatted_address'],
//             lat: location['lat'],
//             lng: location['lng'],
//           );
//
//           // Save to cache
//           _savePlaceToCache(place);
//
//           return place;
//         }
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error fetching place details: $e');
//       return null;
//     }
//   }
//
//   // Save place to local cache
//   Future<void> _savePlaceToCache(PlacePrediction place) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedPlacesJson = prefs.getStringList(_savedPlacesKey) ?? [];
//
//       final placeJson = jsonEncode({
//         'placeId': place.placeId,
//         'description': place.description,
//         'mainText': place.mainText,
//         'secondaryText': place.secondaryText,
//         'lat': place.lat,
//         'lng': place.lng,
//       });
//
//       // Check if place already exists
//       bool exists = false;
//       for (var i = 0; i < savedPlacesJson.length; i++) {
//         final existing = jsonDecode(savedPlacesJson[i]);
//         if (existing['placeId'] == place.placeId) {
//           savedPlacesJson[i] = placeJson; // Update existing
//           exists = true;
//           break;
//         }
//       }
//
//       // Add if not exists
//       if (!exists) {
//         savedPlacesJson.add(placeJson);
//
//         // Limit cache size to 20 most recent places
//         if (savedPlacesJson.length > 20) {
//           savedPlacesJson.removeAt(0);
//         }
//       }
//
//       await prefs.setStringList(_savedPlacesKey, savedPlacesJson);
//     } catch (e) {
//       debugPrint('Error saving place to cache: $e');
//     }
//   }
//
//   // Get local suggestions that match input
//   Future<List<PlacePrediction>> _getLocalSuggestions(String input) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedPlacesJson = prefs.getStringList(_savedPlacesKey) ?? [];
//
//       if (savedPlacesJson.isEmpty) {
//         return [];
//       }
//
//       final List<PlacePrediction> matches = [];
//
//       for (var placeJson in savedPlacesJson) {
//         final place = jsonDecode(placeJson);
//         final description = place['description'] as String;
//
//         if (description.toLowerCase().contains(input.toLowerCase())) {
//           matches.add(PlacePrediction(
//             placeId: place['placeId'],
//             description: description,
//             mainText: place['mainText'],
//             secondaryText: place['secondaryText'],
//             lat: place['lat'],
//             lng: place['lng'],
//           ));
//         }
//       }
//
//       return matches;
//     } catch (e) {
//       debugPrint('Error getting local suggestions: $e');
//       return [];
//     }
//   }
// }