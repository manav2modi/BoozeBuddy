// lib/screens/add_drink_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({Key? key}) : super(key: key);

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  DrinkType _selectedType = DrinkType.beer;
  double _standardDrinks = 1.0;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final Map<DrinkType, Map<String, dynamic>> _drinkTypesInfo = {
    DrinkType.beer: {
      'name': 'Beer',
      'emoji': '🍺',
      'defaultStandardDrinks': 1.0,
      'color': Colors.amber,
    },
    DrinkType.wine: {
      'name': 'Wine',
      'emoji': '🍷',
      'defaultStandardDrinks': 1.5,
      'color': Colors.redAccent,
    },
    DrinkType.cocktail: {
      'name': 'Cocktail',
      'emoji': '🍹',
      'defaultStandardDrinks': 2.0,
      'color': Colors.pinkAccent,
    },
    DrinkType.shot: {
      'name': 'Shot',
      'emoji': '🥃',
      'defaultStandardDrinks': 1.0,
      'color': Colors.deepOrangeAccent,
    },
    DrinkType.other: {
      'name': 'Other',
      'emoji': '🍸',
      'defaultStandardDrinks': 1.0,
      'color': Colors.purpleAccent,
    },
  };

  @override
  void initState() {
    super.initState();
    // Set the default standard drinks based on the selected type
    _standardDrinks = _drinkTypesInfo[_selectedType]!['defaultStandardDrinks'];
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Drink.getColorForType(_selectedType),
              onPrimary: Colors.black,
              surface: const Color(0xFF2C2C2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateDrinkType(DrinkType type) {
    setState(() {
      _selectedType = type;
      _standardDrinks = _drinkTypesInfo[type]!['defaultStandardDrinks'];
    });
  }

  Future<void> _saveDrink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final newDrink = Drink(
        id: const Uuid().v4(),
        type: _selectedType,
        standardDrinks: _standardDrinks,
        timestamp: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      await _storageService.saveDrink(newDrink);

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = _drinkTypesInfo[_selectedType]!['color'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Drink ${_drinkTypesInfo[_selectedType]!['emoji']}',
        ),
        backgroundColor: selectedColor.withOpacity(0.8),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Drink Type Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drink Type',
                      style: Theme.of(context).textTheme.titleLarge,
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
                            child: InkWell(
                              onTap: () => _updateDrinkType(type),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? info['color']
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? info['color']
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
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
                                            ? Colors.white
                                            : Colors.white70,
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

            const SizedBox(height: 16),

            // Standard Drinks
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standard Drinks 🥃',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How many standard drinks?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: _standardDrinks,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      label: _standardDrinks.toStringAsFixed(1),
                      activeColor: selectedColor,
                      inactiveColor: selectedColor.withOpacity(0.3),
                      onChanged: (value) {
                        setState(() {
                          _standardDrinks = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.5',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _standardDrinks.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            color: selectedColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '5.0',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: selectedColor,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes 📝',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optional: Add details about your drink',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g. Special occasion, brand, with friends...',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: selectedColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDrink,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _drinkTypesInfo[_selectedType]!['emoji'],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Drink',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}