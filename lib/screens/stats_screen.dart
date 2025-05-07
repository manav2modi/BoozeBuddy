// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storageService = StorageService();
  List<Drink> _weeklyDrinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyDrinks();
  }

  Future<void> _loadWeeklyDrinks() async {
    setState(() {
      _isLoading = true;
    });

    // Get today and 7 days ago
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - 6);

    try {
      final drinks = await _storageService.getDrinksForDateRange(startOfWeek, now);

      setState(() {
        _weeklyDrinks = drinks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weekly drinks: $e');
      setState(() {
        _weeklyDrinks = [];
        _isLoading = false;
      });
    }
  }

  // Get map with date as key and total drinks as value
  Map<DateTime, double> get _drinksByDay {
    final Map<DateTime, double> result = {};

    // Initialize all days in the week with 0 drinks
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      result[date] = 0;
    }

    // Sum drinks for each day
    for (final drink in _weeklyDrinks) {
      final date = DateTime(
        drink.timestamp.year,
        drink.timestamp.month,
        drink.timestamp.day,
      );

      result[date] = (result[date] ?? 0) + drink.standardDrinks;
    }

    return result;
  }

  // Get drink counts by type
  Map<DrinkType, int> get _drinkCountByType {
    final Map<DrinkType, int> result = {};

    for (final drink in _weeklyDrinks) {
      result[drink.type] = (result[drink.type] ?? 0) + 1;
    }

    return result;
  }

  // Get total drinks for the week
  double get _totalDrinks {
    return _weeklyDrinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  }

  // Get drinks per day average
  double get _averageDrinksPerDay {
    if (_weeklyDrinks.isEmpty) return 0;

    // Get number of unique days with drinks
    final uniqueDays = _drinksByDay.values.where((count) => count > 0).length;

    if (uniqueDays == 0) return 0;

    return _totalDrinks / uniqueDays;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _loadWeeklyDrinks,
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _weeklyDrinks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  size: 72,
                  color: CupertinoColors.systemGrey3,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No drinks logged in the last 7 days",
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekly Summary Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Summary 📊',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatTile(
                            emoji: '🥃',
                            title: 'Total',
                            value: _totalDrinks.toStringAsFixed(1),
                          ),
                          _StatTile(
                            emoji: '📅',
                            title: 'Avg/Day',
                            value: _averageDrinksPerDay.toStringAsFixed(1),
                          ),
                          _StatTile(
                            emoji: '🔝',
                            title: 'Most Common',
                            value: _drinkCountByType.isEmpty
                                ? 'N/A'
                                : Drink.getEmojiForType(
                                _drinkCountByType.entries
                                    .reduce((a, b) =>
                                a.value > b.value ? a : b)
                                    .key),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Weekly Chart
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 7 Days 📈',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _SimpleBarChart(
                          data: _drinksByDay,
                          maxValue: _drinksByDay.values.isEmpty
                              ? 5
                              : (_drinksByDay.values
                              .reduce((a, b) => a > b ? a : b) +
                              1),
                          barColor: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                // Drink Types Distribution
                if (_drinkCountByType.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drinks by Type 🍹',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._drinkCountByType.entries
                            .toList()
                            .map((entry) {
                          final type = entry.key;
                          final count = entry.value;
                          final percentage = count /
                              _weeklyDrinks.length *
                              100;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${Drink.getEmojiForType(type)} ${type.toString().split('.').last}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$count (${percentage.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: Drink.getColorForType(type),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: count / _weeklyDrinks.length,
                                    backgroundColor:
                                    CupertinoColors.systemGrey5,
                                    color: Drink.getColorForType(type),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const _StatTile({
    required this.emoji,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  final Map<DateTime, double> data;
  final double maxValue;
  final Color barColor;

  const _SimpleBarChart({
    required this.data,
    required this.maxValue,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    // Sort dates in ascending order
    final sortedDates = data.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sortedDates.map((date) {
        final value = data[date] ?? 0;
        final percentage = value / maxValue;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label
                Text(
                  value > 0 ? value.toStringAsFixed(1) : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: value > 0 ? barColor : Colors.transparent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                Container(
                  height: 150 * percentage,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: value > 0 ? barColor : CupertinoColors.systemGrey5,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Day label
                Text(
                  DateFormat('E').format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}