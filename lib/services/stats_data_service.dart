// lib/services/stats_data_service.dart
import 'dart:ui';

import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/custom_drinks_service.dart';
import '../screens/stats_screen.dart';

class StatsDataService {
  final CustomDrinksService _customDrinksService;
  List<Drink> _drinks = [];
  List<CustomDrink> _customDrinks = [];

  StatsDataService(this._customDrinksService);

  void updateDrinks(List<Drink> drinks) {
    _drinks = drinks;
  }

  Future<void> loadCustomDrinks() async {
    try {
      _customDrinks = await _customDrinksService.getCustomDrinks();
    } catch (e) {
      print('Error loading custom drinks in stats data service: $e');
      _customDrinks = [];
    }
  }

  // Get filtered drinks based on selected time range
  List<Drink> getFilteredDrinks(TimeRange timeRange) {
    final now = DateTime.now();
    DateTime startDate;

    switch (timeRange) {
      case TimeRange.week:
        startDate = DateTime(now.year, now.month, now.day - 6);
        break;
      case TimeRange.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimeRange.threeMonths:
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case TimeRange.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimeRange.allTime:
        return _drinks;
    }

    return _drinks.where((drink) {
      return drink.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          drink.timestamp.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  // Get the custom drink for a specific ID
  CustomDrink? getCustomDrinkById(String id) {
    for (var drink in _customDrinks) {
      if (drink.id == id) {
        return drink;
      }
    }
    return null;
  }

  // Get chart data based on time range - with proper grouping
  Map<String, double> getChartData(TimeRange timeRange) {
    final Map<String, double> result = {};
    final now = DateTime.now();
    final filteredDrinks = getFilteredDrinks(timeRange);

    switch (timeRange) {
      case TimeRange.week:
      // Show daily data for the week
        for (int i = 6; i >= 0; i--) {
          final date = DateTime(now.year, now.month, now.day - i);
          final dateStr = DateFormat('E').format(date); // Mon, Tue, etc.
          result[dateStr] = 0;
        }

        // Sum drinks for each day
        for (final drink in filteredDrinks) {
          final dateStr = DateFormat('E').format(drink.timestamp);
          result[dateStr] = (result[dateStr] ?? 0) + drink.standardDrinks;
        }
        break;

      case TimeRange.month:
      // Group by week for month view
        for (int i = 0; i < 5; i++) {
          final weekStart = now.subtract(Duration(days: now.weekday + 7 * i - 1));
          if (weekStart.isBefore(now.subtract(const Duration(days: 30)))) {
            break;
          }
          final weekLabel = 'Week ${5 - i}';
          result[weekLabel] = 0;
        }

        // Sum drinks for each week
        for (final drink in filteredDrinks) {
          final weekDiff = now.difference(drink.timestamp).inDays ~/ 7;
          if (weekDiff < 5) {
            final weekLabel = 'Week ${5 - weekDiff}';
            result[weekLabel] = (result[weekLabel] ?? 0) + drink.standardDrinks;
          }
        }
        break;

      case TimeRange.threeMonths:
      // Group by week for 3-month view
        final labels = <String>[];
        for (int i = 0; i < 12; i++) {
          final weekStart = now.subtract(Duration(days: now.weekday + 7 * i - 1));
          if (weekStart.isBefore(now.subtract(const Duration(days: 90)))) {
            break;
          }

          // Format week as "MM/DD"
          final weekLabel = DateFormat('MM/dd').format(weekStart);
          labels.add(weekLabel);
          result[weekLabel] = 0;
        }

        // Sum drinks for each week
        for (final drink in filteredDrinks) {
          final weekDiff = now.difference(drink.timestamp).inDays ~/ 7;
          if (weekDiff < labels.length) {
            final weekLabel = labels[weekDiff];
            result[weekLabel] = (result[weekLabel] ?? 0) + drink.standardDrinks;
          }
        }
        break;

      case TimeRange.year:
      case TimeRange.allTime:
      // Group by month for year and all-time views
        int monthsToShow = 12;
        if (timeRange == TimeRange.allTime && filteredDrinks.isNotEmpty) {
          final earliestDrink = filteredDrinks.reduce(
                  (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b
          );
          final months = (now.year - earliestDrink.timestamp.year) * 12 +
              (now.month - earliestDrink.timestamp.month);
          monthsToShow = (months + 1).clamp(1, 24); // Limit to 24 months max
        }

        // Initialize months with 0 drinks
        for (int i = monthsToShow - 1; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          final monthLabel = DateFormat('MMM').format(date); // Jan, Feb, etc.
          result[monthLabel] = 0;
        }

        // Sum drinks for each month
        for (final drink in filteredDrinks) {
          final monthLabel = DateFormat('MMM').format(drink.timestamp);
          result[monthLabel] = (result[monthLabel] ?? 0) + drink.standardDrinks;
        }
        break;
    }

    return result;
  }

  // Get cost chart data (similar to getChartData but for costs)
  Map<String, double> getCostChartData(TimeRange timeRange) {
    final Map<String, double> result = {};
    final chartData = getChartData(timeRange);
    final filteredDrinks = getFilteredDrinks(timeRange);

    // Initialize with same structure as chartData
    chartData.keys.forEach((key) {
      result[key] = 0;
    });

    // Sum costs for each period
    for (final drink in filteredDrinks) {
      // Skip drinks without cost data
      if (drink.cost == null) continue;

      String label;
      final now = DateTime.now();

      switch (timeRange) {
        case TimeRange.week:
          label = DateFormat('E').format(drink.timestamp);
          break;
        case TimeRange.month:
          final weekDiff = now.difference(drink.timestamp).inDays ~/ 7;
          if (weekDiff < 5) {
            label = 'Week ${5 - weekDiff}';
          } else {
            continue; // Skip if outside range
          }
          break;
        case TimeRange.threeMonths:
          final weekDiff = now.difference(drink.timestamp).inDays ~/ 7;
          if (weekDiff < 12) {
            final weekStart = now.subtract(Duration(days: now.weekday + 7 * weekDiff - 1));
            label = DateFormat('MM/dd').format(weekStart);
          } else {
            continue; // Skip if outside range
          }
          break;
        case TimeRange.year:
        case TimeRange.allTime:
          label = DateFormat('MMM').format(drink.timestamp);
          break;
      }

      if (result.containsKey(label)) {
        result[label] = (result[label] ?? 0) + drink.cost!;
      }
    }

    return result;
  }

  // Enhanced drink type display for statistics to include custom drinks
  Map<String, double> getDrinksByCategory(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    final Map<String, double> result = {};

    // Initialize standard categories
    result['Beer'] = 0;
    result['Wine'] = 0;
    result['Cocktail'] = 0;
    result['Shot'] = 0;
    result['Other'] = 0;

    // Add custom categories
    Map<String, double> customCategories = {};

    for (final drink in filteredDrinks) {
      if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
        // Try to find the custom drink
        final customDrink = getCustomDrinkById(drink.customDrinkId!);
        if (customDrink != null) {
          // Add to custom categories
          final name = customDrink.name;
          customCategories[name] = (customCategories[name] ?? 0) + drink.standardDrinks;
        } else {
          // If custom drink not found, add to Other
          result['Other'] = result['Other']! + drink.standardDrinks;
        }
      } else {
        // Add to standard categories
        switch (drink.type) {
          case DrinkType.beer:
            result['Beer'] = result['Beer']! + drink.standardDrinks;
            break;
          case DrinkType.wine:
            result['Wine'] = result['Wine']! + drink.standardDrinks;
            break;
          case DrinkType.cocktail:
            result['Cocktail'] = result['Cocktail']! + drink.standardDrinks;
            break;
          case DrinkType.shot:
            result['Shot'] = result['Shot']! + drink.standardDrinks;
            break;
          case DrinkType.other:
          case DrinkType.custom: // Fallback
            result['Other'] = result['Other']! + drink.standardDrinks;
            break;
        }
      }
    }

    // Add custom categories to the result
    // Only include top custom drinks to avoid cluttering
    final sortedCustomCategories = customCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Add top 3 custom drink types
    for (int i = 0; i < sortedCustomCategories.length && i < 3; i++) {
      final entry = sortedCustomCategories[i];
      result[entry.key] = entry.value;
    }

    // Remove any categories with 0 drinks
    result.removeWhere((key, value) => value == 0);

    return result;
  }

  // Get emoji for a category
  String getEmojiForCategory(String category) {
    // Check if it's a standard category
    switch (category) {
      case 'Beer':
        return '🍺';
      case 'Wine':
        return '🍷';
      case 'Cocktail':
        return '🍹';
      case 'Shot':
        return '🥃';
      case 'Other':
        return '🍸';
      default:
      // Check if it's a custom category
        for (var customDrink in _customDrinks) {
          if (customDrink.name == category) {
            return customDrink.emoji;
          }
        }
        // Default emoji if not found
        return '🍻';
    }
  }

  // Get color for a category
  Color getColorForCategory(String category) {
    // Check if it's a standard category
    switch (category) {
      case 'Beer':
        return const Color(0xFFFFC107);
      case 'Wine':
        return const Color(0xFFFF5252);
      case 'Cocktail':
        return const Color(0xFFFF4081);
      case 'Shot':
        return const Color(0xFFFF9800);
      case 'Other':
        return const Color(0xFFB388FF);
      default:
      // Check if it's a custom category
        for (var customDrink in _customDrinks) {
          if (customDrink.name == category) {
            return customDrink.color;
          }
        }
        // Default color if not found
        return const Color(0xFF64B5F6);
    }
  }

  // Get costs by drink type
  Map<String, double> getCostsByCategory(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    final Map<String, double> result = {};
    final categories = getDrinksByCategory(timeRange).keys.toList();

    // Initialize categories with zero costs
    for (var category in categories) {
      result[category] = 0;
    }

    for (final drink in filteredDrinks) {
      if (drink.cost == null) continue;

      String category = 'Other';

      if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
        // Try to find the custom drink
        final customDrink = getCustomDrinkById(drink.customDrinkId!);
        if (customDrink != null) {
          category = customDrink.name;
        }
      } else {
        // Standard drink types
        switch (drink.type) {
          case DrinkType.beer:
            category = 'Beer';
            break;
          case DrinkType.wine:
            category = 'Wine';
            break;
          case DrinkType.cocktail:
            category = 'Cocktail';
            break;
          case DrinkType.shot:
            category = 'Shot';
            break;
          case DrinkType.other:
          case DrinkType.custom:
            category = 'Other';
            break;
        }
      }

      // Add cost to category if it exists in our results
      if (result.containsKey(category)) {
        result[category] = result[category]! + drink.cost!;
      }
    }

    return result;
  }

  // Get total drinks for the selected time range
  double totalStandardDrinks(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    return filteredDrinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  }

  // Get total cost for the selected time range
  double totalCost(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    return filteredDrinks.fold(0, (sum, drink) => sum + (drink.cost ?? 0));
  }

  // Get all days where drinks were consumed
  Map<String, bool> _getDrinkingDays(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    final Map<String, bool> drinkingDays = {};

    for (final drink in filteredDrinks) {
      final dateString = DateFormat('yyyy-MM-dd').format(drink.timestamp);
      drinkingDays[dateString] = true;
    }

    return drinkingDays;
  }

  // Get total drinking days
  int totalDrinkingDays(TimeRange timeRange) {
    return _getDrinkingDays(timeRange).length;
  }

  // Get drinks per day average
  double averageDrinksPerDay(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    if (filteredDrinks.isEmpty) return 0;

    // Get number of days with drinks
    final daysWithDrinks = _getDrinkingDays(timeRange).length;

    // If no days with drinks, return 0
    if (daysWithDrinks == 0) return 0;

    // Return average drinks per active drinking day
    return totalStandardDrinks(timeRange) / daysWithDrinks;
  }

  // Get average cost per drink
  double averageCostPerDrink(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    final drinksWithCost = filteredDrinks.where((drink) => drink.cost != null).toList();

    if (drinksWithCost.isEmpty) return 0;

    final totalCostValue = drinksWithCost.fold<double>(
        0.0, (double sum, drink) => sum + (drink.cost ?? 0));

    return totalCostValue / drinksWithCost.length;
  }

  // Get the most drinks consumed in a single day
  double maxDrinksInOneDay(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    if (filteredDrinks.isEmpty) return 0;

    // Group drinks by day
    final Map<String, double> drinksByDay = {};

    for (final drink in filteredDrinks) {
      final dateString = DateFormat('yyyy-MM-dd').format(drink.timestamp);
      drinksByDay[dateString] = (drinksByDay[dateString] ?? 0) + drink.standardDrinks;
    }

    if (drinksByDay.isEmpty) return 0;

    return drinksByDay.values.reduce((max, value) => max > value ? max : value);
  }

  // Get the day of week with most drinks
  String mostPopularDayOfWeek(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    if (filteredDrinks.isEmpty) return 'N/A';

    final Map<int, double> drinksByDayOfWeek = {};

    // Initialize days of week with 0 drinks
    for (int i = 1; i <= 7; i++) {
      drinksByDayOfWeek[i] = 0;
    }

    // Sum drinks for each day of week
    for (final drink in filteredDrinks) {
      final dayOfWeek = drink.timestamp.weekday;
      drinksByDayOfWeek[dayOfWeek] = (drinksByDayOfWeek[dayOfWeek] ?? 0) + drink.standardDrinks;
    }

    // Find day of week with most drinks
    int? mostPopularDay = drinksByDayOfWeek.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Convert day number to name
    switch (mostPopularDay) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'N/A';
    }
  }

  // Get top locations
  Map<String, int> getTopLocations(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    final Map<String, int> locationCounts = {};

    for (final drink in filteredDrinks) {
      if (drink.location != null && drink.location!.isNotEmpty) {
        locationCounts[drink.location!] = (locationCounts[drink.location!] ?? 0) + 1;
      }
    }

    // Sort by count (descending)
    final sortedEntries = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top locations (limited to 5)
    final Map<String, int> result = {};
    final topEntries = sortedEntries.take(5);
    for (final entry in topEntries) {
      result[entry.key] = entry.value;
    }

    return result;
  }

  // Check if we have any location data
  bool hasLocationData(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    for (final drink in filteredDrinks) {
      if (drink.location != null && drink.location!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  // Count drinks with location data
  int drinksWithLocation(TimeRange timeRange) {
    final filteredDrinks = getFilteredDrinks(timeRange);
    return filteredDrinks.where((drink) =>
    drink.location != null && drink.location!.isNotEmpty).length;
  }
}