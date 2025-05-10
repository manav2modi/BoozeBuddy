// lib/screens/home_screen.dart - Modified to include Calendar View
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/custom_drinks_service.dart';
import './add_drink_screen.dart';
import './stats_screen.dart';
import './calendar_screen.dart'; // Add this import for the new calendar screen
import './settings_screen.dart';
import '../widgets/drink_card.dart';
import '../utils/theme.dart';

// Import our widgets
import '../widgets/common/fun_header.dart';
import '../widgets/common/fun_card.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Drink> _drinks = [];
  Map<String, CustomDrink> _customDrinksMap = {};
  bool _isLoading = true;
  bool _loadingCustomDrinks = true;
  int _currentTabIndex = 0;
  bool _costTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    // Update tab controller to include 3 tabs (Drinks, Calendar, Stats)
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadSettings();
    _loadDrinks();
    _loadCustomDrinks();
  }

  Future<void> _loadSettings() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    setState(() {
      _costTrackingEnabled = costTrackingEnabled;
    });
  }

  Future<void> _navigateToEditDrink(Drink drink) async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddDrinkScreen(
          selectedDate: _selectedDate,
          drinkToEdit: drink,
        ),
      ),
    );

    if (result == true) {
      _loadDrinks();
      // Also reload custom drinks in case any new ones were added
      _loadCustomDrinks();
    }
  }

  Future<void> _loadCustomDrinks() async {
    setState(() {
      _loadingCustomDrinks = true;
    });

    try {
      final customDrinks = await _customDrinksService.getCustomDrinks();

      // Create a map of custom drinks for quick lookup by ID
      Map<String, CustomDrink> customDrinksMap = {};
      for (var drink in customDrinks) {
        customDrinksMap[drink.id] = drink;
      }

      setState(() {
        _customDrinksMap = customDrinksMap;
        _loadingCustomDrinks = false;
      });
    } catch (e) {
      print('Error loading custom drinks: $e');
      setState(() {
        _customDrinksMap = {};
        _loadingCustomDrinks = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drinks = await _storageService.getDrinksForDate(_selectedDate);

      setState(() {
        _drinks = drinks;
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

  double get _totalStandardDrinks {
    return _drinks.fold(0, (sum, drink) => sum + drink.standardDrinks);
  }

  // Calculate total cost for today's drinks
  double get _totalCost {
    if (!_costTrackingEnabled) return 0;
    return _drinks.fold(0, (sum, drink) => sum + (drink.cost ?? 0));
  }

  void _selectDate(BuildContext context) async {
    // Determine if we should show animation based on when the date was selected
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    final isYesterday = _selectedDate.year == DateTime.now().subtract(const Duration(days: 1)).year &&
        _selectedDate.month == DateTime.now().subtract(const Duration(days: 1)).month &&
        _selectedDate.day == DateTime.now().subtract(const Duration(days: 1)).day;

    // Different greeting based on date
    String dateGreeting;
    String dateEmoji;

    if (isToday) {
      dateGreeting = "Viewing today's drinks";
      dateEmoji = "🍻";
    } else if (isYesterday) {
      dateGreeting = "Checking yesterday's drinks";
      dateEmoji = "⏰";
    } else {
      dateGreeting = "Looking at past drinks";
      dateEmoji = "📆";
    }

    // iOS style date picker with fun header
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 360, // Taller for the header
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Column(
              children: [
                // Fun header with greeting
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.secondaryColor.withOpacity(0.3),
                        AppTheme.primaryColor.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        dateEmoji,
                        style: const TextStyle(
                          fontSize: 24,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateGreeting,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 44,
                  color: const Color(0xFF2C2C2C),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        child: const Text('Done',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _loadDrinks();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0, color: Color(0xFF3D3D3D)),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: AppTheme.primaryColor,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: _selectedDate,
                      maximumDate: DateTime.now(),
                      minimumDate: DateTime.now().subtract(const Duration(days: 365)),
                      onDateTimeChanged: (DateTime newDate) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

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

  // Navigate to settings screen
  Future<void> _navigateToSettings() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );

    // Reload settings and drinks when returning from settings
    _loadSettings();
    _loadDrinks();
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _loadDrinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Updated Fun Header
            FunHeader(
              selectedDate: _selectedDate,
              onDateTap: () => _selectDate(context),
              onSettingsTap: _navigateToSettings,
              totalDrinks: _totalStandardDrinks,
              onDateChange: _onDateChanged,
            ),

            // Improved Tab Bar with gradient indicator
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: const Color(0xFF333333),
                  thumbColor: const Color(0xFF444444),
                  groupValue: _currentTabIndex,
                  children: {
                    0: _buildTabItem(
                      icon: CupertinoIcons.list_bullet,
                      text: 'Drinks',
                      isSelected: _currentTabIndex == 0,
                    ),
                    1: _buildTabItem(
                      icon: CupertinoIcons.chart_bar_fill,
                      text: 'Stats',
                      isSelected: _currentTabIndex == 1,
                    ),
                    2: _buildTabItem(
                      icon: CupertinoIcons.calendar,
                      text: 'Calendar',
                      isSelected: _currentTabIndex == 2,
                    ),
                  },
                  onValueChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentTabIndex = newValue;
                        _tabController.animateTo(newValue);
                      });
                    }
                  },
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Today's Drinks Tab with updated UI
                  _isLoading || _loadingCustomDrinks
                      ? const Center(child: CupertinoActivityIndicator())
                      : _drinks.isEmpty
                      ? NoDrinksEmptyState(
                    date: _selectedDate,
                    onAddDrink: _navigateToAddDrink,
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _drinks.length,
                    itemBuilder: (context, index) {
                      final drink = _drinks[index];
                      // Wrap the DrinkFunCard in a Dismissible widget
                      return Dismissible(
                        key: Key(drink.id),
                        direction: DismissDirection.endToStart, // Only allow right-to-left swipe (delete)
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // Show delete confirmation
                          return await _showDeleteConfirmation(context);
                        },
                        onDismissed: (direction) {
                          // Delete the drink
                          _storageService.deleteDrink(drink.id);
                          _loadDrinks();
                        },
                        child: GestureDetector(
                          // Add tap to edit functionality
                          onTap: () => _navigateToEditDrink(drink),
                          child: DrinkFunCard(
                            accentColor: _getColorForDrink(drink),
                            onLongPress: null, // Remove this since we're using swipe to delete
                            child: _buildDrinkContent(drink),
                          ),
                        ),
                      );
                    },
                  ),

                  // Stats Tab
                  const StatsScreen(),

                  // New Calendar Tab
                  const CalendarScreen(),

                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(CupertinoIcons.add),
        onPressed: _navigateToAddDrink,
      )
          : null,
    );
  }

  // Helper to build tab items
  Widget _buildTabItem({
    required IconData icon,
    required String text,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build drink card content
  Widget _buildDrinkContent(Drink drink) {
    final String emoji = _getEmojiForDrink(drink);
    final Color color = _getColorForDrink(drink);
    final String typeString = _getTypeStringForDrink(drink);
    final timeString = DateFormat('h:mm a').format(drink.timestamp);

    // Format cost if available and cost tracking is enabled
    final hasCost = _costTrackingEnabled && drink.cost != null;
    final costString = hasCost ? '\$${drink.cost!.toStringAsFixed(2)}' : null;

    // Check if location is available
    final hasLocation = drink.location != null && drink.location!.isNotEmpty;

    return Row(
      children: [
        // Left part with emoji and drink type
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
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
                  fontSize: 17,
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
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                  if (hasCost) ...[
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      costString!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ],
              ),

              // Location row
              if (hasLocation) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: 14,
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

              if (drink.note != null && drink.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  drink.note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Right part with standard drinks
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
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
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                drink.standardDrinks.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    // For non-custom drinks, or if custom drink wasn't found
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

  // Create a method to navigate to AddDrinkScreen to avoid duplicated code
  Future<void> _navigateToAddDrink() async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddDrinkScreen(selectedDate: _selectedDate),
      ),
    );

    if (result == true) {
      _loadDrinks();
      // Also reload custom drinks in case any new ones were added
      _loadCustomDrinks();
    }
  }
}