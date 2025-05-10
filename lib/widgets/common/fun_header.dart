// lib/widgets/common/fun_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import 'swipeable_date_selector.dart.dart';

class FunHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onSettingsTap;
  final double totalDrinks;
  final ValueChanged<DateTime> onDateChange;

  const FunHeader({
    Key? key,
    required this.selectedDate,
    required this.onDateTap,
    required this.onSettingsTap,
    required this.totalDrinks,
    required this.onDateChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dynamic greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 6) {
      greeting = "Enjoy the party! 🎉";
    } else if (hour < 12) {
      greeting = "Good Morning! 🌞";
    } else if (hour < 17) {
      greeting = "Good Afternoon! 🌤️";
    } else {
      greeting = "Good Evening! 🌙";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with logo and actions
          Row(
            children: [
              // Fun animated logo
              _buildLogo(),
              const Spacer(),
              // Date selector with fun styling
              _buildDateSelector(context),
              const SizedBox(width: 8),
              // Settings button
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.settings,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                onPressed: onSettingsTap,
              ),
            ],
          ),

          // Greeting and stats section
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today\'s the perfect day to keep track!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Today's summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.2),
                  AppTheme.primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDrinkMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildDrinksCounter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 28,
          // If you don't have this asset, use an emoji instead:
          errorBuilder: (context, error, stackTrace) => const Text(
            '🍻',
            style: TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'BoozeBuddy',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return SwipeableDateSelector(
      selectedDate: selectedDate,
      onDateChanged: (newDate) {
        // This will need to pass through to HomeScreen
        onDateChange(newDate);
      },
      onTap: () => _selectDate(context),
    );
  }

  void _selectDate(BuildContext context) {
    // Determine if we should show animation based on when the date was selected
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    final isYesterday = selectedDate.year == DateTime.now().subtract(const Duration(days: 1)).year &&
        selectedDate.month == DateTime.now().subtract(const Duration(days: 1)).month &&
        selectedDate.day == DateTime.now().subtract(const Duration(days: 1)).day;

    // Different greeting based on date
    String dateGreeting;
    String dateEmoji;

    if (isToday) {
      dateGreeting = "Viewing today's drinks";
      dateEmoji = "🍻";
    } else if (isYesterday) {
      dateGreeting = "Checking yesterday's drinks";
      dateEmoji = "⏰";
    } else {
      dateGreeting = "Looking at past drinks";
      dateEmoji = "📆";
    }

    // Use our improved date picker approach
    _showImprovedDatePicker(context, dateGreeting, dateEmoji);
  }

  // New improved date picker that won't get cut off
  void _showImprovedDatePicker(BuildContext context, String dateGreeting, String dateEmoji) {
    DateTime tempSelectedDate = selectedDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false, // respect only the bottom inset
        child: Container(
          // force full‐width
          width: MediaQuery.of(ctx).size.width,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          // size to contents
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // … your fun header …
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor.withOpacity(0.3),
                      AppTheme.primaryColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(dateEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      dateGreeting,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // action row with a bit of horizontal padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.primaryColor)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          onDateChange(tempSelectedDate);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 0, color: Color(0xFF3D3D3D)),

              // fixed‐height picker
              SizedBox(
                height: 216, // the “natural” height of a Cupertino picker
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: AppTheme.primaryColor,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selectedDate,
                    maximumDate: DateTime.now(),
                    minimumDate: DateTime.now().subtract(const Duration(days: 365)),
                    onDateTimeChanged: (newDate) => tempSelectedDate = newDate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrinksCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.boozeBuddyGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('🥃', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            totalDrinks.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getDrinkMessage() {
    if (totalDrinks == 0) {
      return "Nothing tracked yet today";
    } else if (totalDrinks <= 1) {
      return "Just getting started";
    } else if (totalDrinks <= 2) {
      return "Keeping it social";
    } else if (totalDrinks <= 4) {
      return "Having a good time";
    } else {
      return "Party mode activated";
    }
  }
}