// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import './add_drink_screen.dart';
import './stats_screen.dart';
import './settings_screen.dart';
import '../widgets/drink_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  List<Drink> _drinks = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;
  bool _costTrackingEnabled = false;

  // Colors for dark theme
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF222222);
  static const Color _accentColor = Color(0xFF007AFF); // iOS blue
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _textSecondaryColor = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _loadSettings();
    _loadDrinks();
  }

  Future<void> _loadSettings() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    setState(() {
      _costTrackingEnabled = costTrackingEnabled;
    });
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
    // iOS style date picker
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            color: const Color(0xFF2C2C2C),
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: const Color(0xFF2C2C2C),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      CupertinoButton(
                        child: const Text('Done'),
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
                      primaryColor: _accentColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: _cardBorderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'BoozeBuddy 🍻',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Image.asset(
                  //   'assets/images/logo.png',
                  //   height: 40,            // adjust to fit your AppBar
                  //   fit: BoxFit.contain,
                  // ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(
                      DateFormat('MMM d').format(_selectedDate),
                      style: const TextStyle(color: _accentColor),
                    ),
                    onPressed: () => _selectDate(context),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.settings,
                      color: _accentColor,
                      size: 24,
                    ),
                    onPressed: _navigateToSettings,
                  ),
                ],
              ),
            ),

            // Stats summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: _cardBorderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (_costTrackingEnabled && _totalCost > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Cost: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondaryColor,
                              ),
                            ),
                            Text(
                              _totalCost.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 14,
                                color: _accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🥃', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          _totalStandardDrinks.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: const Color(0xFF333333),
                thumbColor: const Color(0xFF444444),
                groupValue: _currentTabIndex,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      'Drinks',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text(
                      'Stats',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
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

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Today's Drinks Tab
                  _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _drinks.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.tray,
                          size: 72,
                          color: Color(0xFF555555),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No drinks logged for ${DateFormat('MMM d').format(_selectedDate)}",
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          child: const Text("Add Your First Drink"),
                          onPressed: () => _navigateToAddDrink(),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _drinks.length,
                    separatorBuilder: (context, index) => const Divider(color: _cardBorderColor),
                    itemBuilder: (context, index) {
                      final drink = _drinks[index];
                      return DrinkCard(
                        drink: drink,
                        onDelete: () async {
                          final confirmed = await _showDeleteConfirmation(context);
                          if (confirmed) {
                            await _storageService.deleteDrink(drink.id);
                            _loadDrinks();
                          }
                        },
                      );
                    },
                  ),

                  // Stats Tab
                  if (_currentTabIndex == 1) const StatsScreen() else Container(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
        backgroundColor: _accentColor,
        child: const Icon(CupertinoIcons.add),
        onPressed: _navigateToAddDrink,
      )
          : null,
    );
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
    }
  }
}