// lib/models/passport_session.dart
import 'drink.dart';

class PassportSession {
  final String id;
  final DateTime startTime; // 6am on selected day
  final DateTime endTime;   // 6am next day
  final String? locationName;
  final List<Drink> drinks;
  final String? photoPath;
  final List<String> achievedStamps;

  // Calculated fields
  double get totalStandardDrinks => drinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  double get totalCost => drinks.fold(0, (sum, drink) => sum + (drink.cost ?? 0));
  int get uniqueLocations => drinks.map((d) => d.location).where((l) => l != null).toSet().length;
  int get uniqueDrinkTypes => drinks.map((d) => d.type).toSet().length;

  PassportSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.locationName,
    required this.drinks,
    this.photoPath,
    required this.achievedStamps,
  });
}