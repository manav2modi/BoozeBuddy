// lib/screens/notification_settings_screen.dart - Enhanced version
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
  bool _morningRecapEnabled = true;
  bool _weeklySummaryEnabled = true;
  bool _milestoneEnabled = true;
  bool _streakReminderEnabled = true;
  bool _weekendCheckInEnabled = true;
  bool _hydrationReminderEnabled = true;
  bool _soberDayEncouragementEnabled = true;

  TimeOfDay _eveningReminderTime = const TimeOfDay(hour: 21, minute: 30); // 9:30 PM
  TimeOfDay _morningRecapTime = const TimeOfDay(hour: 11, minute: 0); // 11:00 AM
  int _weeklyReportDay = DateTime.sunday;

  final List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  bool _showDebugInfo = false;
  Map<String, dynamic>? _debugInfo;

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
      _morningRecapEnabled = prefs.getBool(NotificationService.morningRecapEnabledKey) ?? true;
      _weeklySummaryEnabled = prefs.getBool(NotificationService.weeklySummaryEnabledKey) ?? true;
      _milestoneEnabled = prefs.getBool(NotificationService.milestoneEnabledKey) ?? true;
      _streakReminderEnabled = prefs.getBool(NotificationService.streakReminderEnabledKey) ?? true;
      _weekendCheckInEnabled = prefs.getBool(NotificationService.weekendCheckInEnabledKey) ?? true;
      _hydrationReminderEnabled = prefs.getBool(NotificationService.hydrationReminderEnabledKey) ?? true;
      _soberDayEncouragementEnabled = prefs.getBool(NotificationService.soberDayEncouragementEnabledKey) ?? true;

      // Get evening reminder time
      final eveningTimeString = prefs.getString(NotificationService.eveningReminderTimeKey) ?? '21:30';
      final eveningTimeParts = eveningTimeString.split(':');
      final eveningHour = int.parse(eveningTimeParts[0]);
      final eveningMinute = int.parse(eveningTimeParts[1]);
      _eveningReminderTime = TimeOfDay(hour: eveningHour, minute: eveningMinute);

      // Get morning recap time
      final morningTimeString = prefs.getString(NotificationService.morningRecapTimeKey) ?? '11:00';
      final morningTimeParts = morningTimeString.split(':');
      final morningHour = int.parse(morningTimeParts[0]);
      final morningMinute = int.parse(morningTimeParts[1]);
      _morningRecapTime = TimeOfDay(hour: morningHour, minute: morningMinute);

      // Get weekly report day
      _weeklyReportDay = prefs.getInt(NotificationService.weeklyReportDayKey) ?? DateTime.sunday;
    });
  }

  void _showTimePicker(bool isEvening) {
    final currentTime = isEvening ? _eveningReminderTime : _morningRecapTime;
    final title = isEvening ? 'Evening Reminder Time' : 'Morning Recap Time';

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Text(
                      isEvening ? '🌙' : '☀️',
                      style: const TextStyle(fontSize: 20, decoration: TextDecoration.none,),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                color: const Color(0xFF2C2C2C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (isEvening) {
                          _notificationService.setEveningReminderTime(_eveningReminderTime);
                        } else {
                          _notificationService.setMorningRecapTime(_morningRecapTime);
                        }
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
                      currentTime.hour,
                      currentTime.minute
                  ),
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() {
                      if (isEvening) {
                        _eveningReminderTime = TimeOfDay(
                            hour: newTime.hour,
                            minute: newTime.minute
                        );
                      } else {
                        _morningRecapTime = TimeOfDay(
                            hour: newTime.hour,
                            minute: newTime.minute
                        );
                      }
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
          height: 300,
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondaryColor.withOpacity(0.3),
                      AppTheme.primaryColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Text('📊', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                    SizedBox(width: 8),
                    Text(
                      'Weekly Summary Day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 44,
                color: const Color(0xFF2C2C2C),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
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
                      style: const TextStyle(color: Colors.white, decoration: TextDecoration.none,),
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
    return day - 1;
  }

  int _indexToDay(int index) {
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
                          decoration: TextDecoration.none,
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
                  const SizedBox(height: 8),
                  Text(
                    _allNotificationsEnabled
                        ? 'BoozeBuddy will send you helpful reminders and insights about your drinking patterns.'
                        : 'Turn on notifications to get timely reminders and insights.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFAAAAAA),
                      decoration: TextDecoration.none,
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
                          child: const Text('🌙', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Evening Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
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
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_eveningReminderEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _showTimePicker(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.dividerColor),
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
                                style: TextStyle(color: Colors.white, decoration: TextDecoration.none,),
                              ),
                              const Spacer(),
                              Text(
                                _eveningReminderTime.format(context),
                                style: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
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

              // NEW: Morning Recap Settings
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F43).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('☀️', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Morning Recap',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _morningRecapEnabled,
                          activeColor: const Color(0xFFFF9F43),
                          onChanged: (value) {
                            setState(() {
                              _morningRecapEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.morningRecapEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Morning check-in to add any drinks you forgot to log yesterday. Great for catching up!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (_morningRecapEnabled) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _showTimePicker(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.sun_max,
                                color: Color(0xFFFF9F43),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Morning Time:',
                                style: TextStyle(color: Colors.white, decoration: TextDecoration.none,),
                              ),
                              const Spacer(),
                              Text(
                                _morningRecapTime.format(context),
                                style: const TextStyle(
                                  color: Color(0xFFFF9F43),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
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
                          child: const Text('📊', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Weekly Stats Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
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
                        decoration: TextDecoration.none,
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
                            border: Border.all(color: AppTheme.dividerColor),
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
                                style: TextStyle(color: Colors.white, decoration: TextDecoration.none,),
                              ),
                              const Spacer(),
                              Text(
                                _dayNames[_dayToIndex(_weeklyReportDay)],
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
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

              // Streak Reminders
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
                          child: const Text('🔥', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tracking Streak Reminders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _streakReminderEnabled,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _streakReminderEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.streakReminderEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get reminders to keep your tracking streak alive when you\'re on a roll.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Weekend Check-ins
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🎉', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Weekend Check-ins',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _weekendCheckInEnabled,
                          activeColor: const Color(0xFF9C27B0),
                          onChanged: (value) {
                            setState(() {
                              _weekendCheckInEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.weekendCheckInEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Friday evening reminders to be mindful during weekend social activities.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Milestones & Achievements
              FunCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🏆', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Milestones & Achievements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _milestoneEnabled,
                          activeColor: const Color(0xFFFF5722),
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
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sober Day Encouragement
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
                          child: const Text('💚', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Sober Day Encouragement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _soberDayEncouragementEnabled,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _soberDayEncouragementEnabled = value;
                            });
                            _notificationService.toggleNotificationType(
                                NotificationService.soberDayEncouragementEnabledKey,
                                value
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Positive reinforcement when you have alcohol-free days. Building healthy habits!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFAAAAAA),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Test Section
              // FunCard(
              //   color: const Color(0xFF2D5AA0).withOpacity(0.1),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Row(
              //         children: [
              //           Icon(
              //             CupertinoIcons.lab_flask,
              //             color: Color(0xFF64B5F6),
              //             size: 20,
              //           ),
              //           SizedBox(width: 8),
              //           Text(
              //             'Test Notifications',
              //             style: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //               color: Color(0xFF64B5F6),
              //               decoration: TextDecoration.none,
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 12),
              //       Text(
              //         'Test your notification settings to make sure everything is working correctly.',
              //         style: TextStyle(
              //           fontSize: 14,
              //           color: Colors.grey[300],
              //         ),
              //       ),
              //       const SizedBox(height: 16),
              //
              //       // Test buttons row
              //       Row(
              //         children: [
              //           Expanded(
              //             child: CupertinoButton(
              //               padding: EdgeInsets.zero,
              //               onPressed: () async {
              //                 await _notificationService.sendTestNotification();
              //                 if (mounted) {
              //                   ScaffoldMessenger.of(context).showSnackBar(
              //                     SnackBar(
              //                       content: const Text('Test notification sent! On iOS, background the app to see it.'),
              //                       duration: const Duration(seconds: 4),
              //                       behavior: SnackBarBehavior.floating,
              //                       action: SnackBarAction(
              //                         label: 'Background App',
              //                         onPressed: () {
              //                           // This will minimize the app on iOS
              //                           // User can then see the notification
              //                         },
              //                       ),
              //                     ),
              //                   );
              //                 }
              //               },
              //               child: Container(
              //                 padding: const EdgeInsets.symmetric(vertical: 12),
              //                 decoration: BoxDecoration(
              //                   color: const Color(0xFF64B5F6).withOpacity(0.2),
              //                   borderRadius: BorderRadius.circular(8),
              //                   border: Border.all(
              //                     color: const Color(0xFF64B5F6).withOpacity(0.3),
              //                   ),
              //                 ),
              //                 child: const Row(
              //                   mainAxisAlignment: MainAxisAlignment.center,
              //                   children: [
              //                     Text('⚡', style: TextStyle(fontSize: 16)),
              //                     SizedBox(width: 6),
              //                     Text(
              //                       'Instant Test',
              //                       style: TextStyle(
              //                         color: Color(0xFF64B5F6),
              //                         fontWeight: FontWeight.w600,
              //                       ),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //             ),
              //           ),
              //           const SizedBox(width: 12),
              //           Expanded(
              //             child: CupertinoButton(
              //               padding: EdgeInsets.zero,
              //               onPressed: () async {
              //                 await _notificationService.sendTestScheduledNotification();
              //                 if (mounted) {
              //                   ScaffoldMessenger.of(context).showSnackBar(
              //                     const SnackBar(
              //                       content: Text('Scheduled test notification in 5 seconds!'),
              //                       duration: Duration(seconds: 4),
              //                       behavior: SnackBarBehavior.floating,
              //                     ),
              //                   );
              //                 }
              //               },
              //               child: Container(
              //                 padding: const EdgeInsets.symmetric(vertical: 12),
              //                 decoration: BoxDecoration(
              //                   color: const Color(0xFFFF9F43).withOpacity(0.2),
              //                   borderRadius: BorderRadius.circular(8),
              //                   border: Border.all(
              //                     color: const Color(0xFFFF9F43).withOpacity(0.3),
              //                   ),
              //                 ),
              //                 child: const Row(
              //                   mainAxisAlignment: MainAxisAlignment.center,
              //                   children: [
              //                     Text('🕐', style: TextStyle(fontSize: 16)),
              //                     SizedBox(width: 6),
              //                     Text(
              //                       'Scheduled Test',
              //                       style: TextStyle(
              //                         color: Color(0xFFFF9F43),
              //                         fontWeight: FontWeight.w600,
              //                       ),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //
              //       const SizedBox(height: 12),
              //
              //       // Milestone test button
              //       CupertinoButton(
              //         padding: EdgeInsets.zero,
              //         onPressed: () async {
              //           await _notificationService.sendMilestoneNotification('drinks_count', 25);
              //           if (mounted) {
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Text('Test milestone notification sent!'),
              //                 duration: Duration(seconds: 2),
              //                 behavior: SnackBarBehavior.floating,
              //               ),
              //             );
              //           }
              //         },
              //         child: Container(
              //           width: double.infinity,
              //           padding: const EdgeInsets.symmetric(vertical: 12),
              //           decoration: BoxDecoration(
              //             color: const Color(0xFF4CAF50).withOpacity(0.2),
              //             borderRadius: BorderRadius.circular(8),
              //             border: Border.all(
              //               color: const Color(0xFF4CAF50).withOpacity(0.3),
              //             ),
              //           ),
              //           child: const Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               Text('🏆', style: TextStyle(fontSize: 16)),
              //               SizedBox(width: 6),
              //               Text(
              //                 'Test Milestone Notification',
              //                 style: TextStyle(
              //                   color: Color(0xFF4CAF50),
              //                   fontWeight: FontWeight.w600,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 24),

              // Helpful tip
              FunCard(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.lightbulb,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart notifications adapt to your habits. The more you track, the more personalized and helpful they become!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}