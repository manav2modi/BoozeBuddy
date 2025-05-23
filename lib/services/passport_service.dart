// lib/services/passport_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../models/passport_session.dart';
import 'storage_service.dart';

class PassportService {
  static const String _passportSessionsKey = 'passport_sessions';
  final StorageService _storageService = StorageService();

  // Get all passport sessions
  Future<List<PassportSession>> getPassportSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? sessionsJson = prefs.getStringList(_passportSessionsKey);

      if (sessionsJson == null || sessionsJson.isEmpty) {
        return [];
      }

      // Convert JSON strings to PassportSession objects
      List<PassportSession> sessions = [];
      for (var sessionJson in sessionsJson) {
        final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

        // Get drinks for this session
        final List<String> drinkIds = List<String>.from(sessionMap['drinkIds']);
        final List<Drink> drinks = await _getDrinksForSession(drinkIds);

        sessions.add(PassportSession(
          id: sessionMap['id'],
          sessionName: sessionMap['sessionName'],
          startTime: DateTime.parse(sessionMap['startTime']),
          endTime: DateTime.parse(sessionMap['endTime']),
          locationNames: List<String>.from(sessionMap['locationNames']),
          drinks: drinks,
          photoPath: sessionMap['photoPath'],
          stamps: List<PassportStamp>.from(
              sessionMap['stampIds'].map((id) => _getStampById(id))
          ),
        ));
      }

