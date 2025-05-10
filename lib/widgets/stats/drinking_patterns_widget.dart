
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';
import '../../widgets/common/fun_card.dart';
import '../../utils/theme.dart';

class DrinkingPatternsWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;

  const DrinkingPatternsWidget({
    Key? key,
    required this.dataService,
    required this.selectedTimeRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeekendDrinker = _calculateIsWeekendDrinker();
    final consistency = _calculateConsistency();
    final drinkingTrend = _calculateTrend();
    final preferredDrinks = _getPreferredDrinks();

    return FunCard(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Drinking Patterns 🧩',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: AppTheme.secondaryColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pattern insights - removed sober days, fixed overflow
          _buildPatternInsight(
            icon: CupertinoIcons.calendar,
            color: AppTheme.secondaryColor,
            title: isWeekendDrinker ? 'Weekend Preference' : 'Consistent Throughout Week',
            description: isWeekendDrinker
                ? 'You drink more on weekends'
                : 'Your drinking is spread throughout the week',
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.repeat,
            color: AppTheme.primaryColor,
            title: 'Consistency',
            description: consistency,
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.arrow_up_right,
            color: drinkingTrend.contains('decreasing')
                ? Colors.greenAccent
                : (drinkingTrend.contains('increasing')
                ? Colors.orangeAccent
                : AppTheme.primaryColor),
            title: 'Trend',
            description: drinkingTrend,
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.star,
            color: AppTheme.secondaryColor,
            title: 'Preferred Drinks',
            description: preferredDrinks,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternInsight({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Updated to analyze actual data
  bool _calculateIsWeekendDrinker() {
    final filteredDrinks = dataService.getFilteredDrinks(selectedTimeRange);

    if (filteredDrinks.isEmpty) return false;

    // Count drinks by day of week (1-7, where 6 and 7 are weekend)
    Map<int, double> drinksByDay = {};
    for (int i = 1; i <= 7; i++) {
      drinksByDay[i] = 0;
    }

    // Sum up standard drinks for each day of week
    for (final drink in filteredDrinks) {
      final dayOfWeek = drink.timestamp.weekday;
      drinksByDay[dayOfWeek] = (drinksByDay[dayOfWeek] ?? 0) + drink.standardDrinks;
    }

    // Calculate weekday and weekend totals
    final weekdayTotal = drinksByDay[1]! + drinksByDay[2]! +
        drinksByDay[3]! + drinksByDay[4]! + drinksByDay[5]!;
    final weekendTotal = drinksByDay[6]! + drinksByDay[7]!;

    // Calculate daily averages (to account for 5 weekdays vs 2 weekend days)
    final weekdayAverage = weekdayTotal / 5;
    final weekendAverage = weekendTotal / 2;

    // Consider weekend drinker if weekend average is at least 30% higher
    return weekendAverage > (weekdayAverage * 1.3);
  }

  String _calculateConsistency() {
    final filteredDrinks = dataService.getFilteredDrinks(selectedTimeRange);

    if (filteredDrinks.isEmpty) return 'Not enough data yet';

    // Group drinks by day
    Map<String, double> drinksByDay = {};
    for (final drink in filteredDrinks) {
      final dateString = DateFormat('yyyy-MM-dd').format(drink.timestamp);
      drinksByDay[dateString] = (drinksByDay[dateString] ?? 0) + drink.standardDrinks;
    }

    // Calculate standard deviation of daily drinks
    if (drinksByDay.length < 3) return 'Need more data for pattern analysis';

    final values = drinksByDay.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;

    double squaredDiffSum = 0;
    for (final value in values) {
      squaredDiffSum += pow(value - mean, 2);
    }

    final stdDev = sqrt(squaredDiffSum / values.length);
    final coefficientOfVariation = stdDev / mean;

    // Interpret the coefficient of variation
    if (coefficientOfVariation < 0.3) {
      return 'Your drinking pattern is very consistent';
    } else if (coefficientOfVariation < 0.6) {
      return 'Your drinking pattern is fairly consistent';
    } else if (coefficientOfVariation < 1.0) {
      return 'Your drinking varies from day to day';
    } else {
      return 'Your drinking pattern is highly variable';
    }
  }

  String _calculateTrend() {
    final filteredDrinks = dataService.getFilteredDrinks(selectedTimeRange);

    if (filteredDrinks.isEmpty || filteredDrinks.length < 5) {
      return 'Need more data for trend analysis';
    }

    // Group drinks by day
    Map<DateTime, double> drinksByDay = {};
    for (final drink in filteredDrinks) {
      // Normalize to start of day
      final day = DateTime(drink.timestamp.year, drink.timestamp.month, drink.timestamp.day);
      drinksByDay[day] = (drinksByDay[day] ?? 0) + drink.standardDrinks;
    }

    // Sort days chronologically
    final sortedDays = drinksByDay.keys.toList()..sort();

    // Not enough days for trend analysis
    if (sortedDays.length < 5) return 'Need more days for trend analysis';

    // Simple linear regression to determine trend
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = sortedDays.length;

    // Convert dates to numerical X values (days since first date)
    final firstDay = sortedDays.first;
    List<int> xValues = [];
    List<double> yValues = [];

    for (final day in sortedDays) {
      final x = day.difference(firstDay).inDays;
      final y = drinksByDay[day]!;

      xValues.add(x);
      yValues.add(y);

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    // Calculate slope of the line (positive = increasing, negative = decreasing)
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // Interpret the slope relative to the average consumption
    final avgY = sumY / n;
    final relativeSlope = slope / avgY;

    if (relativeSlope.abs() < 0.01) {
      return 'Your consumption is stable';
    } else if (relativeSlope > 0) {
      if (relativeSlope > 0.03) {
        return 'Your consumption is rapidly increasing';
      } else {
        return 'Your consumption is slightly increasing';
      }
    } else {
      if (relativeSlope < -0.03) {
        return 'Your consumption is rapidly decreasing';
      } else {
        return 'Your consumption is slightly decreasing';
      }
    }
  }

  String _getPreferredDrinks() {
    final drinksByCategory = dataService.getDrinksByCategory(selectedTimeRange);
    if (drinksByCategory.isEmpty) {
      return 'Not enough data to determine preferences';
    }

    final sortedEntries = drinksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.length == 1) {
      return 'Mostly ${sortedEntries[0].key}';
    } else if (sortedEntries.length >= 2) {
      return 'Mostly ${sortedEntries[0].key} and ${sortedEntries[1].key}';
    } else {
      return 'Not enough data to determine preferences';
    }
  }
}