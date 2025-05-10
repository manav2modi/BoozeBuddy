// lib/widgets/add_drink/drink_details_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:sip_track/widgets/location_widget.dart';

class DrinkDetailsForm extends StatelessWidget {
  final TextEditingController locationController;
  final TextEditingController noteController;
  final TextEditingController costController;
  final bool showCostField;
  final Color selectedColor;

  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _textFieldColor = Color(0xFF2A2A2A);
  static const Color _textSecondaryColor = Color(0xFF888888);

  const DrinkDetailsForm({
    Key? key,
    required this.locationController,
    required this.noteController,
    required this.costController,
    required this.showCostField,
    required this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location Field
        _buildLocationField(),

        // Cost Field (conditionally shown)
        if (showCostField) _buildCostField(),

        // Note Field
        _buildNoteField(),
      ],
    );
  }

  _buildLocationField() {
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
            LocationAutocompleteField(
              controller: locationController,
              accentColor: selectedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostField() {
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
              controller: costController,
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
    );
  }

  Widget _buildNoteField() {
    return Container(
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
              controller: noteController,
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
    );
  }
}