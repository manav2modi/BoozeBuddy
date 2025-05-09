import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';

class SwipeableDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onTap;

  const SwipeableDateSelector({
    Key? key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Check if at minimum date (30 days ago)
    final minDate = now.subtract(const Duration(days: 30));
    final isAtMinDate = selectedDate.year == minDate.year &&
        selectedDate.month == minDate.month &&
        selectedDate.day == minDate.day;

    return GestureDetector(
      // Open date picker on tap
      onTap: onTap,
      // Handle horizontal swipe gestures
      onHorizontalDragEnd: (details) {
        // Determine swipe direction
        if (details.primaryVelocity! > 0 && !isAtMinDate) {
          // Swiped right - go to previous day if not at minimum date
          onDateChanged(selectedDate.subtract(const Duration(days: 1)));
        } else if (details.primaryVelocity! < 0 && !isToday) {
          // Swiped left - go to next day if not today
          onDateChanged(selectedDate.add(const Duration(days: 1)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Left arrow - show with low opacity if at minimum date
            Icon(
              CupertinoIcons.chevron_left,
              color: isAtMinDate
                  ? AppTheme.secondaryColor.withOpacity(0.3)
                  : AppTheme.secondaryColor.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.calendar,
              color: AppTheme.secondaryColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              DateFormat('MMM d').format(selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            // Right arrow - show with low opacity if today
            Icon(
              CupertinoIcons.chevron_right,
              color: isToday
                  ? AppTheme.secondaryColor.withOpacity(0.3)
                  : AppTheme.secondaryColor.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}