// lib/widgets/add_drink/standard_drinks_slider.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class StandardDrinksSlider extends StatelessWidget {
  final double standardDrinks;
  final Color selectedColor;
  final ValueChanged<double> onChanged;

  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _textSecondaryColor = Color(0xFF888888);

  const StandardDrinksSlider({
    Key? key,
    required this.standardDrinks,
    required this.selectedColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Standard Drinks 🥃',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How many standard drinks?',
              style: TextStyle(
                fontSize: 15,
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
                    fontSize: 15,
                    color: _textSecondaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
                Expanded(
                  child: CupertinoSlider(
                    value: standardDrinks,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    activeColor: selectedColor,
                    onChanged: onChanged,
                  ),
                ),
                const Text(
                  '5.0',
                  style: TextStyle(
                    fontSize: 15,
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
                  standardDrinks.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 17,
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
    );
  }
}