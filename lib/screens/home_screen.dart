// lib/screens/home_screen.dart - Modified to include Calendar View
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sip_track/models/favorite_drink.dart';
import 'package:sip_track/screens/passport_screen.dart';
import 'package:sip_track/services/favorite_drink_service.dart';
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
  final FavoriteDrinkService _favoriteDrinkService = FavoriteDrinkService();

  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Drink> _drinks = [];
  Map<String, CustomDrink> _customDrinksMap = {};
  bool _isLoading = true;
  bool _loadingCustomDrinks = true;
  int _currentTabIndex = 0;
  bool _costTrackingEnabled = false;
  List<FavoriteDrink> _favoriteDrinks = [];
  bool _showFabAnimation = false;

  @override
  void initState() {
    super.initState();
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
    _loadFavoriteDrinks();
    _loadCustomDrinks();

    // Add this to trigger animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showFabAnimation = true;
      });
    });
  }

  // Load favorite drinks
  Future<void> _loadFavoriteDrinks() async {
    try {
      final favorites = await _favoriteDrinkService.getFavoriteDrinks();
      setState(() {
        _favoriteDrinks = favorites;
      });
    } catch (e) {
      print('Error loading favorite drinks: $e');
    }
  }

  // Helper method to check if a drink is favorited
  bool _isDrinkFavorited(Drink drink) {
    return _favoriteDrinks.any((favorite) =>
    favorite.type == drink.type &&
        favorite.customDrinkId == drink.customDrinkId &&
        favorite.standardDrinks == drink.standardDrinks);
  }

  // Get ID of favorite if it exists
  String? _getFavoriteId(Drink drink) {
    final favorite = _favoriteDrinks.firstWhere(
          (favorite) =>
      favorite.type == drink.type &&
          favorite.customDrinkId == drink.customDrinkId &&
          favorite.standardDrinks == drink.standardDrinks,
      orElse: () => null as FavoriteDrink,
    );

    return favorite?.id;
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(Drink drink) async {
    // Check if this exact drink is already a favorite
    FavoriteDrink? existingFavorite;
    String? favoriteId;

    // Look for an exact match including standard drinks amount
    for (var fav in _favoriteDrinks) {
      if (fav.type == drink.type &&
          fav.customDrinkId == drink.customDrinkId &&
          fav.standardDrinks == drink.standardDrinks) {
        existingFavorite = fav;
        favoriteId = fav.id;
        break;
      }
    }

    bool success = false;
    if (existingFavorite != null && favoriteId != null) {
      // This exact drink is already a favorite - remove it
      success = await _favoriteDrinkService.removeFavoriteDrink(favoriteId);

      if (success) {
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${existingFavorite.name} from favorites'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } else {
      // Add as a new favorite
      final favoriteToAdd = await _favoriteDrinkService.createFavoriteFromDrink(drink, _customDrinksMap);
      success = await _favoriteDrinkService.addFavoriteDrink(favoriteToAdd);

      if (success) {
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${favoriteToAdd.name} to favorites'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }

    if (success) {
      _loadFavoriteDrinks(); // Reload the favorites list
    }
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
                  // Today's Drinks Tab with scrollable View Passport header
                  _isLoading || _loadingCustomDrinks
                      ? const Center(child: CupertinoActivityIndicator())
                      : _drinks.isEmpty
                      ? NoDrinksEmptyState(
                    date: _selectedDate,
                    onAddDrink: _navigateToAddDrink,
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _drinks.length + 1, // +1 for the header button
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Scroll-header: View Passport
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GradientButton(
                            text: 'View Passport',
                            emoji: '✈️',
                            onPressed: () =>
                                _navigateToPassport(_selectedDate),
                          ),
                        );
                      }

                      final drink = _drinks[index - 1];
                      return Dismissible(
                        key: Key(drink.id),
                        direction: DismissDirection.endToStart,
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
                          final confirmed =
                          await _showDeleteConfirmation(context);
                          if (confirmed) {
                            await _storageService.deleteDrink(drink.id);
                            setState(() {
                              _drinks
                                  .removeWhere((d) => d.id == drink.id);
                            });
                          }
                          return confirmed;
                        },
                        child: GestureDetector(
                          onTap: () => _navigateToEditDrink(drink),
                          child: DrinkFunCard(
                            accentColor: _getColorForDrink(drink),
                            onLongPress: null,
                            child: _buildDrinkContent(drink),
                          ),
                        ),
                      );
                    },
                  ),

                  // Stats Tab
                  const StatsScreen(),

                  // Calendar Tab
                  const CalendarScreen(),
                ],
              ),

            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.9, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              height: 65, // Larger size for better visibility
              width: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.boozeBuddyGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  splashColor: Colors.white.withOpacity(0.2),
                  onTap: () {
                    // Add haptic feedback
                    HapticFeedback.mediumImpact();
                    _navigateToAddDrink();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main add icon
                      const Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 32,
                      ),

                      // Subtle drink icons around the button for fun
                      Positioned(
                        top: 8,
                        right: 10,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: const Text(
                            '🍺',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: const Text(
                            '🍷',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _navigateToPassport(DateTime date) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PassportScreen(date: date),
      ),
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

    // Check if this drink is a favorite
    final bool isFavorite = _isDrinkFavorited(drink);

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

        // Favorite button - for all drinks
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _toggleFavorite(drink),
          child: Icon(
            isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star,
            color: isFavorite ? AppTheme.secondaryColor : Color(0xFF888888),
            size: 22,
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