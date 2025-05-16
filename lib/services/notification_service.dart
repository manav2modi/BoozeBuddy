// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Notification IDs and keys
  static const int eveningReminderId = 1;
  static const int weeklySummaryId = 2;
  static const int milestoneId = 3;
  static const int passportBadgeId = 4;

  // Notification settings keys
  static const String enabledKey = 'notifications_enabled';
  static const String eveningReminderEnabledKey = 'evening_reminder_enabled';
  static const String weeklySummaryEnabledKey = 'weekly_summary_enabled';
  static const String milestoneEnabledKey = 'milestone_enabled';
  static const String badgeEnabledKey = 'badge_enabled';
  static const String reminderTimeKey = 'reminder_time';
  static const String weeklyReportDayKey = 'weekly_report_day';

  // Initialize the notification system
  Future<void> init() async {
    // Initialize timezone handling for scheduled notifications
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Initialize platform-specific settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions for iOS
    // Using a different approach to avoid the generic type syntax issue
    final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iOSPlugin != null) {
      await iOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Set default settings if first launch
    await _initDefaultSettings();
  }

  // Set default notification settings
  Future<void> _initDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('notification_settings_initialized') ?? false;

    if (!initialized) {
      // Set defaults
      await prefs.setBool(enabledKey, true);
      await prefs.setBool(eveningReminderEnabledKey, true);
      await prefs.setBool(weeklySummaryEnabledKey, true);
      await prefs.setBool(milestoneEnabledKey, true);
      await prefs.setBool(badgeEnabledKey, true);
      await prefs.setString(reminderTimeKey, '21:30'); // 9:30 PM
      await prefs.setInt(weeklyReportDayKey, DateTime.sunday); // Sunday

      // Mark as initialized
      await prefs.setBool('notification_settings_initialized', true);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap based on payload
    print('Notification payload: ${response.payload}');
  }

  // Schedule evening reminder to log drinks (9-11pm, user configurable)
  Future<void> scheduleEveningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
    final reminderEnabled = prefs.getBool(eveningReminderEnabledKey) ?? true;

    if (!notificationsEnabled || !reminderEnabled) return;

    // Get user's preferred reminder time (default 9:30 PM)
    final reminderTimeString = prefs.getString(reminderTimeKey) ?? '22:00';
    final timeParts = reminderTimeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Create schedule time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time today has already passed, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // Cancel any existing reminder
    await flutterLocalNotificationsPlugin.cancel(eveningReminderId);

    // Randomize friendly messages for variety
    final List<String> reminderMessages = [
      "Out tonight? Don't forget to log your drinks on BoozeBuddy 🍻",
      "Hey there! Remember to track tonight's drinks before bed 🍹",
      "Track your drinks now for better insights tomorrow 📊",
      "Keep your streak going! Log your drinks for today 🔥",
      "Quick reminder to log today's drinks before calling it a night 🌙"
    ];

    final random = DateTime.now().millisecond % reminderMessages.length;

    // Schedule new reminder with simplified parameters
    await flutterLocalNotificationsPlugin.zonedSchedule(
      eveningReminderId,
      'BoozeBuddy Reminder',
      reminderMessages[random],
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_reminder_channel',
          'Evening Reminders',
          channelDescription: 'Evening reminders to log drinks',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          icon: 'notification_icon',
          channelShowBadge: true,
          color: Color(0xFF7E57C2), // AppTheme.primaryColor
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification_sound.aiff',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'home',
    );
  }

  // Schedule weekly summary notification
  Future<void> scheduleWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
    final summaryEnabled = prefs.getBool(weeklySummaryEnabledKey) ?? true;

    if (!notificationsEnabled || !summaryEnabled) return;

    // Get user's preferred day (default Sunday)
    final weeklyReportDay = prefs.getInt(weeklyReportDayKey) ?? DateTime.sunday;

    // Create schedule time (preferred day at 10:00 AM)
    final scheduledDate = _nextInstanceOfDay(weeklyReportDay, 10, 0);

    // Cancel any existing reminder
    await flutterLocalNotificationsPlugin.cancel(weeklySummaryId);

    // Schedule new reminder with simplified parameters
    await flutterLocalNotificationsPlugin.zonedSchedule(
      weeklySummaryId,
      'Your Weekly Booze Stats 📊',
      'Curious about your drinking patterns? Check out your weekly insights!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary_channel',
          'Weekly Summaries',
          channelDescription: 'Weekly summaries of drinking patterns',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'stats_icon',
          channelShowBadge: true,
          color: const Color(0xFF7E57C2), // AppTheme.primaryColor
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'stats',
    );
  }

  // Send milestone celebration notification
  Future<void> sendMilestoneNotification(String achievement, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
    final milestoneEnabled = prefs.getBool(milestoneEnabledKey) ?? true;

    if (!notificationsEnabled || !milestoneEnabled) return;

    // Create engaging milestone messages
    String title;
    String body;

    switch (achievement) {
      case 'drinks_count':
        title = 'Milestone Reached! 🎉';
        body = 'You\'ve logged $count drinks in BoozeBuddy. Keep tracking for even better insights!';
        break;
      case 'consecutive_days':
        title = 'Tracking Streak: $count Days! 🔥';
        body = 'You\'ve been logging drinks for $count days in a row. That\'s impressive consistency!';
        break;
      case 'first_week':
        title = 'First Week Complete! 🏆';
        body = 'You\'ve completed your first week of tracking. Great start to your journey!';
        break;
      default:
        title = 'New Achievement! 🌟';
        body = 'You\'ve reached a new milestone in your tracking journey!';
    }

    await flutterLocalNotificationsPlugin.show(
      milestoneId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'milestone_channel',
          'Milestone Celebrations',
          channelDescription: 'Notifications for user milestones',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('achievement_sound'),
          icon: 'achievement_icon',
          channelShowBadge: true,
          color: const Color(0xFFFF9F43), // AppTheme.secondaryColor
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'achievement_sound.aiff',
        ),
      ),
      payload: 'stats',
    );
  }

  // Send passport badge notification
  Future<void> sendPassportBadgeNotification(String badgeName) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
    final badgeEnabled = prefs.getBool(badgeEnabledKey) ?? true;

    if (!notificationsEnabled || !badgeEnabled) return;

    await flutterLocalNotificationsPlugin.show(
      passportBadgeId,
      '🎖️ New Badge Unlocked!',
      'You just earned the \'$badgeName\' badge! Check it out in your Passport.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'badge_channel',
          'Badge Notifications',
          channelDescription: 'Notifications for passport badges',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('badge_sound'),
          icon: 'badge_icon',
          channelShowBadge: true,
          color: const Color(0xFF64B5F6), // Blue
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'badge_sound.aiff',
        ),
      ),
      payload: 'passport',
    );
  }

  // Helper to get next instance of a specific day of week
  tz.TZDateTime _nextInstanceOfDay(int day, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Toggle all notifications
  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);

    if (enabled) {
      // Re-schedule all notifications
      await scheduleEveningReminder();
      await scheduleWeeklySummary();
    } else {
      // Cancel all notifications
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  // Set evening reminder time
  Future<void> setEveningReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(reminderTimeKey, timeString);

    // Reschedule reminder with new time
    await scheduleEveningReminder();
  }

  // Toggle specific notification type
  Future<void> toggleNotificationType(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);

    // Reschedule notifications based on type
    if (key == eveningReminderEnabledKey) {
      if (enabled) {
        await scheduleEveningReminder();
      } else {
        await flutterLocalNotificationsPlugin.cancel(eveningReminderId);
      }
    } else if (key == weeklySummaryEnabledKey) {
      if (enabled) {
        await scheduleWeeklySummary();
      } else {
        await flutterLocalNotificationsPlugin.cancel(weeklySummaryId);
      }
    }
  }

  // Set weekly report day
  Future<void> setWeeklyReportDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(weeklyReportDayKey, day);

    // Reschedule weekly report
    await scheduleWeeklySummary();
  }
}