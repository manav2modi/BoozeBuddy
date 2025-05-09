import 'package:flutter/material.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';
import '../../utils/theme.dart';

class StatsChartWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;
  final String chartType; // 'drinks' or 'cost'
  final String prefix; // Currency symbol for cost chart

  const StatsChartWidget({
    Key? key,
    required this.dataService,
    required this.selectedTimeRange,
    required this.chartType,
    required this.prefix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the appropriate chart data based on type
    final Map<String, double> chartData = chartType == 'drinks'
        ? dataService.getChartData(selectedTimeRange)
        : dataService.getCostChartData(selectedTimeRange);

    if (chartData.isEmpty) {
      return const Center(
        child: Text(
          'No data for selected time range',
          style: TextStyle(
            color: Color(0xFF888888),
          ),
        ),
      );
    }

    final maxValue = chartData.values.isEmpty ? 1.0 :
    (chartData.values.reduce((a, b) => a > b ? a : b) + 1);

    // Get chart labels in proper order
    List<String> sortedLabels;
    switch (selectedTimeRange) {
      case TimeRange.week:
      // Order by days of week (Mon-Sun)
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        sortedLabels = days.where((day) => chartData.containsKey(day)).toList();
        break;
      case TimeRange.month:
      // Order by week number
        sortedLabels = chartData.keys.toList()
          ..sort((a, b) {
            final aNum = int.tryParse(a.split(' ')[1]) ?? 0;
            final bNum = int.tryParse(b.split(' ')[1]) ?? 0;
            return aNum.compareTo(bNum);
          });
        break;
      case TimeRange.threeMonths:
      // Order by date (already sorted in chartData)
        sortedLabels = chartData.keys.toList();
        break;
      case TimeRange.year:
      case TimeRange.allTime:
      // Order months chronologically
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        sortedLabels = months.where((month) => chartData.containsKey(month)).toList();
        break;
    }

    // Fix for overflow issues in 3-month view - limit number of labels if needed
    if (selectedTimeRange == TimeRange.threeMonths && sortedLabels.length > 8) {
      // Keep only every other label for 3-month view
      sortedLabels = sortedLabels.asMap()
          .entries
          .where((entry) => entry.key % 2 == 0) // Keep every other entry
          .map((entry) => entry.value)
          .toList();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(sortedLabels.length, (index) {
        final label = sortedLabels[index];
        final value = chartData[label] ?? 0;
        final percentage = value / maxValue;

        // Fixed column structure to avoid overflow
        return Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            // Stagger the animations
            builder: (context, animValue, child) {
              final delayedValue = index / sortedLabels.length;
              final adjustedValue = (animValue - delayedValue * 0.2).clamp(0.0, 1.0) * 1.25;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min, // Add this to fix column overflow
                  children: [
                    // Value label with a nice fade-in effect
                    Opacity(
                      opacity: adjustedValue.clamp(0.0, 1.0),
                      child: value > 0
                          ? FittedBox( // Add FittedBox to prevent text overflow
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$prefix${value.toStringAsFixed(prefix.isNotEmpty ? 2 : 1)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: _getBarColor(value, maxValue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 2), // Reduce height
                    // Bar with grow animation - Fixed height calculation
                    Container(
                      height: (150 * percentage * adjustedValue).clamp(0.0, 150.0), // Clamp height
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            _getBarColor(value, maxValue).withOpacity(0.7),
                            _getBarColor(value, maxValue),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4), // Reduce height
                    // Label
                    FittedBox( // Add FittedBox to prevent text overflow
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatLabel(label, selectedTimeRange),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2), // Add small buffer at bottom
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // Dynamic color based on value (higher value = more intense color)
  Color _getBarColor(double value, double maxValue) {
    final ratio = value / maxValue;

    if (chartType == 'drinks') {
      // Purple to amber gradient for drinks
      if (ratio > 0.7) {
        return AppTheme.secondaryColor; // More drinks = amber
      } else if (ratio > 0.4) {
        return Color.lerp(AppTheme.primaryColor, AppTheme.secondaryColor, (ratio - 0.4) / 0.3)!;
      } else {
        return AppTheme.primaryColor; // Fewer drinks = purple
      }
    } else {
      // Green to amber gradient for costs
      if (ratio > 0.7) {
        return AppTheme.secondaryColor; // Higher cost = amber
      } else if (ratio > 0.4) {
        return Color.lerp(Colors.greenAccent, AppTheme.secondaryColor, (ratio - 0.4) / 0.3)!;
      } else {
        return Colors.greenAccent; // Lower cost = green
      }
    }
  }

  String _formatLabel(String label, TimeRange timeRange) {
    // For 3-month view with MM/dd format, shorten to just the day
    if (timeRange == TimeRange.threeMonths && label.contains('/')) {
      return label.split('/')[1]; // Just show the day
    }

    return label;
  }
}