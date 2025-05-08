// lib/widgets/stats/stats_categories_widget.dart
import 'package:flutter/material.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';

class StatsCategoriesWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;
  final bool costTrackingEnabled;
  final String currencySymbol;

  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);

  const StatsCategoriesWidget({
    Key? key,
    required this.dataService,
    required this.selectedTimeRange,
    required this.costTrackingEnabled,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final drinksByCategory = dataService.getDrinksByCategory(selectedTimeRange);
    final costsByCategory = dataService.getCostsByCategory(selectedTimeRange);
    final totalStandardDrinks = dataService.totalStandardDrinks(selectedTimeRange);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Drinks by Type 🍹',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          ...drinksByCategory.entries
              .toList()
              .map((entry) {
            final category = entry.key;
            final standardDrinks = entry.value;
            final percentage = standardDrinks / totalStandardDrinks * 100;

            // Get emoji for this category
            final emoji = dataService.getEmojiForCategory(category);
            // Get color for this category
            final color = dataService.getColorForCategory(category);

            // Get cost for this type if available
            final cost = costsByCategory[category];
            final hasCost = costTrackingEnabled && cost != null && cost > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$emoji $category',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${standardDrinks.toStringAsFixed(1)} (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (hasCost) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $currencySymbol${cost!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: const Color(0xFF333333),
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}