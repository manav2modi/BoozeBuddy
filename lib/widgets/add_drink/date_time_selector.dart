// lib/widgets/add_drink/date_time_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';

class DateTimeSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Color selectedColor;
  final ValueChanged<DateTime> onDateTimeSelected;

  static const Color _cardColor = Color(0xFF222222);
  static const Color _cardBorderColor = Color(0xFF333333);
  static const Color _textSecondaryColor = Color(0xFF888888);

  const DateTimeSelector({
    Key? key,
    required this.selectedDate,
    required this.selectedColor,
    required this.onDateTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _cardBorderColor,
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () => _selectDateTime(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.time,
                color: selectedColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM d, yyyy - h:mm a').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      color: _textSecondaryColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                CupertinoIcons.chevron_right,
                color: _textSecondaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDateTime(BuildContext context) {
    // First, calculate proper minimum date that doesn't cause the error
    final now = DateTime.now();
    final minimumDate = DateTime.now().subtract(const Duration(days: 30));

    // Make sure selectedDate is between min and max dates
    DateTime initialDateTime = selectedDate;
    if (initialDateTime.isAfter(now)) {
      initialDateTime = now;
    }
    if (initialDateTime.isBefore(minimumDate)) {
      initialDateTime = minimumDate;
    }

    // Instead of using showCupertinoModalPopup, use our custom approach
    // that ensures the picker is properly positioned with action buttons
    _showFullScreenDatePicker(
      context: context,
      initialDateTime: initialDateTime,
      maximumDate: now,
      minimumDate: minimumDate,
      onDateTimeChanged: onDateTimeSelected,
    );
  }

  // Custom implementation for date picker that ensures proper display
  void _showFullScreenDatePicker({
    required BuildContext context,
    required DateTime initialDateTime,
    required DateTime maximumDate,
    required DateTime minimumDate,
    required ValueChanged<DateTime> onDateTimeChanged,
  }) {
    DateTime tempPickedDate = initialDateTime;

    // Using the BoozeBuddy's primary purple color for buttons
    const buttonColor = AppTheme.primaryColor; // This is the purple color from theme.dart

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Make it responsive to different screen sizes
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height * 0.4, // Adjust height based on screen size
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Action buttons in a fixed position with purple styling
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: buttonColor, // Using the purple color
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: buttonColor, // Using the purple color
                          decoration: TextDecoration.none,
                        ),
                      ),
                      onPressed: () {
                        onDateTimeChanged(tempPickedDate);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 0, color: Color(0xFF3D3D3D)),

              // Date picker in scrollable area
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    primaryColor: buttonColor, // Using the purple color for the picker too
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: initialDateTime,
                    maximumDate: maximumDate,
                    minimumDate: minimumDate,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime dateTime) {
                      tempPickedDate = dateTime;
                    },
                    backgroundColor: const Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}