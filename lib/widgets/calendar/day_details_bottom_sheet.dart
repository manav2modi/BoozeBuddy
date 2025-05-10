// lib/widgets/calendar/day_details_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/drink.dart';
import '../../utils/theme.dart';
import '../common/fun_card.dart';

class DayDetailsBottomSheet extends StatelessWidget {
  final DateTime selectedDay;
  final List<Drink> drinks;
  final double totalDrinks;
  final Map<String, dynamic> customDrinksMap;
  final VoidCallback onAddDrink;
  final Function(String) onDeleteDrink;

  const DayDetailsBottomSheet({
    Key? key,
    required this.selectedDay,
    required this.drinks,
    required this.totalDrinks,
    required this.customDrinksMap,
    required this.onAddDrink,
    required this.onDeleteDrink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(selectedDay);
    final isToday = DateTime.now().year == selectedDay.year &&
        DateTime.now().month == selectedDay.month &&
        DateTime.now().day == selectedDay.day;

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
                Expanded(
                  child: _buildDrinkSummary(totalDrinks, isToday),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onAddDrink,
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

          // Drinks list
          Expanded(
            child: drinks.isEmpty
                ? _buildEmptyState(isToday)
                : _buildDrinksList(context),
          ),
        ],
      ),
    );
  }

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

  Widget _buildDrinkSummary(double totalDrinks, bool isToday) {
    if (totalDrinks == 0) {
      return Text(
        isToday ? "No drinks logged yet today" : "No drinks on this day",
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 15,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey[400], fontSize: 15),
        children: [
          TextSpan(text: 'Total: '),
          TextSpan(
            text: '${totalDrinks.toStringAsFixed(1)} standard drinks',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isToday) {
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

  Widget _buildDrinksList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: drinks.length,
      itemBuilder: (context, index) {
        final drink = drinks[index];
        return _buildDrinkCard(context, drink);
      },
    );
  }

  Widget _buildDrinkCard(BuildContext context, Drink drink) {
    final String typeString = _getTypeStringForDrink(drink);
    final String emoji = _getEmojiForDrink(drink);
    final Color color = _getColorForDrink(drink);
    final timeString = DateFormat('h:mm a').format(drink.timestamp);

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
        onDeleteDrink(drink.id);
      },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FunCard(
          padding: EdgeInsets.zero,
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
                            if (drink.cost != null) ...[
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
                                '\$${drink.cost!.toStringAsFixed(2)}',
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
                        if (drink.location != null && drink.location!.isNotEmpty) ...[
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
              ),
            ),
          ),
        ),
      ),
    );
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
      final customDrink = customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        return customDrink.emoji;
      }
    }

    return Drink.getEmojiForType(drink.type);
  }

  Color _getColorForDrink(Drink drink) {
    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      final customDrink = customDrinksMap[drink.customDrinkId];
      if (customDrink != null) {
        return customDrink.color;
      }
    }

    return Drink.getColorForType(drink.type);
  }

  String _getTypeStringForDrink(Drink drink) {
    if (drink.type == DrinkType.custom && drink.customDrinkId != null) {
      final customDrink = customDrinksMap[drink.customDrinkId];
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
}