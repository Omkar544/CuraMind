// ✅ PROFESSIONAL NOTIFICATION SERVICE (ALERT ONLY - NO ALARM)

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // ==============================
  // INIT FUNCTION (Called in main.dart)
  // ==============================
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // ==============================
  // SCHEDULE NOTIFICATION
  // ==============================
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // 10 minutes before
    final DateTime reminderTime =
        scheduledDate.subtract(const Duration(minutes: 10));

    if (reminderTime.isBefore(DateTime.now())) {
      return; // Don't schedule past notifications
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_channel',
          'Appointment Reminders',
          channelDescription: 'Reminder before appointment',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
