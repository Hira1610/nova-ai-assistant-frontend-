import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart'; // 🔥 JARVIS Power
import '../services/tts_service.dart';

// --- 1. JARVIS BACKGROUND ACTION (TOP-LEVEL) ---
@pragma('vm:entry-point')
void fireAlarmAction(int id, Map<String, dynamic> data) async {
  String taskTitle = data['title'] ?? "Task";

  // Background engine mein services ko dobara jagana parta hai
  await TTSService().init();

  // 🔥 AUTO SPEAK: Yeh hai asal Jarvis magic, jo bagair touch kiye bolega
  await TTSService().speak("Sir, aapka reminder hai: $taskTitle");
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
    TTSService().speak("Reminder: ${notificationResponse.payload}");
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'nova_urgent_channel_v2';

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    } catch (e) {
      print("❌ Timezone Error: $e");
    }

    await TTSService().init();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          await TTSService().speak("Reminder: ${details.payload}");
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  // --- 2. SCHEDULED NOTIFICATION (WITH AUTO-SPEAK) ---
  static Future<void> scheduleNotification(int id, String title, DateTime scheduledTime) async {
    final location = tz.local;
    final scheduledDate = tz.TZDateTime.from(scheduledTime, location);

    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) return;

    try {
      // (A) Local Notification Schedule (Visual ke liye)
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
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: title,
      );

      // 🔥 (B) JARVIS ALARM (Voice ke liye jo khud bolay ga)
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        fireAlarmAction,
        exact: true,
        wakeup: true, // Phone ko neend se jagayega
        allowWhileIdle: true,
        params: {"title": title},
      );

      print("✅ Jarvis Alert Synchronized: $title");
    } catch (e) {
      print("❌ Scheduling Error: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    await AndroidAlarmManager.cancel(id); // Alarm bhi cancel karo
  }

  static Future<void> showNotification(int id, String title, String body) async {
    await _notificationsPlugin.show(
      id, title, body,
      const NotificationDetails(android: AndroidNotificationDetails(_channelId, 'Urgent Reminders')),
      payload: title,
    );
    await TTSService().speak("Reminder: $title");
  }

  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    await Permission.notification.request();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    await Permission.ignoreBatteryOptimizations.request();
  }
}