// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';

enum TimeRange {
  week,
  month,
  threeMonths,
  year,
  allTime
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  List<Drink> _drinks = [];
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.week;
  bool _costTrackingEnabled = false;
  String _currencySymbol = '\$';

  // Colors
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _chartBarColor = Color(0xFF007AFF); // iOS blue
  static const Color _chartInactiveColor = Color(0xFF353535);
  static const Color _segmentedControlColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDrinks();
  }

  Future<void> _loadSettings() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    final currencySymbol = await _settingsService.getCurrencySymbol();

    setState(() {
      _costTrackingEnabled = costTrackingEnabled;
      _currencySymbol = currencySymbol;
    });
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all drinks
      final allDrinks = await _storageService.getDrinks();

      setState(() {
        _drinks = allDrinks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading drinks: $e');
      setState(() {
        _drinks = [];
        _isLoading = false;
      });
    }
  }

  // Get filtered drinks based on selected time range
  List<Drink> get _filteredDrinks {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeRange) {
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

  // Get chart data based on time range - with proper grouping
  Map<String, double> get _chartData {
    final Map<String, double> result = {};
    final now = DateTime.now();
    final filteredDrinks = _filteredDrinks;

    switch (_selectedTimeRange) {
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
        if (_selectedTimeRange == TimeRange.allTime && filteredDrinks.isNotEmpty) {
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

  // Get cost chart data (similar to _chartData but for costs)
  Map<String, double> get _costChartData {
    if (!_costTrackingEnabled) return {};

    final Map<String, double> result = {};
    final now = DateTime.now();
    final filteredDrinks = _filteredDrinks;

    // Initialize with same structure as _chartData
    _chartData.keys.forEach((key) {
      result[key] = 0;
    });

    // Sum costs for each period
    for (final drink in filteredDrinks) {
      // Skip drinks without cost data
      if (drink.cost == null) continue;

      String label;
      switch (_selectedTimeRange) {
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

  // Get drink counts by type
  Map<DrinkType, int> get _drinkCountByType {
    final Map<DrinkType, int> result = {};

    for (final drink in _filteredDrinks) {
      result[drink.type] = (result[drink.type] ?? 0) + 1;
    }

    return result;
  }

  // Get standard drinks by type
  Map<DrinkType, double> get _standardDrinksByType {
    final Map<DrinkType, double> result = {};

    for (final drink in _filteredDrinks) {
      result[drink.type] = (result[drink.type] ?? 0) + drink.standardDrinks;
    }

    return result;
  }

  // Get costs by drink type
  Map<DrinkType, double> get _costsByType {
    if (!_costTrackingEnabled) return {};

    final Map<DrinkType, double> result = {};

    for (final drink in _filteredDrinks) {
      if (drink.cost != null) {
        result[drink.type] = (result[drink.type] ?? 0) + drink.cost!;
      }
    }

    return result;
  }

  // Get total drinks for the selected time range
  double get _totalStandardDrinks {
    return _filteredDrinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  }

  // Get total cost for the selected time range
  double get _totalCost {
    if (!_costTrackingEnabled) return 0;

    return _filteredDrinks.fold(0, (sum, drink) => sum + (drink.cost ?? 0));
  }

  // Get drinks per day average
  double get _averageDrinksPerDay {
    if (_filteredDrinks.isEmpty) return 0;

    // Get number of days with drinks
    final daysWithDrinks = _getDrinkingDays().length;

    // If no days with drinks, return 0
    if (daysWithDrinks == 0) return 0;

    // Return average drinks per active drinking day
    return _totalStandardDrinks / daysWithDrinks;
  }

  // Get average cost per drink
  double get _averageCostPerDrink {
    if (!_costTrackingEnabled) return 0;

    final drinksWithCost = _filteredDrinks.where((drink) => drink.cost != null).toList();
    if (drinksWithCost.isEmpty) return 0;

    final totalCost = drinksWithCost.fold<double>(0.0, (double sum, drink) => sum + (drink.cost ?? 0));
    return totalCost / drinksWithCost.length;
  }

  // Get the most drinks consumed in a single day
  double get _maxDrinksInOneDay {
    if (_filteredDrinks.isEmpty) return 0;

    // Group drinks by day
    final Map<String, double> drinksByDay = {};

    for (final drink in _filteredDrinks) {
      final dateString = DateFormat('yyyy-MM-dd').format(drink.timestamp);
      drinksByDay[dateString] = (drinksByDay[dateString] ?? 0) + drink.standardDrinks;
    }

    if (drinksByDay.isEmpty) return 0;

    return drinksByDay.values.reduce((max, value) => max > value ? max : value);
  }

  // Get the day of week with most drinks
  String get _mostPopularDayOfWeek {
    if (_filteredDrinks.isEmpty) return 'N/A';

    final Map<int, double> drinksByDayOfWeek = {};

    // Initialize days of week with 0 drinks
    for (int i = 1; i <= 7; i++) {
      drinksByDayOfWeek[i] = 0;
    }

    // Sum drinks for each day of week
    for (final drink in _filteredDrinks) {
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

  // Get all days where drinks were consumed
  Map<String, bool> _getDrinkingDays() {
    final Map<String, bool> drinkingDays = {};

    for (final drink in _filteredDrinks) {
      final dateString = DateFormat('yyyy-MM-dd').format(drink.timestamp);
      drinkingDays[dateString] = true;
    }

    return drinkingDays;
  }

  // Get total drinking days
  int get _totalDrinkingDays {
    return _getDrinkingDays().length;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: _loadDrinks,
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _drinks.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.chart_bar_fill,
                  size: 72,
                  color: Color(0xFF555555),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No drinks logged yet",
                  style: TextStyle(
                    color: Color(0xFF888888),
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
                // Time range selector
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Range',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoSlidingSegmentedControl<TimeRange>(
                        backgroundColor: _segmentedControlColor,
                        thumbColor: const Color(0xFF444444),
                        groupValue: _selectedTimeRange,
                        children: const {
                          TimeRange.week: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            child: Text(
                              'Week',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          TimeRange.month: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            child: Text(
                              'Month',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          TimeRange.threeMonths: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            child: Text(
                              '3 Mo',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          TimeRange.year: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            child: Text(
                              'Year',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          TimeRange.allTime: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            child: Text(
                              'All',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (TimeRange? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimeRange = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Summary Stats Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary 📊',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatTile(
                            emoji: '🥃',
                            title: 'Total',
                            value: _totalStandardDrinks.toStringAsFixed(1),
                          ),
                          _StatTile(
                            emoji: '📆',
                            title: 'Days',
                            value: _totalDrinkingDays.toString(),
                          ),
                          _StatTile(
                            emoji: '📊',
                            title: 'Avg/Day',
                            value: _averageDrinksPerDay.toStringAsFixed(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatTile(
                            emoji: '🔝',
                            title: 'Max Day',
                            value: _maxDrinksInOneDay.toStringAsFixed(1),
                          ),
                          _StatTile(
                            emoji: '📅',
                            title: 'Popular Day',
                            value: _mostPopularDayOfWeek,
                            isTextValue: true,
                          ),
                          _StatTile(
                            emoji: '🔠',
                            title: 'Fav Drink',
                            value: _drinkCountByType.isEmpty
                                ? 'N/A'
                                : Drink.getEmojiForType(
                                _drinkCountByType.entries
                                    .reduce((a, b) =>
                                a.value > b.value ? a : b)
                                    .key),
                            isTextValue: true,
                          ),
                        ],
                      ),

                      // Cost summary (conditional)
                      if (_costTrackingEnabled) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF333333)),
                        const SizedBox(height: 16),
                        const Text(
                          'Cost Summary 💰',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatTile(
                              emoji: '💵',
                              title: 'Total',
                              value: '$_currencySymbol${_totalCost.toStringAsFixed(2)}',
                            ),
                            _StatTile(
                              emoji: '🍹',
                              title: 'Avg/Drink',
                              value: '$_currencySymbol${_averageCostPerDrink.toStringAsFixed(2)}',
                            ),
                            _StatTile(
                              emoji: '📊',
                              title: 'Avg/Day',
                              value: _totalDrinkingDays > 0
                                  ? '$_currencySymbol${(_totalCost / _totalDrinkingDays).toStringAsFixed(2)}'
                                  : '$_currencySymbol 0.00',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Consumption Chart Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getChartTitle('Drinks'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildChart(_chartData),
                      ),
                    ],
                  ),
                ),

                // Cost Chart Card (conditional)
                if (_costTrackingEnabled && _costChartData.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _cardBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getChartTitle('Spending'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: _buildChart(_costChartData, prefix: _currencySymbol),
                        ),
                      ],
                    ),
                  ),

                // Drink Types Distribution
                if (_standardDrinksByType.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _cardBorderColor,
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
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._standardDrinksByType.entries
                            .toList()
                            .map((entry) {
                          final type = entry.key;
                          final standardDrinks = entry.value;
                          final percentage = standardDrinks /
                              _totalStandardDrinks *
                              100;

                          // Get cost for this drink type if available
                          final cost = _costsByType[type];
                          final hasCost = _costTrackingEnabled && cost != null;

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
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${standardDrinks.toStringAsFixed(1)} (${percentage.toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        color: Drink.getColorForType(type),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasCost) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• $_currencySymbol${cost!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: const Color(0xFF333333),
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

                // Tips Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Healthy Drinking Tips 💡',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.info_circle,
                              color: _chartBarColor,
                            ),
                            onPressed: _showHealthInfoAlert,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildHealthTips(),
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

  Widget _buildChart(Map<String, double> chartData, {String prefix = ''}) {
    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'No data for selected time range',
          style: TextStyle(
            color: Color(0xFF888888),
          ),
        ),
      );
    }

    final maxValue = chartData.values.isEmpty ? 1.0 :
    (chartData.values.reduce((a, b) => a > b ? a : b) + 1);

    // Get chart labels in proper order
    List<String> sortedLabels;
    switch (_selectedTimeRange) {
      case TimeRange.week:
      // Order by days of week (Mon-Sun)
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        sortedLabels = days.where((day) => chartData.containsKey(day)).toList();
        break;
      case TimeRange.month:
      // Order by week number
        sortedLabels = chartData.keys.toList()
          ..sort((a, b) {
            final aNum = int.tryParse(a.split(' ')[1]) ?? 0;
            final bNum = int.tryParse(b.split(' ')[1]) ?? 0;
            return aNum.compareTo(bNum);
          });
        break;
      case TimeRange.threeMonths:
      // Order by date (already sorted in chartData)
        sortedLabels = chartData.keys.toList();
        break;
      case TimeRange.year:
      case TimeRange.allTime:
      // Order months chronologically
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        sortedLabels = months.where((month) => chartData.containsKey(month)).toList();
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sortedLabels.map((label) {
        final value = chartData[label] ?? 0;
        final percentage = value / maxValue;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label
                Text(
                  value > 0 ? '$prefix${value.toStringAsFixed(prefix.isNotEmpty ? 2 : 1)}' : '',
                  style: TextStyle(
                    fontSize: 9,
                    color: value > 0 ? _chartBarColor : Colors.transparent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                Container(
                  height: 150 * percentage,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: value > 0 ? _chartBarColor : _chartInactiveColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Tooltip(
                  message: label,
                  child: Text(
                    _formatLabel(label),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatLabel(String label) {
    // For 3-month view with MM/dd format, shorten to just the day
    if (_selectedTimeRange == TimeRange.threeMonths && label.contains('/')) {
      return label.split('/')[1]; // Just show the day
    }

    return label;
  }

  String _getChartTitle(String metric) {
    String timeRange;
    switch (_selectedTimeRange) {
      case TimeRange.week:
        timeRange = 'Past 7 Days';
        break;
      case TimeRange.month:
        timeRange = 'Past Month (Weekly)';
        break;
      case TimeRange.threeMonths:
        timeRange = 'Past 3 Months (Weekly)';
        break;
      case TimeRange.year:
        timeRange = 'Past Year (Monthly)';
        break;
      case TimeRange.allTime:
        timeRange = 'All Time (Monthly)';
        break;
    }

    final emoji = metric == 'Drinks' ? '📈' : '💰';
    return '$metric by $timeRange $emoji';
  }

  Widget _buildHealthTips() {
    final averageDrinksPerDay = _averageDrinksPerDay;
    final maxDrinksInOneDay = _maxDrinksInOneDay;

    String tip;
    Color tipColor;

    if (averageDrinksPerDay <= 1.0 && maxDrinksInOneDay <= 2.0) {
      tip = "You're drinking within low-risk guidelines. Great job! 👍";
      tipColor = const Color(0xFF4CD964); // iOS green
    } else if (averageDrinksPerDay <= 2.0 && maxDrinksInOneDay <= 4.0) {
      tip = "Your drinking is moderate. Try alcohol-free days during your week. 🔄";
      tipColor = const Color(0xFFFFCC00); // iOS yellow
    } else {
      tip = "Consider reducing your alcohol intake for better health. 🚨";
      tipColor = const Color(0xFFFF3B30); // iOS red
    }

    // Add cost-saving tip if cost tracking is enabled
    if (_costTrackingEnabled && _totalCost > 0) {
      final monthlyCost = _totalCost * 30 / _getDrinkingDays().length;
      if (monthlyCost > 200) {
        tip += " You could save around $_currencySymbol${(monthlyCost * 0.3).toStringAsFixed(2)} per month by reducing your drinking by 30%.";
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.lightbulb_fill,
            color: tipColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: tipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthInfoAlert() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Drinking Guidelines'),
        content: const Column(
          children: [
            SizedBox(height: 12),
            Text(
              'Low-risk drinking guidelines recommend:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• No more than 2 standard drinks per day'),
            Text('• No more than 10 standard drinks per week'),
            Text('• Several alcohol-free days per week'),
            SizedBox(height: 12),
            Text(
              'Remember that these are guidelines only. The safest option is to not drink alcohol at all.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final bool isTextValue;

  const _StatTile({
    required this.emoji,
    required this.title,
    required this.value,
    this.isTextValue = false,
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
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTextValue ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF007AFF), // iOS blue
            ),
          ),
        ],
      ),
    );
  }
}