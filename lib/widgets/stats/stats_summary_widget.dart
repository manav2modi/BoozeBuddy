// lib/widgets/stats/stats_summary_widget.dart - Modified version
import 'package:flutter/material.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';
import '../../widgets/common/fun_card.dart'; // Add this import
import '../../utils/theme.dart'; // Add this import

class StatsSummaryWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;
  final bool costTrackingEnabled;
  final String currencySymbol;

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

    // Using FunCard instead of plain Container
    return FunCard(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Summary 📊',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Adding a subtle animation for the summary icon
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (value * 0.1), // Subtle pulse
                    child: const Icon(
                      Icons.insights,
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
              ),
            ],
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
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.dividerColor,
                    AppTheme.dividerColor,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cost Summary 💰',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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

// Animated _StatTile widget
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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: Column(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    this.value,
                    style: TextStyle(
                      fontSize: isTextValue ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
