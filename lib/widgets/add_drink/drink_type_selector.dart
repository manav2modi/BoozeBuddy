// lib/widgets/add_drink/drink_type_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/drink.dart';
import '../../models/custom_drink.dart';

class DrinkTypeSelector extends StatelessWidget {
  final int currentTabIndex;
  final TabController tabController;
  final DrinkType selectedType;
  final CustomDrink? selectedCustomDrink;
  final List<CustomDrink> customDrinks;
  final Map<DrinkType, Map<String, dynamic>> drinkTypesInfo;
  final bool loadingCustomDrinks;
  final Function(DrinkType) onDrinkTypeSelected;
  final Function(CustomDrink) onCustomDrinkSelected;
  final VoidCallback onManageCustomDrinks;

  static const Color _accentColor = Color(0xFF007AFF); // iOS blue
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);

  const DrinkTypeSelector({
    Key? key,
    required this.currentTabIndex,
    required this.tabController,
    required this.selectedType,
    required this.selectedCustomDrink,
    required this.customDrinks,
    required this.drinkTypesInfo,
    required this.loadingCustomDrinks,
    required this.onDrinkTypeSelected,
    required this.onCustomDrinkSelected,
    required this.onManageCustomDrinks,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  'Drink Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Spacer(),
                if (currentTabIndex == 1) // Only show when custom drinks tab is selected
                  GestureDetector(
                    onTap: onManageCustomDrinks,
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.pencil,
                          size: 16,
                          color: _accentColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 16,
                            color: _accentColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: const Color(0xFF333333),
              thumbColor: const Color(0xFF444444),
              groupValue: currentTabIndex,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  child: Text(
                    'Default Drinks',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      fontSize: 15,
                    ),
                  ),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  child: Text(
                    'Custom Drinks',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.none,
                      fontSize: 15,
                    ),
                  ),
                ),
              },
              onValueChanged: (int? value) {
                if (value != null) {
                  tabController.animateTo(value);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: TabBarView(
              controller: tabController,
              children: [
                // Default Drinks Tab
                _buildDefaultDrinksTab(),

                // Custom Drinks Tab
                _buildCustomDrinksTab(),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDefaultDrinksTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: drinkTypesInfo.entries.map((entry) {
          final type = entry.key;
          final info = entry.value;
          final color = Drink.getColorForType(type);

          final bool isSelected = selectedType == type && selectedCustomDrink == null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onDrinkTypeSelected(type),
              child: Container(
                width: 85,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : const Color(0xFF444444),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      info['emoji'],
                      style: const TextStyle(
                        fontSize: 28,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? color
                            : Colors.white,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomDrinksTab() {
    if (loadingCustomDrinks) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (customDrinks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No custom drinks yet",
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 22,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text(
                "Create Your First Custom Drink",
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 15,
                ),
              ),
              onPressed: onManageCustomDrinks,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: customDrinks.map((customDrink) {
          final bool isSelected = selectedType == DrinkType.custom &&
              selectedCustomDrink?.id == customDrink.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onCustomDrinkSelected(customDrink),
              child: Container(
                width: 85,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? customDrink.color.withOpacity(0.15)
                      : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? customDrink.color
                        : const Color(0xFF444444),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customDrink.emoji,
                      style: const TextStyle(
                        fontSize: 28,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      customDrink.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? customDrink.color
                            : Colors.white,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}