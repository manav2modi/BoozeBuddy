// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sip_track/models/citation.dart';
import 'package:sip_track/utils/theme.dart';
import 'package:sip_track/widgets/common/fun_card.dart';
import 'package:sip_track/widgets/stats/drinking_patterns_widget.dart';
import '../models/drink.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/custom_drinks_service.dart';
import '../widgets/stats/stats_summary_widget.dart';
import '../widgets/stats/stats_chart_widget.dart';
import '../widgets/stats/stats_categories_widget.dart';
import '../services/stats_data_service.dart';
import 'citations_screen.dart';

enum TimeRange {
  week,
  month,
  threeMonths,
  year,
  allTime
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StorageService _storageService = StorageService();
  final SettingsService _settingsService = SettingsService();
  final CustomDrinksService _customDrinksService = CustomDrinksService();
  late StatsDataService _dataService;

  List<Drink> _drinks = [];
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.week;
  bool _costTrackingEnabled = false;
  String _currencySymbol = '\$';
  ScrollController _scrollController = ScrollController();
  bool _showScrollHint = true;

  // Colors
  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _segmentedControlColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _dataService = StatsDataService(_customDrinksService);
    _loadSettings();
    _loadDrinks();
    _dataService.loadCustomDrinks();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _showScrollHint) {
        setState(() {
          _showScrollHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final costTrackingEnabled = await _settingsService.getCostTrackingEnabled();
    final currencySymbol = await _settingsService.getCurrencySymbol();

    setState(() {
      _costTrackingEnabled = costTrackingEnabled;
      _currencySymbol = currencySymbol;
    });
  }

  Widget _buildScrollHint() {
    if (!_showScrollHint) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -4 * (0.5 - (value - 0.5).abs())),
                    child: const Icon(
                      CupertinoIcons.chevron_down,
                      color: Colors.white,
                      size: 14,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text(
                'Scroll for more',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadDrinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all drinks
      final allDrinks = await _storageService.getDrinks();

      setState(() {
        _drinks = allDrinks;
        _isLoading = false;
        _dataService.updateDrinks(allDrinks);
      });
    } catch (e) {
      print('Error loading drinks: $e');
      setState(() {
        _drinks = [];
        _isLoading = false;
      });
    }
  }

  String _getChartTitle(String metric) {
    String timeRange;
    switch (_selectedTimeRange) {
      case TimeRange.week:
        timeRange = 'Past 7 Days';
        break;
      case TimeRange.month:
        timeRange = 'Past Month (Weekly)';
        break;
      case TimeRange.threeMonths:
        timeRange = 'Past 3M (Weekly)';
        break;
      case TimeRange.year:
        timeRange = 'Past Year (Monthly)';
        break;
      case TimeRange.allTime:
        timeRange = 'All Time (Monthly)';
        break;
    }

    final emoji = metric == 'Drinks' ? '📈' : '💰';
    return '$metric by $timeRange $emoji';
  }

  // Modified _showHealthInfoAlert method for stats_screen.dart
  void _showHealthInfoAlert() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Drinking Guidelines'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Low-risk drinking guidelines recommend:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• No more than 2 standard drinks per day',
              style: TextStyle(decoration: TextDecoration.none),
            ),
            const Text(
              '• No more than 10 standard drinks per week',
              style: TextStyle(decoration: TextDecoration.none),
            ),
            const Text(
              '• Several alcohol-free days per week',
              style: TextStyle(decoration: TextDecoration.none),
            ),
            const SizedBox(height: 12),
            const Text(
              'Remember that these are guidelines only. The safest option is to not drink alcohol at all.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF444444)),
            const SizedBox(height: 12),
            const Text(
              'Sources:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            _buildCitationButton(
                HealthCitations.who.title,
                    () => _navigateToCitationsScreen()
            ),
            const SizedBox(height: 4),
            _buildCitationButton(
                HealthCitations.cdc.title,
                    () => _navigateToCitationsScreen()
            ),
            const SizedBox(height: 4),
            _buildCitationButton(
                HealthCitations.niaaa.title,
                    () => _navigateToCitationsScreen()
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('View All Sources'),
            onPressed: () {
              Navigator.pop(context);
              _navigateToCitationsScreen();
            },
          ),
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

// Helper to build citation buttons that navigate to the Citations screen
  Widget _buildCitationButton(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

// Method to navigate to Citations screen
  void _navigateToCitationsScreen() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const CitationsScreen(),
      ),
    );
  }

  // Modified _buildHealthTips method for stats_screen.dart
  Widget _buildHealthTips() {
    final averageDrinksPerDay = _dataService.averageDrinksPerDay(_selectedTimeRange);
    final maxDrinksInOneDay = _dataService.maxDrinksInOneDay(_selectedTimeRange);

    String tip;
    Color tipColor;

    if (averageDrinksPerDay <= 1.0 && maxDrinksInOneDay <= 2.0) {
      tip = "You're drinking within low-risk guidelines. Great job! 👍";
      tipColor = const Color(0xFF4CD964); // iOS green
    } else if (averageDrinksPerDay <= 2.0 && maxDrinksInOneDay <= 4.0) {
      tip = "Your drinking is moderate. Try alcohol-free days during your week. 🔄";
      tipColor = const Color(0xFFFFCC00); // iOS yellow
    } else {
      tip = "Consider reducing your alcohol intake for better health. 🚨";
      tipColor = const Color(0xFFFF3B30); // iOS red
    }

    // Add cost-saving tip if cost tracking is enabled
    if (_costTrackingEnabled && _dataService.totalCost(_selectedTimeRange) > 0) {
      final totalCost = _dataService.totalCost(_selectedTimeRange);
      final drinkingDays = _dataService.totalDrinkingDays(_selectedTimeRange);
      if (drinkingDays > 0) {
        final monthlyCost = totalCost * 30 / drinkingDays;
        if (monthlyCost > 200) {
          tip += " You could save around $_currencySymbol${(monthlyCost * 0.3).toStringAsFixed(2)} per month by reducing your drinking by 30%.";
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tipColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tipColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                color: tipColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    color: tipColor,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Add citation note below the tips
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: Color(0xFF888888),
                size: 12,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  _showHealthInfoAlert();
                },
                child: const Text(
                  "Based on health guidelines - Tap for sources",
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  return Stack(
    children: [
      CustomScrollView(
        controller: _scrollController,
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadDrinks,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _drinks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar_fill,
                          size: 72,
                          color: Color(0xFF555555),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No drinks logged yet",
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time range selector with FunCard
                        FunCard(
                          color: AppTheme.cardColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time Range',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CupertinoSlidingSegmentedControl<TimeRange>(
                                backgroundColor: const Color(0xFF333333),
                                thumbColor: const Color(0xFF444444),
                                groupValue: _selectedTimeRange,
                                children: const {
                                  TimeRange.week: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                    child: Text(
                                      'Week',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  TimeRange.month: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                    child: Text(
                                      'Month',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  TimeRange.threeMonths: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                    child: Text(
                                      '3 Mo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  TimeRange.year: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                    child: Text(
                                      'Year',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  TimeRange.allTime: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                                    child: Text(
                                      'All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                },
                                onValueChanged: (TimeRange? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedTimeRange = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Summary Stats Card with FunCard
                        StatsSummaryWidget(
                          dataService: _dataService,
                          selectedTimeRange: _selectedTimeRange,
                          costTrackingEnabled: _costTrackingEnabled,
                          currencySymbol: _currencySymbol,
                        ),

                        const SizedBox(height: 16),

                        // NEW: Drinking Patterns Widget
                        DrinkingPatternsWidget(
                          dataService: _dataService,
                          selectedTimeRange: _selectedTimeRange,
                        ),

                        const SizedBox(height: 16),

                        // Drinks Chart with FunCard
                        FunCard(
                          color: AppTheme.cardColor,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _getChartTitle('Drinks'),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Small pulse animation for the chart icon
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(seconds: 1),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.9 + (value * 0.1), // Subtle pulse
                                        child: const Icon(
                                          CupertinoIcons.graph_circle_fill,
                                          color: AppTheme.secondaryColor,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: StatsChartWidget(
                                  dataService: _dataService,
                                  selectedTimeRange: _selectedTimeRange,
                                  chartType: 'drinks',
                                  prefix: '',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cost Chart Card (conditional) with FunCard
                        if (_costTrackingEnabled &&
                            _dataService.getCostChartData(_selectedTimeRange).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          FunCard(
                            color: AppTheme.cardColor,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getChartTitle('Spending'),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: 1),
                                      duration: const Duration(seconds: 1),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.9 + (value * 0.1), // Subtle pulse
                                          child: const Icon(
                                            CupertinoIcons.money_dollar_circle_fill,
                                            color: Color(0xFF4CD964), // iOS green
                                            size: 20,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 200,
                                  child: StatsChartWidget(
                                    dataService: _dataService,
                                    selectedTimeRange: _selectedTimeRange,
                                    chartType: 'cost',
                                    prefix: _currencySymbol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Drink Categories Display with FunCard
                        if (_dataService.getDrinksByCategory(_selectedTimeRange).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          StatsCategoriesWidget(
                            dataService: _dataService,
                            selectedTimeRange: _selectedTimeRange,
                            costTrackingEnabled: _costTrackingEnabled,
                            currencySymbol: _currencySymbol,
                          ),
                        ],

                        // Top Locations (conditional) with FunCard
                        if (_dataService.hasLocationData(_selectedTimeRange)) ...[
                          const SizedBox(height: 16),
                          FunCard(
                            color: AppTheme.cardColor,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Top Locations 📍',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(
                                      CupertinoIcons.location_circle_fill,
                                      color: Color(0xFF007AFF), // iOS blue
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._dataService.getTopLocations(_selectedTimeRange).entries
                                    .toList()
                                    .map((entry) {
                                  final location = entry.key;
                                  final count = entry.value;
                                  final totalWithLocation = _dataService.drinksWithLocation(_selectedTimeRange);
                                  final percentage = totalWithLocation > 0 ? count / totalWithLocation * 100 : 0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.location_fill,
                                              size: 16,
                                              color: Color(0xFF007AFF),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '$count (${percentage.round()}%)',
                                              style: const TextStyle(
                                                color: Color(0xFF007AFF),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Animated progress bar
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0, end: percentage / 100),
                                          duration: const Duration(milliseconds: 1000),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: value,
                                                backgroundColor: const Color(0xFF333333),
                                                color: const Color(0xFF007AFF),
                                                minHeight: 8,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                // Add a message for the case with few locations
                                if (_dataService.getTopLocations(_selectedTimeRange).length == 1)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      "Keep tracking more locations to see your patterns!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Tips Section with FunCard
                        const SizedBox(height: 16),
                        FunCard(
                          color: AppTheme.cardColor,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Healthy Drinking Tips 💡',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.info_circle,
                                      color: Color(0xFF007AFF),
                                    ),
                                    onPressed: _showHealthInfoAlert,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildHealthTips(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
        ],
      ),
      _buildScrollHint(),
    ],
  );
}

}