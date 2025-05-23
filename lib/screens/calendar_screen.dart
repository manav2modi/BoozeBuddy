// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sip_track/screens/passport_screen.dart';
import 'package:sip_track/widgets/calendar/day_details_bottom_sheet.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/storage_service.dart';
import '../services/custom_drinks_service.dart';
import '../utils/theme.dart';
import '../widgets/common/fun_card.dart';
import 'add_drink_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final StorageService _storageService = StorageService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<Drink>> _drinksMap = {};
  Map<String, CustomDrink> _customDrinksMap = {};
  List<Drink> _selectedDayDrinks = [];

  bool _isLoading = true;
  bool _isLoadingSelectedDay = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load custom drinks for displaying proper names and colors
    await _loadCustomDrinks();

    // Load all drinks to create event markers
    await _loadAllDrinks();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCustomDrinks() async {
    try {
      final customDrinks = await _customDrinksService.getCustomDrinks();

      // Create a map of custom drinks for quick lookup by ID
      Map<String, CustomDrink> customDrinksMap = {};
      for (var drink in customDrinks) {
        customDrinksMap[drink.id] = drink;
      }

      setState(() {
        _customDrinksMap = customDrinksMap;
      });
    } catch (e) {
      print('Error loading custom drinks: $e');
      setState(() {
        _customDrinksMap = {};
      });
    }
  }

  Future<void> _loadAllDrinks() async {
    try {
      // Get all drinks from storage
      final allDrinks = await _storageService.getDrinks();

      // Group drinks by date (ignoring time)
      final Map<DateTime, List<Drink>> drinksMap = {};

      for (final drink in allDrinks) {
        // Create a new DateTime with only year, month, day (no time)
        final date = DateTime(
          drink.timestamp.year,
          drink.timestamp.month,
          drink.timestamp.day,
        );

        if (drinksMap[date] == null) {
          drinksMap[date] = [];
        }

        drinksMap[date]!.add(drink);
      }

      setState(() {
        _drinksMap = drinksMap;
      });
    } catch (e) {
      print('Error loading all drinks: $e');
      setState(() {
        _drinksMap = {};
      });
    }
  }

  Future<List<Drink>> _loadDrinksForDay(DateTime day) async {
    setState(() {
      _isLoadingSelectedDay = true;
    });

    try {
      final drinks = await _storageService.getDrinksForDate(day);

      setState(() {
        _selectedDayDrinks = drinks;
        _isLoadingSelectedDay = false;
      });

      return drinks;
    } catch (e) {
      print('Error loading drinks for selected day: $e');
      setState(() {
        _selectedDayDrinks = [];
        _isLoadingSelectedDay = false;
      });
      return [];
    }
  }

  List<Drink> _getDrinksForDay(DateTime day) {
    // Create a DateTime with only year, month, day (no time)
    final date = DateTime(day.year, day.month, day.day);
    return _drinksMap[date] ?? [];
  }

  // Calculate total standard drinks for a day
  double _getTotalStandardDrinksForDay(DateTime day) {
    final drinks = _getDrinksForDay(day);
    return drinks.fold(0.0, (sum, drink) => sum + drink.standardDrinks);
  }

  // Handle day selection - show bottom sheet with day details
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    _showDayDetailsBottomSheet(selectedDay);
  }

  // Show detailed bottom sheet when a day is tapped
  Future<void> _showDayDetailsBottomSheet(DateTime day) async {
    // First load the drinks for this day
    final drinks = await _loadDrinksForDay(day);
    //final  = drinks.fold(0.0, (sum, drink) => sum + drink.standardDrinks);
    final totalDrinks = drinks.fold<double>(
      0.0,
          (sum, drink) => sum + ((drink.standardDrinks as double?) ?? 0.0),
    );
    if (!mounted) return;

    // Show bottom sheet with day details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailsBottomSheet(
        selectedDay: day,
        drinks: drinks,
        totalDrinks: totalDrinks,
        customDrinksMap: _customDrinksMap, // Make sure you have this map available
        onAddDrink: () => _navigateToAddDrink(day),
        onDeleteDrink: _handleDeleteDrink,
        onViewPassport: _navigateToPassport, // Add this line
      ),
    );
  }

  // Add this method to your _CalendarScreenState class
  Future<void> _navigateToPassport(DateTime date) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PassportScreen(date: date),
      ),
    );
  }

  // Build the bottom sheet content
  Widget _buildDayDetailsBottomSheet(DateTime day, List<Drink> drinks, double totalDrinks) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(day);
    final isToday = DateTime.now().year == day.year &&
        DateTime.now().month == day.month &&
        DateTime.now().day == day.day;

    // Determine status text and color based on drink amount
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (totalDrinks == 0) {
      statusText = isToday ? "No drinks yet today" : "No drinks on this day";
      statusIcon = CupertinoIcons.checkmark_circle;
      statusColor = Colors.green;
    } else if (totalDrinks <= 2.0) {
      statusText = "Light drinking (${totalDrinks.toStringAsFixed(1)} drinks)";
      statusIcon = CupertinoIcons.check_mark_circled;
      statusColor = Colors.green;
    } else if (totalDrinks <= 4.0) {
      statusText = "Moderate drinking (${totalDrinks.toStringAsFixed(1)} drinks)";
      statusIcon = CupertinoIcons.exclamationmark_circle;
      statusColor = AppTheme.secondaryColor;
    } else {
      statusText = "Heavy drinking (${totalDrinks.toStringAsFixed(1)} drinks)";
      statusIcon = CupertinoIcons.exclamationmark_circle_fill;
      statusColor = Colors.red;
    }

    // Calculate the maximum height for the bottom sheet (80% of screen height)
    final height = MediaQuery.of(context).size.height * 0.8;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _buildDrinkStatusBadge(totalDrinks, isToday),
              ],
            ),
          ),

          // Status and add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _navigateToAddDrink(day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.boozeBuddyGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isToday ? "🍹" : "📝",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Drink',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.dividerColor),

          // Drinks list or empty state
          Expanded(
            child: drinks.isEmpty
                ? _buildEmptyBottomSheetState(isToday)
                : _buildDrinksListForBottomSheet(drinks),
          ),
        ],
      ),
    );
  }

  // Status badge for drink amount
  Widget _buildDrinkStatusBadge(double totalDrinks, bool isToday) {
    String label;
    Color color;

    if (totalDrinks == 0) {
      label = 'No Drinks';
      color = Colors.green;
    } else if (totalDrinks <= 2) {
      label = 'Light';
      color = Colors.green;
    } else if (totalDrinks <= 4) {
      label = 'Moderate';
      color = AppTheme.secondaryColor;
    } else {
      label = 'Heavy';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Empty state for bottom sheet
  Widget _buildEmptyBottomSheetState(bool isToday) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isToday ? CupertinoIcons.plus_circle : CupertinoIcons.calendar,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? "No drinks logged yet today"
                : "No drinks logged on this day",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isToday
                ? "Tap the Add Drink button to start tracking"
                : "Add a drink or select another day",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Drinks list for bottom sheet
  Widget _buildDrinksListForBottomSheet(List<Drink> drinks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: drinks.length,
      itemBuilder: (context, index) {
        final drink = drinks[index];

        return Dismissible(
          key: Key(drink.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context);
          },
          onDismissed: (direction) {
            _handleDeleteDrink(drink.id);
            Navigator.pop(context); // Close the sheet after delete
          },
          child: _buildDrinkItem(drink),
        );
      },
    );
  }

  // Individual drink item for the list
  // Update the _buildDrinkItem method in the CalendarScreen class

  Widget _buildDrinkItem(Drink drink) {
    final String emoji = _getEmojiForDrink(drink);
    final Color color = _getColorForDrink(drink);
    final String typeString = _getTypeStringForDrink(drink);
    final timeString = DateFormat('h:mm a').format(drink.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _navigateToEditDrink(drink), // Add edit on tap
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Left part with emoji
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle part with details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeString,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                          if (drink.cost != null) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${drink.cost!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Location row
                      if (drink.location != null && drink.location!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.location,
                              size: 12,
                              color: color.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                drink.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Right part with standard drinks
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🥃',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        drink.standardDrinks.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Add this method to the CalendarScreen class
  Future<void> _navigateToEditDrink(Drink drink) async {
    Navigator.pop(context); // Close the bottom sheet

    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddDrinkScreen(
          selectedDate: drink.timestamp,
          drinkToEdit: drink,
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Reload all data to update calendar markers
    }
  }

  // Determine marker color based on number of standard drinks
  Color _getMarkerColor(double standardDrinks) {
    if (standardDrinks <= 1.0) {
      return Colors.green;
    } else if (standardDrinks <= 3.0) {
      return AppTheme.secondaryColor;
    } else {
      return Colors.red;
    }
  }

  // Navigate to add drink screen
  Future<void> _navigateToAddDrink(DateTime selectedDate) async {
    Navigator.pop(context); // Close the bottom sheet first

    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddDrinkScreen(selectedDate: selectedDate),
      ),
    );

    if (result == true) {
      _loadData(); // Reload all data to update calendar markers
    }
  }

  // Handle delete drink
  Future<void> _handleDeleteDrink(String drinkId) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed) {
      await _storageService.deleteDrink(drinkId);
      _loadData(); // Reload all data to update calendar and list
    }
  }

  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Drink'),
        content: const Text('Are you sure you want to delete this drink?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;
  }

  // Helper methods to get emoji, color, and type string for a drink
  String _getEmojiForDrink(Drink drink) {
    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      final customDrink = _customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        return customDrink.emoji;
      }
    }

    return Drink.getEmojiForType(drink.type);
  }

  Color _getColorForDrink(Drink drink) {
    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      final customDrink = _customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        return customDrink.color;
      }
    }

    return Drink.getColorForType(drink.type);
  }

  String _getTypeStringForDrink(Drink drink) {
    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      final customDrink = _customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        return customDrink.name;
      }
    }

    switch (drink.type) {
      case DrinkType.beer:
        return 'Beer';
      case DrinkType.wine:
        return 'Wine';
      case DrinkType.cocktail:
        return 'Cocktail';
      case DrinkType.shot:
        return 'Shot';
      case DrinkType.other:
        return 'Other';
      case DrinkType.custom:
        return 'Custom Drink';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Calendar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _buildCalendar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    // Calculate calendar height based on format and rows needed
    double calendarHeight;

    switch (_calendarFormat) {
      case CalendarFormat.month:
      // Calculate based on number of rows in current month
        final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
        final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1).weekday % 7; // 0-6 for Sun-Sat
        final rowCount = ((daysInMonth + firstDayOfMonth) / 7).ceil(); // Number of rows needed

        // Add header row and limit max height
        calendarHeight = min(42.0 * rowCount + 60.0, MediaQuery.of(context).size.height * 0.65);
        break;

      case CalendarFormat.twoWeeks:
        calendarHeight = 150.0;
        break;

      case CalendarFormat.week:
        calendarHeight = 100.0;
        break;
    }

    // Ensure focusedDay is not after lastDay (today)
    final DateTime now = DateTime.now();
    final DateTime safeToday = DateTime(now.year, now.month, now.day);
    final DateTime safeFocusedDay = _focusedDay.isAfter(safeToday)
        ? safeToday
        : _focusedDay;

    // Ensure selectedDay is not after lastDay (today)
    final DateTime safeSelectedDay = _selectedDay.isAfter(safeToday)
        ? safeToday
        : _selectedDay;

    return FunCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom header with month title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(CupertinoIcons.chevron_left, color: AppTheme.primaryColor, size: 20),
                  onPressed: () {
                    setState(() {
                      if (_calendarFormat == CalendarFormat.month) {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                      } else {
                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day - 7);
                      }
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _calendarFormat == CalendarFormat.month
                        ? DateFormat('MMMM yyyy').format(safeFocusedDay)
                        : '${DateFormat('MMM d').format(safeFocusedDay)} - '
                        '${DateFormat('MMM d').format(
                      safeFocusedDay.add(Duration(days: _calendarFormat == CalendarFormat.week ? 6 : 13)),
                    )}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(CupertinoIcons.chevron_right, color: AppTheme.primaryColor, size: 20),
                  onPressed: () {
                    // Don't allow navigating past today
                    if (safeFocusedDay.add(const Duration(days: 7)).isAfter(safeToday)) {
                      return;
                    }

                    setState(() {
                      if (_calendarFormat == CalendarFormat.month) {
                        _focusedDay = DateTime(safeFocusedDay.year, safeFocusedDay.month + 1, 1);
                      } else {
                        _focusedDay = DateTime(safeFocusedDay.year, safeFocusedDay.month, safeFocusedDay.day + 7);
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Format selector - more compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(3),
              child: CupertinoSlidingSegmentedControl<CalendarFormat>(
                groupValue: _calendarFormat,
                backgroundColor: Colors.transparent,
                thumbColor: AppTheme.primaryColor.withOpacity(0.2),
                children: {
                  CalendarFormat.month: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('Month'),
                  ),
                  CalendarFormat.twoWeeks: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('2 Weeks'),
                  ),
                  CalendarFormat.week: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text('Week'),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _calendarFormat = value;
                    });
                  }
                },
              ),
            ),
          ),

          // Table calendar with dynamic height
          SizedBox(
            height: calendarHeight,
            child: TableCalendar(
              key: ValueKey('calendar-${_calendarFormat.toString()}-${safeFocusedDay.toString()}'),
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: safeToday,
              focusedDay: safeFocusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 Weeks',
                CalendarFormat.week: 'Week',
              },
              selectedDayPredicate: (day) {
                return isSameDay(safeSelectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                // Only allow selecting days up to today
                if (selectedDay.isAfter(safeToday)) return;
                _onDaySelected(selectedDay, focusedDay);
              },
              onPageChanged: (focusedDay) {
                // Ensure the new focused day isn't after today
                final safeFocused = focusedDay.isAfter(safeToday) ? safeToday : focusedDay;
                setState(() {
                  _focusedDay = safeFocused;
                });
              },
              // Compact sizing for better fit
              rowHeight: 42, // More compact row height
              daysOfWeekHeight: 20, // Smaller days of week header
              headerVisible: false, // We're using our own custom header

              calendarStyle: const CalendarStyle(
                // Customize the calendar appearance
                isTodayHighlighted: true,
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0x33D090E0), // Transparent purple
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                // Text styling
                defaultTextStyle: TextStyle(color: Colors.white, fontSize: 14),
                weekendTextStyle: TextStyle(color: Colors.white70, fontSize: 14),
                selectedTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                todayTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                // Enhanced styling for a cleaner look
                cellMargin: EdgeInsets.all(0),
                cellPadding: EdgeInsets.zero,
              ),

              daysOfWeekStyle: const DaysOfWeekStyle(
                // More compact day of week labels
                weekdayStyle: TextStyle(color: Colors.white70, fontSize: 12),
                weekendStyle: TextStyle(color: Colors.white70, fontSize: 12),
              ),

              // Calendar events (drink markers)
              calendarBuilders: CalendarBuilders(
                // Day of week labels at top of calendar
                dowBuilder: (context, day) {
                  return Center(
                    child: Text(
                      DateFormat.E().format(day).substring(0, 1), // Just first letter (M T W T F S S)
                      style: TextStyle(
                        color: day.weekday >= 6 ? Colors.grey[400] : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );
                },

                // Make empty cells look better
                outsideBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(30),
                    ),
                  );
                },

                // Markers for days with drinks
                markerBuilder: (context, date, events) {
                  final drinks = _getDrinksForDay(date);
                  if (drinks.isEmpty) return null;

                  final standardDrinks = drinks.fold<double>(
                    0.0,
                        (sum, drink) => sum + ((drink.standardDrinks as double?) ?? 0.0),
                  );
                  final markerColor = _getMarkerColor(standardDrinks);

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: markerColor,
                      ),
                      width: 6, // Smaller marker
                      height: 6,
                    ),
                  );
                },

                // Colored background for days with drinks
                defaultBuilder: (context, day, focusedDay) {
                  final drinks = _getDrinksForDay(day);
                  if (drinks.isEmpty) return null;

                  final standardDrinks = drinks.fold<double>(
                    0.0,
                        (sum, drink) => sum + ((drink.standardDrinks as double?) ?? 0.0),
                  );
                  // Adjust intensity based on calendar format
                  final intensity = _calendarFormat == CalendarFormat.month
                      ? (standardDrinks / 15).clamp(0.05, 0.25) // Less intense for month view
                      : (standardDrinks / 10).clamp(0.05, 0.35);
                  final markerColor = _getMarkerColor(standardDrinks);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: markerColor.withOpacity(intensity),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}