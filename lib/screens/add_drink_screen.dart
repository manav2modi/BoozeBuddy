// lib/screens/add_drink_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/custom_drinks_service.dart';
import './custom_drinks_screen.dart';

class AddDrinkScreen extends StatefulWidget {
  final DateTime selectedDate;

  AddDrinkScreen({
    Key? key,
    DateTime? selectedDate,
  }) : this.selectedDate = selectedDate ?? DateTime.now(),
        super(key: key);

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();
  final _locationController = TextEditingController();

  late TabController _tabController;
  DrinkType _selectedType = DrinkType.beer;
  CustomDrink? _selectedCustomDrink;
  List<CustomDrink> _customDrinks = [];
  double _standardDrinks = 1.0;
  late DateTime _selectedDate;
  bool _isSaving = false;
  bool _showCostField = false;
  bool _loadingCustomDrinks = true;
  int _currentTabIndex = 0;

  // Colors for dark theme
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _textFieldColor = Color(0xFF2A2A2A);
  static const Color _textSecondaryColor = Color(0xFF888888);
  static const Color _accentColor = Color(0xFF007AFF); // iOS blue

  final Map<DrinkType, Map<String, dynamic>> _drinkTypesInfo = {
    DrinkType.beer: {
      'name': 'Beer',
      'emoji': '🍺',
      'defaultStandardDrinks': 1.0,
    },
    DrinkType.wine: {
      'name': 'Wine',
      'emoji': '🍷',
      'defaultStandardDrinks': 1.5,
    },
    DrinkType.cocktail: {
      'name': 'Cocktail',
      'emoji': '🍹',
      'defaultStandardDrinks': 2.0,
    },
    DrinkType.shot: {
      'name': 'Shot',
      'emoji': '🥃',
      'defaultStandardDrinks': 1.0,
    },
    DrinkType.other: {
      'name': 'Other',
      'emoji': '🍸',
      'defaultStandardDrinks': 1.0,
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    _selectedDate = widget.selectedDate;

    // Set the default standard drinks based on the selected type
    _standardDrinks = _drinkTypesInfo[_selectedType]!['defaultStandardDrinks'];

    // Load cost tracking setting
    _loadCostTrackingSetting();
    // Load custom drinks
    _loadCustomDrinks();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;

        if (_currentTabIndex == 0) {
          // Built-in drinks tab
          _selectedType = DrinkType.beer;
          _selectedCustomDrink = null;
          _standardDrinks = _drinkTypesInfo[_selectedType]!['defaultStandardDrinks'];
        } else if (_currentTabIndex == 1 && _customDrinks.isNotEmpty) {
          // Custom drinks tab - select the first custom drink
          _selectedType = DrinkType.custom;
          _selectedCustomDrink = _customDrinks[0];
          _standardDrinks = _selectedCustomDrink!.defaultStandardDrinks;
        }
      });
    }
  }

  Future<void> _loadCostTrackingSetting() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    setState(() {
      _showCostField = costTrackingEnabled;
    });
  }

  Future<void> _loadCustomDrinks() async {
    setState(() {
      _loadingCustomDrinks = true;
    });

    try {
      final customDrinks = await _customDrinksService.getCustomDrinks();
      setState(() {
        _customDrinks = customDrinks;
        _loadingCustomDrinks = false;
      });
    } catch (e) {
      print('Error loading custom drinks: $e');
      setState(() {
        _customDrinks = [];
        _loadingCustomDrinks = false;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _costController.dispose();
    _locationController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) {
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
                      child: const Text('Cancel',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
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
                    primaryColor: Color(0xFF007AFF),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    maximumDate: DateTime.now(),
                    minimumDate: DateTime.now().subtract(const Duration(days: 30)),
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
      },
    );
  }

  void _updateDrinkType(DrinkType type) {
    setState(() {
      _selectedType = type;
      _selectedCustomDrink = null; // Reset selected custom drink
      _standardDrinks = _drinkTypesInfo[type]!['defaultStandardDrinks'];
    });
  }

  void _updateCustomDrink(CustomDrink customDrink) {
    setState(() {
      _selectedType = DrinkType.custom;
      _selectedCustomDrink = customDrink;
      _standardDrinks = customDrink.defaultStandardDrinks;
    });
  }

  Future<void> _navigateToCustomDrinksScreen() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const CustomDrinksScreen(),
      ),
    );

    // Reload custom drinks after returning
    _loadCustomDrinks();
  }

  Future<void> _saveDrink() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Parse cost if enabled and entered
      double? cost;
      if (_showCostField && _costController.text.isNotEmpty) {
        cost = double.tryParse(_costController.text);
        if (cost == null) {
          _showInvalidCostError();
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      final newDrink = Drink(
        id: const Uuid().v4(),
        type: _selectedType,
        standardDrinks: _standardDrinks,
        timestamp: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        cost: cost,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        customDrinkId: _selectedCustomDrink?.id, // Include reference to custom drink
      );

      final saved = await _storageService.saveDrink(newDrink);

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        if (saved) {
          Navigator.of(context).pop(true);
        } else {
          _showSaveError();
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showSaveError();
    }
  }

  void _showSaveError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: const Text('Failed to save drink. Please try again.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showInvalidCostError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Invalid Cost'),
        content: const Text('Please enter a valid number for the cost.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String get _getAppBarTitle {
    if (_selectedType == DrinkType.custom && _selectedCustomDrink != null) {
      return 'Add ${_selectedCustomDrink!.name} ${_selectedCustomDrink!.emoji}';
    } else {
      return 'Add ${_drinkTypesInfo[_selectedType]!['name']} ${_drinkTypesInfo[_selectedType]!['emoji']}';
    }
  }

  Color get _getSelectedColor {
    if (_selectedType == DrinkType.custom && _selectedCustomDrink != null) {
      return _selectedCustomDrink!.color;
    } else {
      return Drink.getColorForType(_selectedType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = _getSelectedColor;

    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: _cardColor,
        border: const Border(
          bottom: BorderSide(
            color: _cardBorderColor,
            width: 0.5,
          ),
        ),
        middle: Text(_getAppBarTitle,
          style: const TextStyle(
            decoration: TextDecoration.none,
          ),
        ),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Changes for the Drink Type Section
// Replace the existing Drink Type container with this improved version

// Drink Type Tab Selector with improved spacing and sizing
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          const Text(
                            'Drink Type',
                            style: TextStyle(
                              fontSize: 18, // Adjusted font size
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          if (_currentTabIndex == 1) // Only show when custom drinks tab is selected
                            GestureDetector(
                              onTap: _navigateToCustomDrinksScreen,
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.pencil,
                                    size: 16,
                                    color: _accentColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _accentColor,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8), // Added padding
                      child: CupertinoSlidingSegmentedControl<int>(
                        backgroundColor: const Color(0xFF333333),
                        thumbColor: const Color(0xFF444444),
                        groupValue: _currentTabIndex,
                        children: const {
                          0: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                            child: Text(
                              'Default Drinks',
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.none,
                                fontSize: 15, // Adjusted font size
                              ),
                            ),
                          ),
                          1: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                            child: Text(
                              'Custom Drinks',
                              style: TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.none,
                                fontSize: 15, // Adjusted font size
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              _tabController.animateTo(value);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12), // Adjusted spacing
                    SizedBox(
                      height: 120, // Reduced height to match screenshots
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Default Drinks Tab with improved sizing
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: _drinkTypesInfo.entries.map((entry) {
                                final type = entry.key;
                                final info = entry.value;
                                final color = Drink.getColorForType(type);

                                final bool isSelected = _selectedType == type && _selectedCustomDrink == null;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4), // Adjusted padding
                                  child: GestureDetector(
                                    onTap: () => _updateDrinkType(type),
                                    child: Container(
                                      width: 85, // Fixed width to make all options the same size
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color.withOpacity(0.15)
                                            : const Color(0xFF333333),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? color
                                              : const Color(0xFF444444),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            info['emoji'],
                                            style: const TextStyle(
                                              fontSize: 28, // Adjusted font size
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            info['name'],
                                            style: TextStyle(
                                              fontSize: 15, // Adjusted font size
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? color
                                                  : Colors.white,
                                              decoration: TextDecoration.none,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Custom Drinks Tab with improved empty state styling
                          _loadingCustomDrinks
                              ? const Center(child: CupertinoActivityIndicator())
                              : _customDrinks.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "No custom drinks yet",
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 22, // Larger font size for empty state
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: const Text(
                                    "Create Your First Custom Drink",
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onPressed: _navigateToCustomDrinksScreen,
                                ),
                              ],
                            ),
                          )
                              : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: _customDrinks.map((customDrink) {
                                final bool isSelected = _selectedType == DrinkType.custom &&
                                    _selectedCustomDrink?.id == customDrink.id;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4), // Adjusted padding
                                  child: GestureDetector(
                                    onTap: () => _updateCustomDrink(customDrink),
                                    child: Container(
                                      width: 85, // Fixed width to match default drinks
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? customDrink.color.withOpacity(0.15)
                                            : const Color(0xFF333333),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? customDrink.color
                                              : const Color(0xFF444444),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            customDrink.emoji,
                                            style: const TextStyle(
                                              fontSize: 28, // Adjusted font size
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            customDrink.name,
                                            style: TextStyle(
                                              fontSize: 15, // Adjusted font size
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? customDrink.color
                                                  : Colors.white,
                                              decoration: TextDecoration.none,
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis, // Prevent overflow
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // Additional bottom padding
                  ],
                ),
              ),

// Also update the Standard Drinks section to match the screenshots:
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _cardBorderColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Standard Drinks 🥃',
                        style: TextStyle(
                          fontSize: 18, // Adjusted font size
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How many standard drinks?',
                        style: TextStyle(
                          fontSize: 15, // Adjusted font size
                          color: _textSecondaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            '0.5',
                            style: TextStyle(
                              fontSize: 15, // Adjusted font size
                              color: _textSecondaryColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Expanded(
                            child: CupertinoSlider(
                              value: _standardDrinks,
                              min: 0.5,
                              max: 5.0,
                              divisions: 9,
                              activeColor: selectedColor,
                              onChanged: (value) {
                                setState(() {
                                  _standardDrinks = value;
                                });
                              },
                            ),
                          ),
                          const Text(
                            '5.0',
                            style: TextStyle(
                              fontSize: 15, // Adjusted font size
                              color: _textSecondaryColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _standardDrinks.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 17, // Adjusted font size
                              fontWeight: FontWeight.bold,
                              color: selectedColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

// And update the date section to match the screenshots:
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _cardBorderColor,
                    width: 1,
                  ),
                ),
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: selectedColor,
                          size: 22, // Adjusted size
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 18, // Adjusted font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 15, // Adjusted font size
                                color: _textSecondaryColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: _textSecondaryColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Location Field
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _cardBorderColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location 📍',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Optional: Where did you have this drink?',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: _locationController,
                        placeholder: 'e.g. New York, Bar name, etc.',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF666666),
                          decoration: TextDecoration.none,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Icon(
                            CupertinoIcons.location,
                            color: selectedColor,
                            size: 20,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _textFieldColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        cursorColor: selectedColor,
                        autocorrect: false,
                        enableSuggestions: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Cost (conditionally shown)
              if (_showCostField)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost 💲',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'How much did this drink cost?',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          controller: _costController,
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          placeholder: '0.00',
                          placeholderStyle: const TextStyle(
                            color: Color(0xFF666666),
                            decoration: TextDecoration.none,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _textFieldColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF444444),
                              width: 1,
                            ),
                          ),
                          cursorColor: selectedColor,
                          autocorrect: false,
                          enableSuggestions: false,
                        ),
                      ],
                    ),
                  ),
                ),

              // Note
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _cardBorderColor,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes 📝',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Optional: Add details about your drink',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondaryColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: _noteController,
                        placeholder: 'e.g. Special occasion, brand, with friends...',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF666666),
                          decoration: TextDecoration.none,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 3,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _textFieldColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        cursorColor: selectedColor,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _isSaving ? null : _saveDrink,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedType == DrinkType.custom && _selectedCustomDrink != null
                            ? _selectedCustomDrink!.emoji
                            : _drinkTypesInfo[_selectedType]!['emoji'],
                        style: const TextStyle(
                          fontSize: 20,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Save Drink',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}