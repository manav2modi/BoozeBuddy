// lib/widgets/custom_drinks/custom_drink_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../models/custom_drink.dart';

typedef CustomDrinkSaveCallback = Future<void> Function(
    String name, String emoji, double standardDrinks, Color color, String? id);

void showCustomDrinkDialog({
  required BuildContext context,
  CustomDrink? existingDrink,
  required CustomDrinkSaveCallback onSave,
}) {
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
            return Padding(
              // Wrap with Padding and use MediaQuery to avoid keyboard overlap
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                // Wrap with SingleChildScrollView to make content scrollable when keyboard appears
                child: SingleChildScrollView(
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
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
                                  _showErrorDialog(context, 'Please enter a name for your drink');
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

                                // Call the save callback
                                await onSave(
                                    name,
                                    emoji,
                                    defaultStandardDrinks,
                                    selectedColor,
                                    isEditing ? existingDrink!.id : null
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pop();
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
                          cursorColor: const Color(0xFF007AFF),
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
                          cursorColor: const Color(0xFF007AFF),
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
                ),
              ),
            );
          }
      );
    },
  );
}

void _showErrorDialog(BuildContext context, String message) {
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