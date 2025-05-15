// lib/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../widgets/common/fun_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  // Notification settings
  bool _allNotificationsEnabled = true;
  bool _eveningReminderEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _milestoneEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 30); // 9:30 PM
  int _weeklyReportDay = DateTime.sunday;

  final List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _allNotificationsEnabled = prefs.getBool(NotificationService.enabledKey) ?? true;
      _eveningReminderEnabled = prefs.getBool(NotificationService.eveningReminderEnabledKey) ?? true;
      _weeklySummaryEnabled = prefs.getBool(NotificationService.weeklySummaryEnabledKey) ?? true;
      _milestoneEnabled = prefs.getBool(NotificationService.milestoneEnabledKey) ?? true;

      // Get reminder time
      final reminderTimeString = prefs.getString(NotificationService.reminderTimeKey) ?? '21:30';
      final timeParts = reminderTimeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      _reminderTime = TimeOfDay(hour: hour, minute: minute);

      // Get weekly report day
      _weeklyReportDay = prefs.getInt(NotificationService.weeklyReportDayKey) ?? DateTime.sunday;
    });
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: const Color(0xFF2C2C2C),
          child: Column(
            children: [
              Container(
                height: 44,
                color: const Color(0xFF2C2C2C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _notificationService.setEveningReminderTime(_reminderTime);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0, color: Color(0xFF3D3D3D)),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                      2022, 1, 1,
                      _reminderTime.hour,
                      _reminderTime.minute
                  ),
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      _reminderTime = TimeOfDay(
                          hour: newTime.hour,
                          minute: newTime.minute
                      );
                    });
                  },
                  backgroundColor: const Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDayPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: const Color(0xFF2C2C2C),
          child: Column(
            children: [
              Container(
                height: 44,
                color: const Color(0xFF2C2C2C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _notificationService.setWeeklyReportDay(_weeklyReportDay);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 0, color: Color(0xFF3D3D3D)),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: const Color(0xFF2C2C2C),
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _dayToIndex(_weeklyReportDay),
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _weeklyReportDay = _indexToDay(index);
                    });
                  },
                  children: _dayNames.map((day) => Center(
                    child: Text(
                      day,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _dayToIndex(int day) {
    // Convert from DateTime.monday (1) to index 0, etc.
    return day - 1;
  }

  int _indexToDay(int index) {
    // Convert from index 0 to DateTime.monday (1), etc.
    return index + 1;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.cardColor,
        middle: Text('Notification Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Master toggle for all notifications
            FunCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      CupertinoSwitch(
                        value: _allNotificationsEnabled,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _allNotificationsEnabled = value;
                          });
                          _notificationService.toggleNotifications(value);
                        },
                      ),
                    ],
                  ),
                  if (_allNotificationsEnabled)
                    const Text(
                      'BoozeBuddy will send you helpful reminders and insights about your drinking patterns.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    )
                  else
                    const Text(
                      'Turn on notifications to get timely reminders and insights.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_allNotificationsEnabled) ...[
              // Evening Reminder Settings
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🍹',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Evening Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _eveningReminderEnabled,
                          activeColor: AppTheme.secondaryColor,
                          onChanged: (value) {
                            setState(() {
                              _eveningReminderEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.eveningReminderEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A gentle reminder to log your drinks before bed. Perfect for nights out!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    if (_eveningReminderEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showTimePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.clock,
                                color: AppTheme.secondaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Reminder Time:',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _reminderTime.format(context),
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: Color(0xFF888888),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Weekly Summary Settings
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '📊',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Weekly Stats Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _weeklySummaryEnabled,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _weeklySummaryEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.weeklySummaryEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get insights on your weekly drinking patterns, like a mini Spotify Wrapped for your drinks.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    if (_weeklySummaryEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showDayPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.calendar,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Send summary on:',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _dayNames[_dayToIndex(_weeklyReportDay)],
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: Color(0xFF888888),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Milestone and Achievement Settings
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🏆',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Milestones & Achievements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _milestoneEnabled,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _milestoneEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.milestoneEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Celebrate your progress with notifications for streaks, tracking milestones, and more.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Passport Badge Notifications
              // FunCard(
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         children: [
              //           Container(
              //             padding: const EdgeInsets.all(8),
              //             decoration: BoxDecoration(
              //               color: const Color(0xFFFF5722).withOpacity(0.2),
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             child: const Text(
              //               '🎖️',
              //               style: TextStyle(fontSize: 20),
              //             ),
              //           ),
              //           const SizedBox(width: 12),
              //           const Expanded(
              //             child: Text(
              //               'Passport Badges',
              //               style: TextStyle(
              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w600,
              //                 color: Colors.white,
              //               ),
              //             ),
              //           ),
              //           CupertinoSwitch(
              //             value: _badgeEnabled,
              //             activeColor: const Color(0xFFFF5722),
              //             onChanged: (value) {
              //               setState(() {
              //                 _badgeEnabled = value;
              //               });
              //               _notificationService.toggleNotificationType(
              //                   NotificationService.badgeEnabledKey,
              //                   false
              //               );
              //             },
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 8),
              //       const Text(
              //         'Get notified when you earn new badges in your BoozeBuddy Passport.',
              //         style: TextStyle(
              //           fontSize: 14,
              //           color: Color(0xFFAAAAAA),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ],
        ),
      ),
    );
  }
}