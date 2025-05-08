// lib/screens/custom_drinks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/custom_drink.dart';
import '../services/custom_drinks_service.dart';

class CustomDrinksScreen extends StatefulWidget {
  const CustomDrinksScreen({Key? key}) : super(key: key);

  @override
  State<CustomDrinksScreen> createState() => _CustomDrinksScreenState();
}

class _CustomDrinksScreenState extends State<CustomDrinksScreen> {
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  List<CustomDrink> _customDrinks = [];
  bool _isLoading = true;

  // Colors for dark theme
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _accentColor = Color(0xFF007AFF); // iOS blue

  // Predefined colors
  final List<Color> _predefinedColors = [
    const Color(0xFF64B5F6), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF5252), // Red
    const Color(0xFFFF4081), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF009688), // Teal
    const Color(0xFFFFC107), // Amber
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomDrinks();
  }

  Future<void> _loadCustomDrinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customDrinks = await _customDrinksService.getCustomDrinks();
      setState(() {
        _customDrinks = customDrinks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading custom drinks: $e');
      setState(() {
        _customDrinks = [];
        _isLoading = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Custom Drink'),
        content: const Text('Are you sure you want to delete this custom drink? Any drinks logged with this type will remain, but will display as "Custom" without specific details.'),
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

  void _showAddEditCustomDrinkDialog({CustomDrink? existingDrink}) {
    final isEditing = existingDrink != null;
    final nameController = TextEditingController(text: isEditing ? existingDrink.name : '');
    // Always use 1.0 as standard drinks
    const defaultStandardDrinks = 1.0;

    // Default emoji or existing emoji
    String selectedEmoji = isEditing ? existingDrink.emoji : '🍺';
    final emojiController = TextEditingController(text: selectedEmoji);

    Color selectedColor = isEditing ? existingDrink.color : _predefinedColors[0];

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced top padding
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min, // Use min size
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Cancel',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          Text(
                            isEditing ? 'Edit Custom Drink' : 'Add Custom Drink',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Save',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                              ),
                            ),
                            onPressed: () async {
                              // Validate input
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                _showErrorDialog('Please enter a name for your drink');
                                return;
                              }

                              // Get emoji from controller
                              String emoji = emojiController.text;
                              if (emoji.isEmpty) {
                                emoji = '🍺'; // Default emoji if none entered
                              } else {
                                // Take only first character if multiple characters were entered
                                emoji = emoji.characters.first.toString();
                              }

                              bool success;
                              if (isEditing) {
                                // Update existing drink
                                final updatedDrink = CustomDrink(
                                  id: existingDrink.id,
                                  name: name,
                                  emoji: emoji,
                                  defaultStandardDrinks: defaultStandardDrinks, // Always 1.0
                                  color: selectedColor,
                                );
                                success = await _customDrinksService.updateCustomDrink(updatedDrink);
                              } else {
                                // Add new drink
                                success = await _customDrinksService.saveCustomDrink(
                                  name,
                                  emoji,
                                  defaultStandardDrinks, // Always 1.0
                                  selectedColor,
                                );
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                                if (success) {
                                  _loadCustomDrinks();
                                } else {
                                  _showErrorDialog('Failed to save custom drink');
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF333333)),
                      const SizedBox(height: 16),
                      // Drink preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: selectedColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emojiController.text.isEmpty ? '🍺' : emojiController.text.characters.first.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Name field with manual length limiting
                      CupertinoTextField(
                        controller: nameController,
                        placeholder: 'Drink Name (e.g. Vodka Tonic)',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF666666),
                          decoration: TextDecoration.none,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        cursorColor: _accentColor,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(25),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Emoji input field with manual character limiting
                      const Text(
                        'Choose an Emoji',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: emojiController,
                        placeholder: 'Tap to select emoji',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF666666),
                          decoration: TextDecoration.none,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          decoration: TextDecoration.none,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF444444),
                            width: 1,
                          ),
                        ),
                        cursorColor: _accentColor,
                        // Manual character limiting for emoji
                        maxLength: 1,
                        // Let the system choose the keyboard type (which includes emoji)
                        keyboardType: TextInputType.text,
                        onTap: () {
                          // Clear existing text to make it easier to change emoji
                          emojiController.clear();
                        },
                      ),
                      const SizedBox(height: 24),
                      // Color selector
                      const Text(
                        'Choose a Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _predefinedColors.length,
                          itemBuilder: (context, index) {
                            final color = _predefinedColors[index];
                            final isSelected = color.value == selectedColor.value;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
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
    return CupertinoPageScaffold(
      backgroundColor: _backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF222222),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 0.5,
          ),
        ),
        middle: Text('Custom Drinks'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
          children: [
            Expanded(
              child: _customDrinks.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.square_list,
                      size: 72,
                      color: Color(0xFF555555),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No custom drinks yet",
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Add your favorites to track them easily",
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      child: const Text("Create Custom Drink",
                        style: TextStyle(
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () => _showAddEditCustomDrinkDialog(),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _customDrinks.length,
                separatorBuilder: (context, index) =>
                const Divider(color: _cardBorderColor),
                itemBuilder: (context, index) {
                  final customDrink = _customDrinks[index];
                  return _buildCustomDrinkItem(customDrink);
                },
              ),
            ),
            // if (_customDrinks.isNotEmpty)
            //   Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: SizedBox(
            //       width: double.infinity,
            //       child: CupertinoButton(
            //         color: _accentColor,
            //         borderRadius: BorderRadius.circular(10),
            //         onPressed: () => _showAddEditCustomDrinkDialog(),
            //         child: const Text('Add New Custom Drink',
            //           style: TextStyle(
            //             decoration: TextDecoration.none,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrinkItem(CustomDrink customDrink) {
    return GestureDetector(
      onTap: () => _showAddEditCustomDrinkDialog(existingDrink: customDrink),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _cardBorderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left part with emoji
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: customDrink.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: customDrink.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    customDrink.emoji,
                    style: const TextStyle(
                      fontSize: 24,
                      decoration: TextDecoration.none,
                    ),
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
                      customDrink.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showAddEditCustomDrinkDialog(existingDrink: customDrink),
                    child: const Icon(
                      CupertinoIcons.pencil,
                      color: _accentColor,
                      size: 22,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirmation(context);
                      if (confirmed) {
                        final success = await _customDrinksService.deleteCustomDrink(customDrink.id);
                        if (success) {
                          _loadCustomDrinks();
                        } else {
                          _showErrorDialog('Failed to delete custom drink');
                        }
                      }
                    },
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: Color(0xFF888888),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
