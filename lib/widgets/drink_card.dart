// lib/widgets/drink_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/drink.dart';
import '../models/custom_drink.dart';
import '../services/settings_service.dart';
import '../services/custom_drinks_service.dart';

class DrinkCard extends StatefulWidget {
  final Drink drink;
  final VoidCallback onDelete;

  const DrinkCard({
    Key? key,
    required this.drink,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<DrinkCard> {
  final SettingsService _settingsService = SettingsService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  bool _costTrackingEnabled = false;
  String _currencySymbol = "\$";
  CustomDrink? _customDrink;
  bool _loadingCustomDrink = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    // If this is a custom drink, load the custom drink details
    if (widget.drink.type == DrinkType.custom && widget.drink.customDrinkId != null) {
      _loadCustomDrink();
    }
  }

  Future<void> _loadSettings() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    final currencySymbol = await _settingsService.getCurrencySymbol();

    if (mounted) {
      setState(() {
        _costTrackingEnabled = costTrackingEnabled;
        _currencySymbol = currencySymbol;
      });
    }
  }

  Future<void> _loadCustomDrink() async {
    setState(() {
      _loadingCustomDrink = true;
    });

    try {
      if (widget.drink.customDrinkId != null) {
        final customDrink = await _customDrinksService.getCustomDrinkById(widget.drink.customDrinkId!);

        if (mounted) {
          setState(() {
            _customDrink = customDrink;
            _loadingCustomDrink = false;
          });
        }
      }
    } catch (e) {
      print('Error loading custom drink: $e');
      if (mounted) {
        setState(() {
          _loadingCustomDrink = false;
        });
      }
    }
  }

  String get _getEmoji {
    if (widget.drink.type == DrinkType.custom && _customDrink != null) {
      return _customDrink!.emoji;
    } else {
      return Drink.getEmojiForType(widget.drink.type);
    }
  }

  Color get _getColor {
    if (widget.drink.type == DrinkType.custom && _customDrink != null) {
      return _customDrink!.color;
    } else {
      return Drink.getColorForType(widget.drink.type);
    }
  }

  String get _getTypeString {
    if (widget.drink.type == DrinkType.custom && _customDrink != null) {
      return _customDrink!.name;
    } else {
      return widget.drink.type.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String emoji = _getEmoji;
    final Color color = _getColor;
    final String typeString = _getTypeString;
    final timeString = DateFormat('h:mm a').format(widget.drink.timestamp);

    // Format cost if available and cost tracking is enabled
    final hasCost = _costTrackingEnabled && widget.drink.cost != null;
    final costString = hasCost ? '$_currencySymbol${widget.drink.cost!.toStringAsFixed(2)}' : null;

    // Check if location is available
    final hasLocation = widget.drink.location != null && widget.drink.location!.isNotEmpty;

    // Show loading indicator if still loading custom drink
    if (_loadingCustomDrink) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF333333),
            width: 1,
          ),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onLongPress: widget.onDelete,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                                  widget.drink.location!,
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

                        if (widget.drink.note != null && widget.drink.note!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.drink.note!,
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
                          widget.drink.standardDrinks.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.onDelete,
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: Color(0xFF888888),
                      size: 20,
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