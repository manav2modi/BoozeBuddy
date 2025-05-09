// lib/screens/custom_drinks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/custom_drink.dart';
import '../services/custom_drinks_service.dart';
import '../widgets/custom_drinks/custom_drink_item.dart';
import '../widgets/custom_drinks/custom_drink_dialog.dart';
import '../utils/theme.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/empty_state.dart';

class CustomDrinksScreen extends StatefulWidget {
  const CustomDrinksScreen({Key? key}) : super(key: key);

  @override
  State<CustomDrinksScreen> createState() => _CustomDrinksScreenState();
}

class _CustomDrinksScreenState extends State<CustomDrinksScreen> {
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  List<CustomDrink> _customDrinks = [];
  bool _isLoading = true;

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
    showCustomDrinkDialog(
      context: context,
      existingDrink: existingDrink,
      onSave: _handleCustomDrinkSave,
    );
  }

  Future<void> _handleCustomDrinkSave(
      String name, String emoji, double standardDrinks, Color color, String? id) async {
    bool success;

    if (id != null) {
      // Update existing drink
      final updatedDrink = CustomDrink(
        id: id,
        name: name,
        emoji: emoji,
        defaultStandardDrinks: standardDrinks,
        color: color,
      );
      success = await _customDrinksService.updateCustomDrink(updatedDrink);
    } else {
      // Add new drink
      success = await _customDrinksService.saveCustomDrink(
        name,
        emoji,
        standardDrinks, // Always 1.0
        color,
      );
    }

    if (mounted) {
      if (success) {
        _loadCustomDrinks();
      } else {
        _showErrorDialog('Failed to save custom drink');
      }
    }
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

  Future<void> _handleDeleteDrink(String id) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed) {
      final success = await _customDrinksService.deleteCustomDrink(id);
      if (success) {
        _loadCustomDrinks();
      } else {
        _showErrorDialog('Failed to delete custom drink');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.cardColor,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFF333333),
            width: 0.5,
          ),
        ),
        middle: const Text('Custom Drinks'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
          children: [
            Expanded(
              child: _customDrinks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _customDrinks.length,
                separatorBuilder: (context, index) =>
                const Divider(color: Color(0xFF333333)),
                itemBuilder: (context, index) {
                  final customDrink = _customDrinks[index];
                  return CustomDrinkItem(
                    customDrink: customDrink,
                    onEdit: () => _showAddEditCustomDrinkDialog(existingDrink: customDrink),
                    onDelete: () => _handleDeleteDrink(customDrink.id),
                  );
                },
              ),
            ),
            // Add button with fixed styling for when custom drinks exist
            if (_customDrinks.isNotEmpty)
              _buildAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.lab_flask,
            size: 72,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            "No custom drinks yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Create your own special drinks with custom names, colors, and emojis",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            text: "Create Custom Drink",
            emoji: "🧪",
            onPressed: () => _showAddEditCustomDrinkDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GradientButton(
        text: 'Add New Custom Drink',
        emoji: '➕',
        onPressed: () => _showAddEditCustomDrinkDialog(),
      ),
    );
  }
}