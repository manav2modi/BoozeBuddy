// lib/widgets/stats/stats_summary_widget.dart
import 'package:flutter/material.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';

class StatsSummaryWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;
  final bool costTrackingEnabled;
  final String currencySymbol;

  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);

  const StatsSummaryWidget({
    Key? key,
    required this.dataService,
    required this.selectedTimeRange,
    required this.costTrackingEnabled,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalStandardDrinks = dataService.totalStandardDrinks(selectedTimeRange);
    final totalDrinkingDays = dataService.totalDrinkingDays(selectedTimeRange);
    final averageDrinksPerDay = dataService.averageDrinksPerDay(selectedTimeRange);
    final maxDrinksInOneDay = dataService.maxDrinksInOneDay(selectedTimeRange);
    final mostPopularDayOfWeek = dataService.mostPopularDayOfWeek(selectedTimeRange);

    // Get favorite drink (most consumed category)
    String favoriteDrink = 'N/A';
    final drinksByCategory = dataService.getDrinksByCategory(selectedTimeRange);
    if (drinksByCategory.isNotEmpty) {
      final topCategory = drinksByCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      favoriteDrink = dataService.getEmojiForCategory(topCategory);
    }

    // Cost data
    final totalCost = dataService.totalCost(selectedTimeRange);
    final averageCostPerDrink = dataService.averageCostPerDrink(selectedTimeRange);

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
            'Summary 📊',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                emoji: '🥃',
                title: 'Total',
                value: totalStandardDrinks.toStringAsFixed(1),
              ),
              _StatTile(
                emoji: '📆',
                title: 'Days',
                value: totalDrinkingDays.toString(),
              ),
              _StatTile(
                emoji: '📊',
                title: 'Avg/Day',
                value: averageDrinksPerDay.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                emoji: '🔝',
                title: 'Max Day',
                value: maxDrinksInOneDay.toStringAsFixed(1),
              ),
              _StatTile(
                emoji: '📅',
                title: 'Popular Day',
                value: mostPopularDayOfWeek,
                isTextValue: true,
              ),
              _StatTile(
                emoji: '🔠',
                title: 'Fav Drink',
                value: favoriteDrink,
                isTextValue: true,
              ),
            ],
          ),

          // Cost summary (conditional)
          if (costTrackingEnabled && totalCost > 0) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF333333)),
            const SizedBox(height: 16),
            const Text(
              'Cost Summary 💰',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatTile(
                  emoji: '💵',
                  title: 'Total',
                  value: '$currencySymbol${totalCost.toStringAsFixed(2)}',
                ),
                _StatTile(
                  emoji: '🍹',
                  title: 'Avg/Drink',
                  value: '$currencySymbol${averageCostPerDrink.toStringAsFixed(2)}',
                ),
                _StatTile(
                  emoji: '📊',
                  title: 'Avg/Day',
                  value: totalDrinkingDays > 0
                      ? '$currencySymbol${(totalCost / totalDrinkingDays).toStringAsFixed(2)}'
                      : '$currencySymbol 0.00',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final bool isTextValue;

  const _StatTile({
    required this.emoji,
    required this.title,
    required this.value,
    this.isTextValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 28,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isTextValue ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF007AFF), // iOS blue
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}