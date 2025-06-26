// lib/screens/notification_settings_screen.dart - iOS-optimized version
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import '../widgets/common/fun_card.dart';
import 'dart:io' show Platform;

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
  bool _notificationsTroubleShoot = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    // Check if notifications are actually working
    final debugInfo = await _notificationService.getNotificationDebugInfo();
    setState(() {
      _debugInfo = debugInfo;
      _notificationsTroubleShoot = !(debugInfo['notifications_functional'] ?? false);
    });
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

  Widget _buildIOSTroubleshootingCard() {
    if (!Platform.isIOS || !_notificationsTroubleShoot) return const SizedBox.shrink();

    return FunCard(
      color: const Color(0xFFFF5722).withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: Color(0xFFFF5722),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'iOS Notification Issues Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5722),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Notifications may not be working properly on your device. Try these steps:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFAAAAAA),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Check iOS Settings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('1️⃣', style: TextStyle(fontSize: 16, decoration: TextDecoration.none,)),
                    SizedBox(width: 8),
                    Text(
                      'Check iOS Notification Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Go to: Settings > Notifications > BoozeBuddy\nEnsure "Allow Notifications" is ON',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Show instructions since we can't directly open settings
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Open iOS Settings'),
                        content: const Text(
                          'To enable notifications:\n\n'
                              '1. Close BoozeBuddy\n'
                              '2. Open Settings app\n'
                              '3. Scroll down to "BoozeBuddy"\n'
                              '4. Tap "Notifications"\n'
                              '5. Turn ON "Allow Notifications"\n'
                              '6. Return to BoozeBuddy',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Got it'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Show Instructions',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step 2: Test notifications
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('2️⃣', style: TextStyle(fontSize: 16, decoration: TextDecoration.none,)),
                    SizedBox(width: 8),
                    Text(
                      'Test Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Test if notifications work (remember to background the app after testing)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await _notificationService.sendTestNotification();
                          if (mounted) {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Test Sent! 📱'),
                                content: const Text(
                                  'Background the app now to see if the notification appears. '
                                      'On iOS, notifications only show when the app is backgrounded or device is locked.',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('⚡', style: TextStyle(fontSize: 14, decoration: TextDecoration.none,)),
                              SizedBox(width: 4),
                              Text(
                                'Test Now',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          await _notificationService.reinitializePermissions();
                          await _checkNotificationStatus();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Permissions reinitialized. Check if notifications work now.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F43).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🔄', style: TextStyle(fontSize: 14, decoration: TextDecoration.none,)),
                              SizedBox(width: 4),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  color: Color(0xFFFF9F43),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // iOS-specific tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.info,
                  color: Color(0xFF007AFF),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'iOS Only: Notifications appear when the app is backgrounded or your device is locked. They won\'t show when the app is in the foreground.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF007AFF),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.cardColor,
        middle: const Text('Notification Settings'),
        trailing: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // iOS Troubleshooting Card (only shows if there are issues)
            _buildIOSTroubleshootingCard(),

            if (_notificationsTroubleShoot) const SizedBox(height: 16),

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
                        onChanged: (value) async {
                          setState(() {
                            _allNotificationsEnabled = value;
                          });
                          await _notificationService.toggleNotifications(value);
                          await _checkNotificationStatus();
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

                  // Show status indicator
                  if (_debugInfo != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          (_debugInfo!['notifications_functional'] ?? false)
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          color: (_debugInfo!['notifications_functional'] ?? false)
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF5722),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (_debugInfo!['notifications_functional'] ?? false)
                              ? 'Notifications are working'
                              : 'Notifications may not work properly',
                          style: TextStyle(
                            fontSize: 12,
                            color: (_debugInfo!['notifications_functional'] ?? false)
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF5722),
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
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

              // Morning Recap Settings
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

              // Other notification cards would continue here...
              // (Weekly Summary, Streak Reminders, Weekend Check-ins, etc.)
              // I'll add a few key ones to show the pattern

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

              // Milestones & Achievements
              FunCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 20, decoration: TextDecoration.none,)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Milestones & Achievements',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Celebrate your progress with achievement notifications',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFAAAAAA),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
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
              ),

              const SizedBox(height: 24),

              // iOS-specific helpful tip
              if (Platform.isIOS) ...[
                FunCard(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            CupertinoIcons.device_phone_portrait,
                            color: Color(0xFF007AFF),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'iOS Notification Tip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007AFF),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'On iOS, notifications only appear when BoozeBuddy is backgrounded or your device is locked. This is how iOS protects your privacy and prevents apps from interrupting you while actively using them.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Android tip
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
          ],
        ),
      ),
    );
  }
}