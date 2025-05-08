// lib/widgets/stats/stats_chart_widget.dart
import 'package:flutter/material.dart';
import '../../screens/stats_screen.dart';
import '../../services/stats_data_service.dart';

class StatsChartWidget extends StatelessWidget {
  final StatsDataService dataService;
  final TimeRange selectedTimeRange;
  final String chartType; // 'drinks' or 'cost'
  final String prefix; // Currency symbol for cost chart

  static const Color _chartBarColor = Color(0xFF007AFF); // iOS blue
  static const Color _chartInactiveColor = Color(0xFF353535);

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
            decoration: TextDecoration.none,
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sortedLabels.map((label) {
        final value = chartData[label] ?? 0;
        final percentage = value / maxValue;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value label
                Text(
                  value > 0 ? '$prefix${value.toStringAsFixed(prefix.isNotEmpty ? 2 : 1)}' : '',
                  style: TextStyle(
                    fontSize: 9,
                    color: value > 0 ? _chartBarColor : Colors.transparent,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                Container(
                  height: 150 * percentage,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: value > 0 ? _chartBarColor : _chartInactiveColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Tooltip(
                  message: label,
                  child: Text(
                    _formatLabel(label, selectedTimeRange),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF888888),
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatLabel(String label, TimeRange timeRange) {
    // For 3-month view with MM/dd format, shorten to just the day
    if (timeRange == TimeRange.threeMonths && label.contains('/')) {
      return label.split('/')[1]; // Just show the day
    }

    return label;
  }
}