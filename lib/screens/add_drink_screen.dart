// lib/screens/add_drink_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';

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

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final StorageService _storageService = StorageService();
  final _noteController = TextEditingController();

  DrinkType _selectedType = DrinkType.beer;
  double _standardDrinks = 1.0;
  late DateTime _selectedDate;
  bool _isSaving = false;

  final Map<DrinkType, Map<String, dynamic>> _drinkTypesInfo = {
    DrinkType.beer: {
      'name': 'Beer',
      'emoji': '🍺',
      'defaultStandardDrinks': 1.0,
      'color': CupertinoColors.systemYellow,
    },
    DrinkType.wine: {
      'name': 'Wine',
      'emoji': '🍷',
      'defaultStandardDrinks': 1.5,
      'color': CupertinoColors.systemRed,
    },
    DrinkType.cocktail: {
      'name': 'Cocktail',
      'emoji': '🍹',
      'defaultStandardDrinks': 2.0,
      'color': CupertinoColors.systemPink,
    },
    DrinkType.shot: {
      'name': 'Shot',
      'emoji': '🥃',
      'defaultStandardDrinks': 1.0,
      'color': CupertinoColors.systemOrange,
    },
    DrinkType.other: {
      'name': 'Other',
      'emoji': '🍸',
      'defaultStandardDrinks': 1.0,
      'color': CupertinoColors.systemPurple,
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    // Set the default standard drinks based on the selected type
    _standardDrinks = _drinkTypesInfo[_selectedType]!['defaultStandardDrinks'];
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 44,
                color: CupertinoColors.systemBackground,
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
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
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
            ],
          ),
        );
      },
    );
  }

  void _updateDrinkType(DrinkType type) {
    setState(() {
      _selectedType = type;
      _standardDrinks = _drinkTypesInfo[type]!['defaultStandardDrinks'];
    });
  }

  Future<void> _saveDrink() async {
    // No need to validate since we're using CupertinoUI components
    // which have built-in validation
    setState(() {
      _isSaving = true;
    });

    try {
      final newDrink = Drink(
        id: const Uuid().v4(),
        type: _selectedType,
        standardDrinks: _standardDrinks,
        timestamp: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
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

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = _drinkTypesInfo[_selectedType]!['color'];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Add ${_drinkTypesInfo[_selectedType]!['name']} ${_drinkTypesInfo[_selectedType]!['emoji']}',
        ),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Drink Type Selection
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Drink Type',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _drinkTypesInfo.entries.map((entry) {
                            final type = entry.key;
                            final info = entry.value;

                            final bool isSelected = _selectedType == type;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _updateDrinkType(type),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? info['color'].withOpacity(0.2)
                                        : CupertinoColors.systemGrey6,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? info['color']
                                          : CupertinoColors.systemGrey5,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        info['emoji'],
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        info['name'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? info['color']
                                              : CupertinoColors.label,
                                        ),
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
              ),

              // Standard Drinks
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How many standard drinks?',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            '0.5',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
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
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
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
                            color: selectedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _standardDrinks.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Date Selection
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5,
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
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey2,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Note
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemGrey5,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Optional: Add details about your drink',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: _noteController,
                        placeholder: 'e.g. Special occasion, brand, with friends...',
                        maxLines: 3,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isSaving ? null : _saveDrink,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _drinkTypesInfo[_selectedType]!['emoji'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Save Drink',
                        style: TextStyle(
                          fontSize: 17,
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
      ),
    );
  }
}