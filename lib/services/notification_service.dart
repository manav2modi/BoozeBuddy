// lib/services/notification_service.dart - iOS-optimized version
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final StorageService _storageService = StorageService();

  // Notification IDs
  static const int eveningReminderId = 1;
  static const int morningRecapId = 2;
  static const int weeklySummaryId = 3;
  static const int milestoneId = 4;
  static const int streakReminderId = 5;
  static const int weekendCheckInId = 6;
  static const int hydrationReminderId = 7;
  static const int soberDayEncouragementId = 8;

  // Notification settings keys
  static const String enabledKey = 'notifications_enabled';
  static const String eveningReminderEnabledKey = 'evening_reminder_enabled';
  static const String morningRecapEnabledKey = 'morning_recap_enabled';
  static const String weeklySummaryEnabledKey = 'weekly_summary_enabled';
  static const String milestoneEnabledKey = 'milestone_enabled';
  static const String streakReminderEnabledKey = 'streak_reminder_enabled';
  static const String weekendCheckInEnabledKey = 'weekend_checkin_enabled';
  static const String hydrationReminderEnabledKey = 'hydration_reminder_enabled';
  static const String soberDayEncouragementEnabledKey = 'sober_day_encouragement_enabled';

  static const String eveningReminderTimeKey = 'evening_reminder_time';
  static const String morningRecapTimeKey = 'morning_recap_time';
  static const String weeklyReportDayKey = 'weekly_report_day';

  bool _iosPermissionsGranted = false;

  // Initialize the notification system with proper iOS handling
  Future<void> init() async {
    print('🔧 Initializing NotificationService...');

    try {
      // Initialize timezone handling for scheduled notifications
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('✅ Timezone initialized: $timeZoneName');

      // Initialize platform-specific settings
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // ENHANCED iOS settings - this is crucial for iOS notifications
      const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
        // These settings help with foreground notifications
        notificationCategories: [],
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      print('Plugin initialized: $initialized');

      // CRITICAL: Request iOS permissions explicitly and check result
      await _requestIOSPermissions();

      // Set default settings if first launch
      await _initDefaultSettings();

      // Only schedule notifications if permissions are granted
      if (_iosPermissionsGranted) {
        await _scheduleAllNotifications();
        print('✅ All notifications scheduled');
      } else {
        print('❌ iOS permissions not granted - notifications will not work');
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  // ENHANCED: Proper iOS permission handling
  Future<void> _requestIOSPermissions() async {
    final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iOSPlugin != null) {
      print('📱 Requesting iOS notification permissions...');

      // Request permissions
      final bool? result = await iOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: false, // Don't request critical unless needed
      );

      _iosPermissionsGranted = result ?? false;
      print('iOS permissions result: $result');

      if (!_iosPermissionsGranted) {
        print('⚠️  iOS notification permissions denied');
        // You might want to show a dialog explaining why notifications are useful
      } else {
        print('✅ iOS notification permissions granted');
      }
    } else {
      // Android or other platform
      _iosPermissionsGranted = true;
      print('✅ Non-iOS platform - permissions assumed granted');
    }
  }

  // NEW: Check if notifications are actually enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final appEnabled = prefs.getBool(enabledKey) ?? true;

    // For iOS, also check if system permissions are granted
    return appEnabled && _iosPermissionsGranted;
  }

  // ENHANCED: Background notification handler
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    print('Background notification response: ${response.payload}');
    // Handle background notification taps here
  }

  // Set default notification settings
  Future<void> _initDefaultSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool('notification_settings_initialized') ?? false;

    if (!initialized) {
      // Set defaults
      await prefs.setBool(enabledKey, true);
      await prefs.setBool(eveningReminderEnabledKey, true);
      await prefs.setBool(morningRecapEnabledKey, true);
      await prefs.setBool(weeklySummaryEnabledKey, true);
      await prefs.setBool(milestoneEnabledKey, true);
      await prefs.setBool(streakReminderEnabledKey, true);
      await prefs.setBool(weekendCheckInEnabledKey, true);
      await prefs.setBool(hydrationReminderEnabledKey, true);
      await prefs.setBool(soberDayEncouragementEnabledKey, true);

      await prefs.setString(eveningReminderTimeKey, '21:30'); // 9:30 PM
      await prefs.setString(morningRecapTimeKey, '11:00'); // 11:00 AM
      await prefs.setInt(weeklyReportDayKey, DateTime.sunday); // Sunday

      // Mark as initialized
      await prefs.setBool('notification_settings_initialized', true);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('Notification payload: ${response.payload}');
    // Handle notification tap based on payload
  }

  // Schedule all enabled notifications with permission check
  Future<void> _scheduleAllNotifications() async {
    if (!await areNotificationsEnabled()) {
      print('❌ Cannot schedule notifications - not enabled or no permissions');
      return;
    }

    print('📅 Scheduling all notifications...');
    await scheduleEveningReminder();
    await scheduleMorningRecap();
    await scheduleWeeklySummary();
    await scheduleWeekendCheckIn();
    await scheduleStreakReminder();
  }

  // ENHANCED: Evening reminder with better iOS compatibility
  Future<void> scheduleEveningReminder() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final reminderEnabled = prefs.getBool(eveningReminderEnabledKey) ?? true;

    if (!reminderEnabled) return;

    try {
      // Get user's preferred reminder time (default 9:30 PM)
      final reminderTimeString = prefs.getString(eveningReminderTimeKey) ?? '21:30';
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

      // Enhanced evening messages
      final List<String> weekdayMessages = [
        "Quick check-in! Log today's drinks before bed 🌙",
        "End your day right - track your drinks in BoozeBuddy 📝",
        "Don't forget to log today's drinks! Your future self will thank you 🍻",
        "Time to wrap up the day - add any drinks you had today 📊",
        "Keep your streak going! Log today's drinks before sleeping 🔥"
      ];

      final List<String> weekendMessages = [
        "Weekend vibes! Don't forget to log tonight's drinks 🎉",
        "Out and about? Quick reminder to track your drinks 🍹",
        "Weekend check-in: Log your drinks to keep track 🥳",
        "Having fun? Remember to log your drinks in BoozeBuddy 🍻",
        "Weekend tracking time! Add today's drinks before bed 🌙"
      ];

      final isWeekend = now.weekday >= 6;
      final messages = isWeekend ? weekendMessages : weekdayMessages;
      final random = DateTime.now().millisecond % messages.length;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        eveningReminderId,
        'BoozeBuddy Evening Check-in',
        messages[random],
        scheduledTime,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'evening_reminder_channel',
            'Evening Reminders',
            channelDescription: 'Evening reminders to log drinks',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFF7E57C2),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            // IMPORTANT: These settings help with iOS delivery
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'reminder_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'home',
      );

      print('✅ Evening reminder scheduled for ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling evening reminder: $e');
    }
  }

  // ENHANCED: Morning recap with better iOS compatibility
  Future<void> scheduleMorningRecap() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final morningRecapEnabled = prefs.getBool(morningRecapEnabledKey) ?? true;

    if (!morningRecapEnabled) return;

    try {
      // Get user's preferred morning time (default 11:00 AM)
      final morningTimeString = prefs.getString(morningRecapTimeKey) ?? '11:00';
      final timeParts = morningTimeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create schedule time for tomorrow morning
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Always schedule for next occurrence
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Cancel any existing morning recap
      await flutterLocalNotificationsPlugin.cancel(morningRecapId);

      // Check if user logged drinks yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDrinks = await _storageService.getDrinksForDate(yesterday);

      String message;
      if (yesterdayDrinks.isEmpty) {
        final dayOfWeek = DateFormat('EEEE').format(yesterday);
        message = "Did you have any drinks yesterday ($dayOfWeek)? Add them now if you forgot to log them! 📝";
      } else {
        final totalDrinks = yesterdayDrinks.fold<double>(0, (sum, drink) => sum + drink.standardDrinks);
        message = "Yesterday's recap: ${totalDrinks.toStringAsFixed(1)} drinks logged. How are you feeling today? 🌅";
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        morningRecapId,
        'Good morning! ☀️',
        message,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'morning_recap_channel',
            'Morning Recap',
            channelDescription: 'Morning recap and catch-up reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFFFF9F43),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'morning_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'home',
      );

      print('✅ Morning recap scheduled for ${scheduledTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling morning recap: $e');
    }
  }

  // Enhanced weekly summary notification
  Future<void> scheduleWeeklySummary() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final summaryEnabled = prefs.getBool(weeklySummaryEnabledKey) ?? true;

    if (!summaryEnabled) return;

    try {
      final weeklyReportDay = prefs.getInt(weeklyReportDayKey) ?? DateTime.sunday;
      final scheduledDate = _nextInstanceOfDay(weeklyReportDay, 10, 0);

      await flutterLocalNotificationsPlugin.cancel(weeklySummaryId);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        weeklySummaryId,
        'Your Weekly Drinking Insights 📊',
        'Time for your weekly wrap-up! See how your drinking patterns looked this week and get personalized insights.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_summary_channel',
            'Weekly Summaries',
            channelDescription: 'Weekly summaries of drinking patterns',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'stats_icon',
            channelShowBadge: true,
            color: Color(0xFF7E57C2),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'weekly_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'stats',
      );

      print('✅ Weekly summary scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      print('❌ Error scheduling weekly summary: $e');
    }
  }

  // Weekend check-in notification
  Future<void> scheduleWeekendCheckIn() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final weekendCheckInEnabled = prefs.getBool(weekendCheckInEnabledKey) ?? true;

    if (!weekendCheckInEnabled) return;

    try {
      // Schedule for Friday evening (start of weekend)
      final fridayEvening = _nextInstanceOfDay(DateTime.friday, 18, 0); // 6 PM Friday

      await flutterLocalNotificationsPlugin.cancel(weekendCheckInId);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        weekendCheckInId,
        'Weekend Plans? 🎉',
        'The weekend is here! If you\'re planning to drink, remember to track it in BoozeBuddy for better insights.',
        fridayEvening,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekend_checkin_channel',
            'Weekend Check-ins',
            channelDescription: 'Weekend planning and awareness reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFFFF9F43),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'weekend_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'home',
      );

      print('✅ Weekend check-in scheduled for ${fridayEvening.toString()}');
    } catch (e) {
      print('❌ Error scheduling weekend check-in: $e');
    }
  }

  // Streak reminder notification
  Future<void> scheduleStreakReminder() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final streakReminderEnabled = prefs.getBool(streakReminderEnabledKey) ?? true;

    if (!streakReminderEnabled) return;

    try {
      // Check user's tracking streak
      final trackingDays = await _calculateTrackingStreak();

      if (trackingDays >= 3) {
        // Schedule reminder to keep streak going
        final now = tz.TZDateTime.now(tz.local);
        final tomorrowEvening = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          20, // 8 PM
          0,
        );

        await flutterLocalNotificationsPlugin.zonedSchedule(
          streakReminderId,
          'Keep Your Streak Going! 🔥',
          'You\'ve been tracking for $trackingDays days in a row! Don\'t break the streak - log today\'s drinks.',
          tomorrowEvening,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'streak_reminder_channel',
              'Streak Reminders',
              channelDescription: 'Reminders to maintain tracking streaks',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              channelShowBadge: true,
              color: Color(0xFF4CAF50),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.active,
              categoryIdentifier: 'streak_category',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'home',
        );

        print('✅ Streak reminder scheduled for ${tomorrowEvening.toString()}');
      }
    } catch (e) {
      print('❌ Error scheduling streak reminder: $e');
    }
  }

  // ENHANCED: Better milestone notifications
  Future<void> sendMilestoneNotification(String achievement, int count) async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final milestoneEnabled = prefs.getBool(milestoneEnabledKey) ?? true;

    if (!milestoneEnabled) return;

    String title;
    String body;

    switch (achievement) {
      case 'drinks_count':
        if (count == 10) {
          title = 'First 10 Drinks Logged! 🎉';
          body = 'You\'ve successfully tracked your first 10 drinks. Great start to building healthy awareness!';
        } else if (count == 50) {
          title = '50 Drinks Tracked! 📊';
          body = 'Half a century of drinks logged! You\'re building great tracking habits.';
        } else if (count == 100) {
          title = '100 Drinks Milestone! 🏆';
          body = 'Wow! You\'ve logged 100 drinks. Your dedication to tracking is impressive!';
        } else {
          title = 'Milestone Reached! 🌟';
          body = 'You\'ve logged $count drinks in BoozeBuddy. Keep up the great tracking!';
        }
        break;
      case 'tracking_streak':
        title = '$count Day Tracking Streak! 🔥';
        body = 'Amazing! You\'ve consistently tracked your drinks for $count days in a row. That\'s dedication!';
        break;
      case 'first_week':
        title = 'One Week of Tracking! 📅';
        body = 'Congratulations! You\'ve completed your first week of drink tracking. You\'re building a great habit!';
        break;
      case 'sober_days':
        title = '$count Sober Days This Month! 💚';
        body = 'Well done! You\'ve had $count alcohol-free days this month. Taking care of your health!';
        break;
      case 'moderate_week':
        title = 'Moderate Week Achieved! 👍';
        body = 'Great job! You kept your drinking within recommended guidelines this week.';
        break;
      default:
        title = 'Achievement Unlocked! 🌟';
        body = 'You\'ve reached a new milestone in your tracking journey!';
    }

    try {
      await flutterLocalNotificationsPlugin.show(
        milestoneId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestone_channel',
            'Milestone Celebrations',
            channelDescription: 'Notifications for user milestones and achievements',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'achievement_icon',
            channelShowBadge: true,
            color: Color(0xFF4CAF50),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'milestone_category',
          ),
        ),
        payload: 'stats',
      );

      print('✅ Milestone notification sent: $title');
    } catch (e) {
      print('❌ Error sending milestone notification: $e');
    }
  }

  // Send sober day encouragement
  Future<void> sendSoberDayEncouragement() async {
    if (!await areNotificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final soberDayEnabled = prefs.getBool(soberDayEncouragementEnabledKey) ?? true;

    if (!soberDayEnabled) return;

    final encouragementMessages = [
      "Great choice staying sober today! Your body is thanking you 💚",
      "Alcohol-free day achieved! You're taking great care of yourself 🌟",
      "Sober and strong today! Keep up the healthy choices 💪",
      "Zero drinks today = 100% taking care of yourself! 👏",
      "Another sober day in the books! Your future self will thank you 🙏"
    ];

    final random = DateTime.now().millisecond % encouragementMessages.length;

    try {
      await flutterLocalNotificationsPlugin.show(
        soberDayEncouragementId,
        'Sober Day Champion! 🏆',
        encouragementMessages[random],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sober_encouragement_channel',
            'Sober Day Encouragement',
            channelDescription: 'Positive reinforcement for alcohol-free days',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFF4CAF50),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'sober_category',
          ),
        ),
        payload: 'stats',
      );

      print('✅ Sober day encouragement sent');
    } catch (e) {
      print('❌ Error sending sober day encouragement: $e');
    }
  }

  // Helper method to calculate tracking streak
  Future<int> _calculateTrackingStreak() async {
    try {
      final drinks = await _storageService.getDrinks();
      if (drinks.isEmpty) return 0;

      final now = DateTime.now();
      int streak = 0;

      // Check each day going backwards from today
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dayDrinks = drinks.where((drink) =>
        drink.timestamp.year == checkDate.year &&
            drink.timestamp.month == checkDate.month &&
            drink.timestamp.day == checkDate.day
        ).toList();

        if (dayDrinks.isNotEmpty) {
          streak++;
        } else {
          break; // Streak broken
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
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

    if (enabled && _iosPermissionsGranted) {
      await _scheduleAllNotifications();
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
    }
  }

  // Set evening reminder time
  Future<void> setEveningReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(eveningReminderTimeKey, timeString);
    await scheduleEveningReminder();
  }

  // Set morning recap time
  Future<void> setMorningRecapTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(morningRecapTimeKey, timeString);
    await scheduleMorningRecap();
  }

  // Toggle specific notification type
  Future<void> toggleNotificationType(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, enabled);

    if (!await areNotificationsEnabled()) return;

    // Reschedule relevant notifications
    switch (key) {
      case eveningReminderEnabledKey:
        if (enabled) {
          await scheduleEveningReminder();
        } else {
          await flutterLocalNotificationsPlugin.cancel(eveningReminderId);
        }
        break;
      case morningRecapEnabledKey:
        if (enabled) {
          await scheduleMorningRecap();
        } else {
          await flutterLocalNotificationsPlugin.cancel(morningRecapId);
        }
        break;
      case weeklySummaryEnabledKey:
        if (enabled) {
          await scheduleWeeklySummary();
        } else {
          await flutterLocalNotificationsPlugin.cancel(weeklySummaryId);
        }
        break;
      case weekendCheckInEnabledKey:
        if (enabled) {
          await scheduleWeekendCheckIn();
        } else {
          await flutterLocalNotificationsPlugin.cancel(weekendCheckInId);
        }
        break;
      case streakReminderEnabledKey:
        if (enabled) {
          await scheduleStreakReminder();
        } else {
          await flutterLocalNotificationsPlugin.cancel(streakReminderId);
        }
        break;
    }
  }

  // Set weekly report day
  Future<void> setWeeklyReportDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(weeklyReportDayKey, day);
    await scheduleWeeklySummary();
  }

  // ENHANCED: Test notification with better iOS handling
  Future<void> sendTestNotification() async {
    try {
      print('🧪 Testing notification - checking permissions...');

      // First check if notifications are enabled
      if (!await areNotificationsEnabled()) {
        print('❌ Notifications not enabled or no permissions');
        return;
      }

      final testMessages = [
        "🧪 Test notification working perfectly!",
        "🍻 BoozeBuddy notifications are ready to go!",
        "📱 Your notification system is set up correctly!",
        "🎉 Test successful! All systems go!",
        "⚡ Notification test complete - looking good!"
      ];

      final random = DateTime.now().millisecond % testMessages.length;

      print('📱 Attempting to send test notification...');
      print('💡 Tip: On iOS, background the app or lock device to see notification');

      await flutterLocalNotificationsPlugin.show(
        999, // Use a special test ID
        'BoozeBuddy Test 🧪',
        testMessages[random],
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications for development',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFF7E57C2),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 1,
            // IMPORTANT: This helps with iOS notification delivery
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'test_category',
          ),
        ),
        payload: 'test',
      );

      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // Test scheduled notification (5 seconds from now)
  Future<void> sendTestScheduledNotification() async {
    try {
      print('🕐 Testing scheduled notification...');

      if (!await areNotificationsEnabled()) {
        print('❌ Notifications not enabled or no permissions');
        return;
      }

      // Schedule a notification 5 seconds from now
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 5));

      print('Scheduling notification for: $scheduledTime (current time: $now)');

      await flutterLocalNotificationsPlugin.zonedSchedule(
        998, // Special test scheduled ID
        'Scheduled Test 🕐',
        'This scheduled notification was sent 5 seconds after you tapped the button!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_scheduled_channel',
            'Test Scheduled Notifications',
            channelDescription: 'Test scheduled notifications for development',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'notification_icon',
            channelShowBadge: true,
            color: Color(0xFFFF9F43),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            badgeNumber: 2,
            interruptionLevel: InterruptionLevel.active,
            categoryIdentifier: 'test_scheduled_category',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test_scheduled',
      );

      print('✅ Scheduled notification set successfully');
    } catch (e) {
      print('❌ Error scheduling test notification: $e');
    }
  }

  // NEW: Show system settings for notifications (iOS specific)
  Future<void> openNotificationSettings() async {
    // This would require additional platform-specific code
    // For now, we can only show instructions to the user
    print('📱 User should go to iOS Settings > Notifications > BoozeBuddy');
  }

  // ENHANCED: Debug method with iOS-specific info
  Future<Map<String, dynamic>> getNotificationDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> debugInfo = {
      'app_notifications_enabled': prefs.getBool(enabledKey) ?? true,
      'evening_reminder_enabled': prefs.getBool(eveningReminderEnabledKey) ?? true,
      'morning_recap_enabled': prefs.getBool(morningRecapEnabledKey) ?? true,
      'ios_permissions_granted': _iosPermissionsGranted,
      'notifications_functional': await areNotificationsEnabled(),
      'platform': 'unknown',
    };

    try {
      // Check platform-specific permissions
      final IOSFlutterLocalNotificationsPlugin? iOSPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iOSPlugin != null) {
        debugInfo['platform'] = 'iOS';
        debugInfo['ios_specific_note'] = 'iOS notifications only show when app is backgrounded or device is locked';
      } else {
        debugInfo['platform'] = 'Android';
        debugInfo['android_note'] = 'Android notifications should work immediately';
      }

      // Check pending notifications
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugInfo['pending_notifications_count'] = pendingNotifications.length;
      debugInfo['pending_notifications'] = pendingNotifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
      }).toList();

      // Check timezone
      debugInfo['timezone'] = tz.local.name;
      debugInfo['current_time'] = tz.TZDateTime.now(tz.local).toString();

    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }

  // Cancel all test notifications
  Future<void> cancelTestNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(999); // Instant test
      await flutterLocalNotificationsPlugin.cancel(998); // Scheduled test
      print('✅ Test notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling test notifications: $e');
    }
  }

  // Check daily milestones
  Future<void> checkDailyMilestones() async {
    if (!await areNotificationsEnabled()) return;

    final now = DateTime.now();

    try {
      // Check if user had no drinks yesterday (sober day)
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDrinks = await _storageService.getDrinksForDate(yesterday);

      if (yesterdayDrinks.isEmpty) {
        // It was a sober day - encourage them
        await sendSoberDayEncouragement();
      }

      // Check tracking streak
      final streak = await _calculateTrackingStreak();
      if (streak > 0 && streak % 7 == 0) {
        // Weekly streak milestone
        await sendMilestoneNotification('tracking_streak', streak);
      }

      // Check total drinks milestone
      final allDrinks = await _storageService.getDrinks();
      final totalDrinks = allDrinks.length;
      if ([10, 25, 50, 100, 250, 500].contains(totalDrinks)) {
        await sendMilestoneNotification('drinks_count', totalDrinks);
      }
    } catch (e) {
      print('❌ Error checking daily milestones: $e');
    }
  }

  // NEW: Force reinitialize permissions (useful for troubleshooting)
  Future<void> reinitializePermissions() async {
    print('🔄 Reinitializing iOS permissions...');
    await _requestIOSPermissions();

    if (_iosPermissionsGranted) {
      await _scheduleAllNotifications();
      print('✅ Permissions reinitialized and notifications rescheduled');
    } else {
      print('❌ Permissions still not granted after reinitialization');
    }
  }
}