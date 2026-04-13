import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

/// Service for scheduling outgoing "CareClock" alerts
class NotificationService {
  // Singleton pattern to ensure only one instance of the service exists
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification system, timezones, and handles Android 13+ permissions.
  Future<void> init() async {
    // 1. Initialize Timezones (Required for zonedSchedule)
    tz.initializeTimeZones();

    // 2. Android-specific initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Here you can handle what happens when a user taps the notification
        print("Notification tapped: ${details.payload}");
      },
    );

    // 3. Request permissions for Android 13 (API 33) and above
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedules a "Ringing" Alert at a specific time.
  /// Used for both one-time appointments and recurring medicine reminders.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String timeStr, // Expected Format: "10:30 PM"
    String? dateStr, // Expected Format: "2026-02-05" (Optional)
  }) async {
    try {
      DateTime now = DateTime.now();

      // Parse the Time string using intl
      DateFormat timeFormat = DateFormat.jm(); // Matches "10:30 PM"
      DateTime parsedTime = timeFormat.parse(timeStr);

      DateTime scheduledDate;
      if (dateStr != null) {
        // If a specific date is provided (e.g., Doctor Appointment)
        DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        scheduledDate = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedTime.hour,
          parsedTime.minute,
        );
      } else {
        // If no date is provided, assume it's a daily reminder (e.g., Pills)
        // If the time has already passed today, schedule for tomorrow
        scheduledDate = DateTime(
            now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }

      // Android Notification Channel Details
      // Set to Importance.max and fullScreenIntent: true to simulate an alarm
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'careclock_channel',
        'CareClock Alerts',
        channelDescription: 'High-priority notifications for health schedules',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      // Schedule the notification using the device's local timezone
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print(
          "🔔 CareClock: Notification Scheduled for ${scheduledDate.toString()}");
    } catch (e) {
      print("❌ Notification Service Error: $e");
    }
  }

  /// Cancels a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

/// Service for listening to incoming notifications (e.g., Syncing steps from StepsApp)
class NotificationSyncService {
  /// Reads steps directly from the StepsApp notification.
  /// Bypasses all Health Connect / Google Fit bugs.
  void startListening(Function(int) onStepsFound) {
    // Initialize the listener
    NotificationsListener.initialize();

    NotificationsListener.receivePort?.listen((evt) {
      // Logic for capturing data from "StepsApp"
      if (evt.packageName == "com.stepsapp.stepsapp") {
        // Find the numeric value in text like "Steps: 1,234"
        String text = evt.text ?? "";

        // Remove commas and extract the sequence of digits
        RegExp regExp = RegExp(r'\d+');
        var match = regExp.firstMatch(text.replaceAll(',', ''));

        if (match != null) {
          int steps = int.parse(match.group(0)!);
          print("📊 NotificationSync: Captured $steps steps from StepsApp");
          onStepsFound(steps);
        }
      }
    });
  }
}
