// // lib/services/notification_service.dart
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:flutter_native_timezone/flutter_native_timezone.dart';
//
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   // Notification channels
//   static const String eveningReminderChannelKey = 'evening_reminder_channel';
//   static const String weeklyStatsChannelKey = 'weekly_stats_channel';
//   static const String milestoneChannelKey = 'milestone_channel';
//
//   // Notification IDs
//   static const int eveningReminderId = 1;
//   static const int weeklySummaryId = 2;
//   static const int milestoneId = 3;
//
//   // Settings keys - keeping the same as your current implementation
//   static const String enabledKey = 'notifications_enabled';
//   static const String eveningReminderEnabledKey = 'evening_reminder_enabled';
//   static const String weeklySummaryEnabledKey = 'weekly_summary_enabled';
//   static const String milestoneEnabledKey = 'milestone_enabled';
//   static const String reminderTimeKey = 'reminder_time';
//   static const String weeklyReportDayKey = 'weekly_report_day';
//
//   // Initialize notifications
//   Future<void> init() async {
//     tz.initializeTimeZones();
//     final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
//     tz.setLocalLocation(tz.getLocation(timeZoneName));
//
//     await AwesomeNotifications().initialize(
//       null, // no app icon - will use app launcher icon
//       [
//         NotificationChannel(
//           channelKey: eveningReminderChannelKey,
//           channelName: 'Evening Reminders',
//           channelDescription: 'Evening reminders to log drinks',
//           defaultColor: const Color(0xFF7E57C2), // AppTheme.primaryColor
//           importance: NotificationImportance.High,
//           // Note: If soundSource doesn't work, you may need to modify this line
//           // soundSource: 'resource://raw/notification_sound',
//           channelShowBadge: true,
//         ),
//         NotificationChannel(
//           channelKey: weeklyStatsChannelKey,
//           channelName: 'Weekly Summaries',
//           channelDescription: 'Weekly summaries of drinking patterns',
//           defaultColor: const Color(0xFF7E57C2), // AppTheme.primaryColor
//           importance: NotificationImportance.High,
//           channelShowBadge: true,
//         ),
//         NotificationChannel(
//           channelKey: milestoneChannelKey,
//           channelName: 'Milestone Celebrations',
//           channelDescription: 'Notifications for user milestones',
//           defaultColor: const Color(0xFFFF9F43), // AppTheme.secondaryColor
//           importance: NotificationImportance.High,
//           channelShowBadge: true,
//         ),
//       ],
//     );
//
//     // Request permission - this works better in iOS
//     await requestPermissions();
//
//     // Set initial settings
//     await _initDefaultSettings();
//   }
//
//   // Request notification permissions
//   Future<bool> requestPermissions() async {
//     return await AwesomeNotifications().requestPermissionToSendNotifications();
//   }
//
//   // Set default notification settings if first launch
//   Future<void> _initDefaultSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     final initialized = prefs.getBool('notification_settings_initialized') ?? false;
//
//     if (!initialized) {
//       // Set defaults
//       await prefs.setBool(enabledKey, true);
//       await prefs.setBool(eveningReminderEnabledKey, true);
//       await prefs.setBool(weeklySummaryEnabledKey, true);
//       await prefs.setBool(milestoneEnabledKey, true);
//       await prefs.setString(reminderTimeKey, '21:30'); // 9:30 PM
//       await prefs.setInt(weeklyReportDayKey, DateTime.sunday); // Sunday
//
//       // Mark as initialized
//       await prefs.setBool('notification_settings_initialized', true);
//     }
//   }
//
//   // Schedule evening reminder to log drinks
//   Future<void> scheduleEveningReminder() async {
//     final prefs = await SharedPreferences.getInstance();
//     final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
//     final reminderEnabled = prefs.getBool(eveningReminderEnabledKey) ?? true;
//
//     if (!notificationsEnabled || !reminderEnabled) return;
//
//     // Cancel existing schedule
//     await AwesomeNotifications().cancelSchedule(eveningReminderId);
//
//     // Get user's preferred reminder time (default 9:30 PM)
//     final reminderTimeString = prefs.getString(reminderTimeKey) ?? '21:30';
//     final timeParts = reminderTimeString.split(':');
//     final hour = int.parse(timeParts[0]);
//     final minute = int.parse(timeParts[1]);
//
//     // Randomize friendly messages for variety
//     final List<String> reminderMessages = [
//       "Out tonight? Don't forget to log your drinks on BoozeBuddy 🍻",
//       "Hey there! Remember to track tonight's drinks before bed 🍹",
//       "Track your drinks now for better insights tomorrow 📊",
//       "Keep your streak going! Log your drinks for today 🔥",
//       "Quick reminder to log today's drinks before calling it a night 🌙"
//     ];
//
//     final random = DateTime.now().millisecond % reminderMessages.length;
//
//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: eveningReminderId,
//         channelKey: eveningReminderChannelKey,
//         title: 'BoozeBuddy Reminder',
//         body: reminderMessages[random],
//         notificationLayout: NotificationLayout.Default,
//         category: NotificationCategory.Reminder,
//       ),
//       schedule: NotificationCalendar(
//         hour: hour,
//         minute: minute,
//         second: 0,
//         repeats: true,
//       ),
//     );
//   }
//
//   // Schedule weekly summary notification
//   Future<void> scheduleWeeklySummary() async {
//     final prefs = await SharedPreferences.getInstance();
//     final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
//     final summaryEnabled = prefs.getBool(weeklySummaryEnabledKey) ?? true;
//
//     if (!notificationsEnabled || !summaryEnabled) return;
//
//     // Cancel existing schedule
//     await AwesomeNotifications().cancelSchedule(weeklySummaryId);
//
//     // Get user's preferred day (default Sunday)
//     final weeklyReportDay = prefs.getInt(weeklyReportDayKey) ?? DateTime.sunday;
//
//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: weeklySummaryId,
//         channelKey: weeklyStatsChannelKey,
//         title: 'Your Weekly Booze Stats 📊',
//         body: 'Curious about your drinking patterns? Check out your weekly insights!',
//         notificationLayout: NotificationLayout.Default,
//         category: NotificationCategory.Recommendation,
//       ),
//       schedule: NotificationCalendar(
//         weekday: weeklyReportDay,
//         hour: 10,
//         minute: 0,
//         second: 0,
//         repeats: true,
//       ),
//     );
//   }
//
//   // Send milestone celebration notification
//   Future<void> sendMilestoneNotification(String achievement, int count) async {
//     final prefs = await SharedPreferences.getInstance();
//     final notificationsEnabled = prefs.getBool(enabledKey) ?? true;
//     final milestoneEnabled = prefs.getBool(milestoneEnabledKey) ?? true;
//
//     if (!notificationsEnabled || !milestoneEnabled) return;
//
//     // Create engaging milestone messages
//     String title;
//     String body;
//
//     switch (achievement) {
//       case 'drinks_count':
//         title = 'Milestone Reached! 🎉';
//         body = 'You\'ve logged $count drinks in BoozeBuddy. Keep tracking for even better insights!';
//         break;
//       case 'consecutive_days':
//         title = 'Tracking Streak: $count Days! 🔥';
//         body = 'You\'ve been logging drinks for $count days in a row. That\'s impressive consistency!';
//         break;
//       case 'first_week':
//         title = 'First Week Complete! 🏆';
//         body = 'You\'ve completed your first week of tracking. Great start to your journey!';
//         break;
//       default:
//         title = 'New Achievement! 🌟';
//         body = 'You\'ve reached a new milestone in your tracking journey!';
//     }
//
//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: milestoneId,
//         channelKey: milestoneChannelKey,
//         title: title,
//         body: body,
//         notificationLayout: NotificationLayout.Default,
//         category: NotificationCategory.Social,
//       ),
//     );
//   }
//
//   // Toggle all notifications
//   Future<void> toggleNotifications(bool enabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(enabledKey, enabled);
//
//     if (enabled) {
//       // Re-schedule all notifications
//       await scheduleEveningReminder();
//       await scheduleWeeklySummary();
//     } else {
//       // Cancel all notifications
//       await AwesomeNotifications().cancelAllSchedules();
//     }
//   }
//
//   // Set evening reminder time
//   Future<void> setEveningReminderTime(TimeOfDay time) async {
//     final prefs = await SharedPreferences.getInstance();
//     final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//     await prefs.setString(reminderTimeKey, timeString);
//
//     // Reschedule reminder with new time
//     await scheduleEveningReminder();
//   }
//
//   // Toggle specific notification type
//   Future<void> toggleNotificationType(String key, bool enabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(key, enabled);
//
//     // Reschedule notifications based on type
//     if (key == eveningReminderEnabledKey) {
//       if (enabled) {
//         await scheduleEveningReminder();
//       } else {
//         await AwesomeNotifications().cancelSchedule(eveningReminderId);
//       }
//     } else if (key == weeklySummaryEnabledKey) {
//       if (enabled) {
//         await scheduleWeeklySummary();
//       } else {
//         await AwesomeNotifications().cancelSchedule(weeklySummaryId);
//       }
//     }
//   }
//
//   // Set weekly report day
//   Future<void> setWeeklyReportDay(int day) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(weeklyReportDayKey, day);
//
//     // Reschedule weekly report
//     await scheduleWeeklySummary();
//   }
//
//   // Test function to send an immediate notification for debugging
//   Future<bool> sendTestNotification() async {
//     try {
//       await AwesomeNotifications().createNotification(
//         content: NotificationContent(
//           id: 999,
//           channelKey: eveningReminderChannelKey,
//           title: 'BoozeBuddy Test Notification',
//           body: 'If you can see this, notifications are working correctly!',
//           notificationLayout: NotificationLayout.Default,
//         ),
//       );
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   // Get the notification permission status
//   Future<String> getPermissionStatus() async {
//     final status = await AwesomeNotifications().checkPermissionList();
//
//     // Fix the error by using the string key instead of enum
//     if (status[NotificationPermission.Alert.index] == true) {
//       return 'Granted';
//     } else {
//       return 'Denied';
//     }
//   }
// }