      return sessions;
    } catch (e) {
      print('Error getting passport sessions: $e');
      return [];
    }
  }

  // Get a single passport session
  Future<PassportSession?> getPassportSessionById(String id) async {
    final sessions = await getPassportSessions();
    for (var session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  // Generate a passport session for a date
  Future<PassportSession?> generatePassportForDate(DateTime date, String sessionName) async {
    // Get all drinks for this date
    final drinks = await _storageService.getDrinksForDate(date);

    if (drinks.isEmpty) {
      return null; // No drinks to create a passport
    }

    // Get unique locations
    final Set<String> locations = {};
    for (var drink in drinks) {
      if (drink.location != null && drink.location!.isNotEmpty) {
        locations.add(drink.location!);
      }
    }

    // Determine start and end times
    final startTime = DateTime(date.year, date.month, date.day, 6); // 6 AM
    final endTime = DateTime(date.year, date.month, date.day + 1, 6); // 6 AM next day

    // Determine stamps
    List<PassportStamp> stamps = _determineStamps(drinks, locations);

    // Create a passport session
    final session = PassportSession(
      id: const Uuid().v4(),
      sessionName: sessionName,
      startTime: startTime,
      endTime: endTime,
      locationNames: locations.toList(),
      drinks: drinks,
      photoPath: null, // No photo initially
      stamps: stamps,
    );

    // Save the session
    await _savePassportSession(session);

    return session;
  }

  // Save a passport session
  Future<bool> _savePassportSession(PassportSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing sessions
      List<String>? sessionsJson = prefs.getStringList(_passportSessionsKey) ?? [];

      // Convert session to JSON map
      Map<String, dynamic> sessionMap = {
        'id': session.id,
        'sessionName': session.sessionName,
        'startTime': session.startTime.toIso8601String(),
        'endTime': session.endTime.toIso8601String(),
        'locationNames': session.locationNames,
        'drinkIds': session.drinks.map((d) => d.id).toList(),
        'photoPath': session.photoPath,
        'stampIds': session.stamps.map((s) => s.id).toList(),
      };

      // Add new session JSON
      sessionsJson.add(jsonEncode(sessionMap));

      // Save to storage
      return await prefs.setStringList(_passportSessionsKey, sessionsJson);
    } catch (e) {
      print('Error saving passport session: $e');
      return false;
    }
  }

  // Update a passport session (e.g., add photo, rename)
  Future<bool> updatePassportSession(
      String id,
      {String? newName, String? photoPath}
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? sessionsJson = prefs.getStringList(_passportSessionsKey);

      if (sessionsJson == null || sessionsJson.isEmpty) {
        return false;
      }

      List<String> updatedSessionsJson = [];
      bool found = false;

      for (var sessionJson in sessionsJson) {
        final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

        if (sessionMap['id'] == id) {
          found = true;

          // Update fields
          if (newName != null) {
            sessionMap['sessionName'] = newName;
          }

          if (photoPath != null) {
            sessionMap['photoPath'] = photoPath;

            // Add photographer stamp if not already present
            List<String> stampIds = List<String>.from(sessionMap['stampIds']);
            if (!stampIds.contains(PassportStamp.photographer.id)) {
              stampIds.add(PassportStamp.photographer.id);
              sessionMap['stampIds'] = stampIds;
            }
          }

          updatedSessionsJson.add(jsonEncode(sessionMap));
        } else {
          updatedSessionsJson.add(sessionJson);
        }
      }

      if (!found) {
        return false;
      }

      // Save updated sessions
      return await prefs.setStringList(_passportSessionsKey, updatedSessionsJson);
    } catch (e) {
      print('Error updating passport session: $e');
      return false;
    }
  }

  // Helper method to get drinks for a session
  Future<List<Drink>> _getDrinksForSession(List<String> drinkIds) async {
    final allDrinks = await _storageService.getDrinks();
    return allDrinks.where((drink) => drinkIds.contains(drink.id)).toList();
  }

  // Add these methods to lib/services/passport_service.dart

  // Remove photo from a passport session
  Future<bool> removePassportPhoto(String id) async {
    return await updatePassportSession(id, photoPath: ''); // Empty string to remove photo
  }

  // Update passport name
  Future<bool> updatePassportName(String id, String newName) async {
    return await updatePassportSession(id, newName: newName);
  }

  // Refresh drinks for an existing passport session
  Future<PassportSession?> refreshPassportDrinks(String sessionId) async {
    try {
      final session = await getPassportSessionById(sessionId);
      if (session == null) return null;

      // Get fresh drinks for the date
      final drinks = await _storageService.getDrinksForDate(session.startTime);

      if (drinks.isEmpty) return session; // Return existing session if no drinks

      // Get unique locations from fresh drinks
      final Set<String> locations = {};
      for (var drink in drinks) {
        if (drink.location != null && drink.location!.isNotEmpty) {
          locations.add(drink.location!);
        }
      }

      // Re-determine stamps with fresh data
      List<PassportStamp> stamps = _determineStamps(drinks, locations);

      // Keep photographer stamp if photo exists
      if (session.photoPath != null && session.photoPath!.isNotEmpty) {
        if (!stamps.any((s) => s.id == PassportStamp.photographer.id)) {
          stamps.add(PassportStamp.photographer);
        }
      }

      // Update the session in storage
      final prefs = await SharedPreferences.getInstance();
      List<String>? sessionsJson = prefs.getStringList(_passportSessionsKey);

      if (sessionsJson == null || sessionsJson.isEmpty) return null;

      List<String> updatedSessionsJson = [];

      for (var sessionJson in sessionsJson) {
        final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);

        if (sessionMap['id'] == sessionId) {
          // Update with fresh data
          sessionMap['drinkIds'] = drinks.map((d) => d.id).toList();
          sessionMap['locationNames'] = locations.toList();
          sessionMap['stampIds'] = stamps.map((s) => s.id).toList();
        }

        updatedSessionsJson.add(jsonEncode(sessionMap));
      }

      await prefs.setStringList(_passportSessionsKey, updatedSessionsJson);

      // Return refreshed session
      return PassportSession(
        id: session.id,
        sessionName: session.sessionName,
        startTime: session.startTime,
        endTime: session.endTime,
        locationNames: locations.toList(),
        drinks: drinks,
        photoPath: session.photoPath,
        stamps: stamps,
      );
    } catch (e) {
      print('Error refreshing passport drinks: $e');
      return null;
    }
  }

  // Helper method to get a stamp by ID
  PassportStamp _getStampById(String id) {
    switch (id) {
      case 'explorer': return PassportStamp.explorer;
      case 'mixologist': return PassportStamp.mixologist;
      case 'photographer': return PassportStamp.photographer;
      case 'social_butterfly': return PassportStamp.socialButterfly;
      case 'moderate_drinker': return PassportStamp.moderateDrinker;
      default: throw ArgumentError('Invalid stamp ID: $id');
    }
  }

  // Helper method to determine which stamps to award
  List<PassportStamp> _determineStamps(
      List<Drink> drinks,
      Set<String> locations
      ) {
    List<PassportStamp> stamps = [];

    // Explorer stamp (2+ locations)
    if (locations.length >= 2) {
      stamps.add(PassportStamp.explorer);
    }

    // Mixologist stamp (2+ drink types)
    final drinkTypes = drinks.map((d) => d.type).toSet();
    if (drinkTypes.length >= 2) {
      stamps.add(PassportStamp.mixologist);
    }

    // Social Butterfly (5+ drinks)
    if (drinks.length >= 5) {
      stamps.add(PassportStamp.socialButterfly);
    }

    // Moderate Drinker (< 3 standard drinks)
    final totalStandardDrinks = drinks.fold<double>(
      0.0,
          (sum, drink) => sum + (drink.standardDrinks ?? 0.0),
    );

    if (totalStandardDrinks < 3.0) {
      stamps.add(PassportStamp.moderateDrinker);
    }

    return stamps;
  }
}