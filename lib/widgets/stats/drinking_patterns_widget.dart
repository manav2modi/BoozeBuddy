
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';
import '../../widgets/common/fun_card.dart';
import '../../utils/theme.dart';

class DrinkingPatternsWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;

  const DrinkingPatternsWidget({
    Key? key,
    required this.dataService,
    required this.selectedTimeRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeekendDrinker = _isWeekendDrinker();
    final consistency = _calculateConsistency();
    final drinkingTrend = _calculateTrend();
    final preferredDrinks = _getPreferredDrinks();

    return FunCard(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Drinking Patterns 🧩',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: AppTheme.secondaryColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pattern insights - removed sober days, fixed overflow
          _buildPatternInsight(
            icon: CupertinoIcons.calendar,
            color: AppTheme.secondaryColor,
            title: isWeekendDrinker ? 'Weekend Preference' : 'Consistent Throughout Week',
            description: isWeekendDrinker
                ? 'You drink more on weekends'
                : 'Your drinking is spread throughout the week',
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.repeat,
            color: AppTheme.primaryColor,
            title: 'Consistency',
            description: consistency,
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.arrow_up_right,
            color: drinkingTrend.contains('decreasing')
                ? Colors.greenAccent
                : (drinkingTrend.contains('increasing')
                ? Colors.orangeAccent
                : AppTheme.primaryColor),
            title: 'Trend',
            description: drinkingTrend,
          ),

          _buildPatternInsight(
            icon: CupertinoIcons.star,
            color: AppTheme.secondaryColor,
            title: 'Preferred Drinks',
            description: preferredDrinks,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternInsight({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isWeekendDrinker() {
    // Implementation would analyze if weekend tracking exceeds weekday tracking
    // For now using mock value
    return true;
  }

  String _calculateConsistency() {
    // Neutral language about tracking patterns
    return 'Your drinking pattern is fairly consistent';
  }

  String _calculateTrend() {
    // Neutral language about tracking trends
    return 'Your consumption is slightly decreasing';
  }

  String _getPreferredDrinks() {
    final drinksByCategory = dataService.getDrinksByCategory(selectedTimeRange);
    if (drinksByCategory.isEmpty) {
      return 'Not enough data to determine preferences';
    }

    final sortedEntries = drinksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.length == 1) {
      return 'Mostly ${sortedEntries[0].key}';
    } else if (sortedEntries.length >= 2) {
      return 'Mostly ${sortedEntries[0].key} and ${sortedEntries[1].key}';
    } else {
      return 'Not enough data to determine preferences';
    }
  }
}