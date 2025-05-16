// lib/screens/add_drink_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sip_track/models/favorite_drink.dart';
import 'package:sip_track/services/favorite_drink_service.dart';
import 'package:sip_track/utils/theme.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/custom_drinks_service.dart';
import './custom_drinks_screen.dart';
import '../widgets/add_drink/drink_type_selector.dart';
import '../widgets/add_drink/standard_drinks_slider.dart';
import '../widgets/add_drink/date_time_selector.dart';
import '../widgets/add_drink/drink_details_form.dart';

// Update the AddDrinkScreen class in add_drink_screen.dart

class AddDrinkScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Drink? drinkToEdit; // Add this parameter

  AddDrinkScreen({
    Key? key,
    DateTime? selectedDate,
    this.drinkToEdit, // Add this parameter
  }) : this.selectedDate = selectedDate ?? DateTime.now(),
        super(key: key);

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> with SingleTickerProviderStateMixin {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  final FavoriteDrinkService _favoriteDrinkService = FavoriteDrinkService();
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
  bool _isLoading = true;
  int _currentTabIndex = 0;
  List<FavoriteDrink> _favoriteDrinks = [];
  bool _loadingFavorites = true;
  bool _includeTime = false;
  bool _isEditing = false; // Add this flag
  int _drinkCount = 1;
  bool _editingFavorites = false;

  // Colors for dark theme
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
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
      'defaultStandardDrinks': 1.0,
    },
    DrinkType.cocktail: {
      'name': 'Cocktail',
      'emoji': '🍹',
      'defaultStandardDrinks': 1.0,
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
    _isEditing = widget.drinkToEdit != null; // Set editing flag

    // If editing, populate fields with existing drink data
    if (_isEditing) {
      final drink = widget.drinkToEdit!;
      _selectedType = drink.type;
      _standardDrinks = drink.standardDrinks;
      _selectedDate = drink.timestamp;

      if (drink.note != null) {
        _noteController.text = drink.note!;
      }

      if (drink.location != null) {
        _locationController.text = drink.location!;
      }

      if (drink.cost != null) {
        _costController.text = drink.cost!.toString();
      }

      // For custom drinks, we'll need to load the specific custom drink
      if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
        _currentTabIndex = 1;
        _tabController.animateTo(1);
      }
    } else {
      // Set the default standard drinks based on the selected type
      _standardDrinks = _drinkTypesInfo[_selectedType]!['defaultStandardDrinks'];
    }

    // Load cost tracking setting
    _loadCostTrackingSetting();
    _loadFavoriteDrinks();
    // Load custom drinks
    _loadCustomDrinks();
  }

  Future<void> _loadFavoriteDrinks() async {
    setState(() {
      _loadingFavorites = true;
      _isLoading = true; // Set loading state
    });

    try {
      final favorites = await _favoriteDrinkService.getFavoriteDrinks();

      setState(() {
        _favoriteDrinks = favorites;
        _loadingFavorites = false;
        _isLoading = _loadingCustomDrinks; // Only completely loaded when both are done
      });
    } catch (e) {
      print('Error loading favorite drinks: $e');
      setState(() {
        _favoriteDrinks = [];
        _loadingFavorites = false;
        _isLoading = _loadingCustomDrinks; // Only completely loaded when both are done
      });
    }
  }

  void _updateDrinkCount(int value) {
    setState(() {
      _drinkCount = value;
    });
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
      _isLoading = true; // Set loading state
    });

    try {
      final customDrinks = await _customDrinksService.getCustomDrinks();
      setState(() {
        _customDrinks = customDrinks;
        _loadingCustomDrinks = false;
        _isLoading = _loadingFavorites; // Only completely loaded when both are done

        // If editing a custom drink, select it
        if (_isEditing && widget.drinkToEdit!.type == DrinkType.custom &&
            widget.drinkToEdit!.customDrinkId != null) {
          // Find the custom drink by ID
          _selectedCustomDrink = _customDrinks.firstWhere(
                (drink) => drink.id == widget.drinkToEdit!.customDrinkId,
            orElse: () => null as CustomDrink,
          );
        }
      });
    } catch (e) {
      print('Error loading custom drinks: $e');
      setState(() {
        _customDrinks = [];
        _loadingCustomDrinks = false;
        _isLoading = _loadingFavorites; // Only completely loaded when both are done
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

  void _updateStandardDrinks(double value) {
    setState(() {
      _standardDrinks = value;
    });
  }

  // Add this to AddDrinkScreen as a new method
  Widget _buildFavoritesSection() {
    if (_favoriteDrinks.isEmpty) {
      return const SizedBox.shrink(); // No favorites
    }

    return Container(
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Spacer(),
                // Optional: Add an edit mode toggle
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    _editingFavorites ? CupertinoIcons.checkmark_circle : CupertinoIcons.pen,
                    color: AppTheme.secondaryColor,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _editingFavorites = !_editingFavorites;
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120, // Make a bit taller to fit more content
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _favoriteDrinks.length,
              itemBuilder: (context, index) {
                final favorite = _favoriteDrinks[index];

                // Create a clearer display name
                String displayName = favorite.name;

                return Stack(
                  children: [
                    // The favorite drink item
                    GestureDetector(
                      onTap: () => _selectFavoriteDrink(favorite),
                      child: Container(
                        width: 85, // Slightly wider
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Emoji
                            Text(
                              favorite.emoji,
                              style: const TextStyle(
                                fontSize: 24,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Name
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),

                            // Standard Drinks with Star
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: favorite.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: favorite.color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.star_fill,
                                    color: AppTheme.secondaryColor,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    favorite.standardDrinks.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: favorite.color,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Optional: Location hint if available
                            if (favorite.location != null && favorite.location!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.location,
                                      color: Colors.grey[400],
                                      size: 8,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        favorite.location!,
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey[400],
                                          decoration: TextDecoration.none,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Delete button overlay (conditionally shown)
                    if (_editingFavorites)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeFavorite(favorite.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.minus,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8.0,),
        ],
      ),
    );
  }

  void _removeFavorite(String id) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text('Are you sure you want to remove this drink from favorites?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await _favoriteDrinkService.removeFavoriteDrink(id);
      if (success) {
        _loadFavoriteDrinks();

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorite removed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

// Method to select a favorite drink
  void _selectFavoriteDrink(FavoriteDrink favorite) {
    setState(() {
      _selectedType = favorite.type;
      _standardDrinks = favorite.standardDrinks;

      if (favorite.type == DrinkType.custom && favorite.customDrinkId != null) {
        _currentTabIndex = 1; // Switch to custom drinks tab
        _tabController.animateTo(1);

        // Find and select the custom drink
        final customDrink = _customDrinks.firstWhere(
              (drink) => drink.id == favorite.customDrinkId,
          orElse: () => null as CustomDrink, // For compilation
        );

        if (customDrink != null) {
          _selectedCustomDrink = customDrink;
        }
      }

      // Pre-fill optional fields if they exist
      if (favorite.note != null) {
        _noteController.text = favorite.note!;
      }

      if (favorite.location != null) {
        _locationController.text = favorite.location!;
      }

      if (favorite.cost != null) {
        _costController.text = favorite.cost!.toString();
      }
    });

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${favorite.name} from favorites'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
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

      bool allSaved = true;

      if (_isEditing) {
        // Update existing drink (don't handle multiple drinks for editing)
        final drinkToSave = Drink(
          id: widget.drinkToEdit!.id, // Keep the same ID
          type: _selectedType,
          standardDrinks: _standardDrinks,
          timestamp: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          cost: cost,
          location: _locationController.text.isEmpty ? null : _locationController.text,
          customDrinkId: _selectedCustomDrink?.id, // Include reference to custom drink
        );

        // Call update method instead of save
        allSaved = await _storageService.updateDrink(drinkToSave);
      } else {
        // Create new drinks - one for each count in the drink counter
        for (int i = 0; i < _drinkCount; i++) {
          final drinkToSave = Drink(
            id: const Uuid().v4(), // Generate unique ID for each
            type: _selectedType,
            standardDrinks: _standardDrinks,
            timestamp: _selectedDate,
            note: _noteController.text.isEmpty ? null : _noteController.text,
            cost: cost,
            location: _locationController.text.isEmpty ? null : _locationController.text,
            customDrinkId: _selectedCustomDrink?.id, // Include reference to custom drink
          );

          final saved = await _storageService.saveDrink(drinkToSave);
          if (!saved) {
            allSaved = false;
            break; // Stop saving if one fails
          }
        }
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        if (allSaved) {
          // Show a success message with the count if multiple drinks
          String message = _isEditing
              ? 'Drink updated successfully!'
              : _drinkCount > 1
              ? '$_drinkCount drinks added successfully!'
              : 'Drink added successfully!';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: _getSelectedColor,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pop(true);
        } else {
          _showSaveError();
        }
      }
    } catch (e) {
      print('Error saving drinks: $e');
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
    if (_isEditing) {
      if (_selectedType == DrinkType.custom && _selectedCustomDrink != null) {
        return 'Edit ${_selectedCustomDrink!.name} ${_selectedCustomDrink!.emoji}';
      } else {
        return 'Edit ${_drinkTypesInfo[_selectedType]!['name']} ${_drinkTypesInfo[_selectedType]!['emoji']}';
      }
    } else {
      if (_selectedType == DrinkType.custom && _selectedCustomDrink != null) {
        return 'Add ${_selectedCustomDrink!.name} ${_selectedCustomDrink!.emoji}';
      } else {
        return 'Add ${_drinkTypesInfo[_selectedType]!['name']} ${_drinkTypesInfo[_selectedType]!['emoji']}';
      }
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
              if (!_isLoading) _buildFavoritesSection(),
              // Drink Type Selector
              DrinkTypeSelector(
                currentTabIndex: _currentTabIndex,
                tabController: _tabController,
                selectedType: _selectedType,
                selectedCustomDrink: _selectedCustomDrink,
                customDrinks: _customDrinks,
                drinkTypesInfo: _drinkTypesInfo,
                loadingCustomDrinks: _loadingCustomDrinks,
                onDrinkTypeSelected: _updateDrinkType,
                onCustomDrinkSelected: _updateCustomDrink,
                onManageCustomDrinks: _navigateToCustomDrinksScreen,
              ),

              // Standard Drinks Slider
              StandardDrinksSlider(
                standardDrinks: _standardDrinks,
                selectedColor: selectedColor,
                onChanged: _updateStandardDrinks,
                drinkCount: _drinkCount,
                onDrinkCountChanged: _updateDrinkCount,
              ),

              // Date Selector
              DateTimeSelector(
                selectedDate: _selectedDate,
                selectedColor: selectedColor,
                onDateTimeSelected: _updateSelectedDate,
              ),

              // Form Fields
              DrinkDetailsForm(
                locationController: _locationController,
                noteController: _noteController,
                costController: _costController,
                showCostField: _showCostField,
                selectedColor: selectedColor,
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
                      Text(
                        _isEditing
                            ? 'Update Drink'
                            : _drinkCount > 1
                            ? 'Save $_drinkCount Drinks'
                            : 'Save Drink',
                        style: const TextStyle(
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