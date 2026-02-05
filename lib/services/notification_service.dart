import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'nova_urgent_channel_v2';

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      print("✅ DEBUG: Timezone set to Asia/Karachi");
    } catch (e) {
      print("❌ DEBUG: Timezone Error: $e");
    }

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) {
        print("🔔 Notification Clicked: ${details.payload}");
      },
    );

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Urgent Reminders',
          description: 'This channel is used for important task reminders.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        ),
      );
    }
  }

  // --- 1. CANCEL NOTIFICATION (NEWLY ADDED) ---
  // Ye function TaskStorageService se call hoga jab task delete hoga
  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      print("🚫 DEBUG: Notification ID $id Cancelled/Removed");
    } catch (e) {
      print("❌ DEBUG: Error cancelling notification: $e");
    }
  }

  // --- 2. CANCEL ALL (NEWLY ADDED) ---
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print("🚫 DEBUG: All Notifications Cancelled");
  }

  // --- 3. INSTANT NOTIFICATION ---
  static Future<void> showNotification(int id, String title, String body) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Urgent Reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
    );
  }

  // --- 4. SCHEDULED NOTIFICATION ---
  static Future<void> scheduleNotification(int id, String title, DateTime scheduledTime) async {
    final location = tz.local;
    final scheduledDate = tz.TZDateTime.from(scheduledTime, location);

    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) {
      print("❌ DEBUG: Cannot schedule in the past");
      return;
    }

    print("⏰ DEBUG: Scheduling for: $scheduledDate");

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Reminder: $title',
        'Nova: Is task ka waqt ho gaya hai!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Urgent Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("✅ DEBUG: Schedule Successful for ID: $id");
    } catch (e) {
      print("❌ DEBUG: Schedule Failed: $e");
      _scheduleInexact(id, title, scheduledDate);
    }
  }

  static Future<void> _scheduleInexact(int id, String title, tz.TZDateTime scheduledDate) async {
    await _notificationsPlugin.zonedSchedule(
      id, 'Reminder: $title', 'Task is due!', scheduledDate,
      const NotificationDetails(android: AndroidNotificationDetails(_channelId, 'Urgent Reminders')),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // --- 5. PERMISSIONS ---
  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}