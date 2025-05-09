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
              _buildDateSelector(),
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

  Widget _buildDateSelector() {
    return SwipeableDateSelector(
      selectedDate: selectedDate,
      onDateChanged: (newDate) {
        // This will need to pass through to HomeScreen
        onDateChange(newDate);
      },
      onTap: onDateTap,
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