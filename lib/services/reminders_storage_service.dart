import 'dart:convert';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_task.dart';
import 'notification_service.dart';

class TaskStorageService {
  static const String _boxName = 'tasksBox';
  static const String _deletedBoxName = 'deletedTasksBox';

  // Backend URL
  final String baseUrl = "http://192.168.100.17:8000/api/v1"; // Hira
  // final String baseUrl = "http://192.168.100.22:8000/api/v1"; // Waleed

  // 1. Initialize Boxes
  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocalTaskAdapter());
    }
    await Hive.openBox<LocalTask>(_boxName);
    await Hive.openBox<String>(_deletedBoxName);
  }

  // Helper: Get Headers with Token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 2. Add Task (JARVIS READY - Auto Schedule)
  Future<void> addTask({
    required String title,
    required String type,
    String status = 'pending',
    DateTime? remindTime,
  }) async {
    var box = Hive.box<LocalTask>(_boxName);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) return;

    // Unique ID for Hive/Database
    String uniqueId = "${userId}_${DateTime.now().millisecondsSinceEpoch}";

    // 🔥 Generate Unique Integer ID for Android Alarm/Notification
    int generatedNotifId = math.Random().nextInt(1000000);

    var newTask = LocalTask(
      notificationId: generatedNotifId,
      id: uniqueId,
      userId: userId,
      title: title,
      type: type,
      status: status,
      createdAt: DateTime.now(),
      isSynced: false,
      isCompleted: false,
      remindAt: remindTime,
    );

    // Save to Hive
    await box.put(uniqueId, newTask);

    // 🔥 JARVIS: Schedule Alarm + Voice + Notification agar time set hai
    if (remindTime != null && remindTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
          generatedNotifId,
          title,
          remindTime
      );
    }

    print("🚀 Task Saved & Jarvis Alert Synchronized (ID: $generatedNotifId)");
    syncTasks();
  }

  // 3. Delete Task (System se Alarm/Voice bhi cancel karega)
  Future<void> deleteTask(String id) async {
    var box = Hive.box<LocalTask>(_boxName);
    var deletedBox = Hive.box<String>(_deletedBoxName);

    LocalTask? taskToDelete = box.get(id);

    if (taskToDelete != null) {
      // 🔥 Stop Jarvis: Alarm aur notification dono ko khatam karein
      await NotificationService.cancelNotification(taskToDelete.notificationId);

      // Server sync ke liye queue mein dalein
      await deletedBox.add(id);

      // Hive se delete karein
      await box.delete(id);

      print("🗑️ Task and Jarvis Reminder Deleted");
    }

    syncTasks();
  }

  // 4. Update Status (Auto-Silence Logic)
  Future<void> updateTaskStatus(String id, String newStatus) async {
    var box = Hive.box<LocalTask>(_boxName);
    var task = box.get(id);
    if (task != null) {
      task.status = newStatus;
      task.isCompleted = (newStatus == 'completed');
      task.isSynced = false;

      // 🔥 Agar task complete ho jaye, toh voice reminder cancel kar do
      if (task.isCompleted) {
        await NotificationService.cancelNotification(task.notificationId);
      }

      await task.save();
      syncTasks();
    }
  }

  // NEW: Cleanup function for missed meetings
  Future<void> cleanupMissedMeetings() async {
    final box = Hive.box<LocalTask>(_boxName);
    final now = DateTime.now();

    // Find all meetings that are in the past and not yet completed
    final missedMeetings = box.values.where((task) {
      // FIX: Corrected the typo in 'meeting'
      return task.type == 'meeting' &&
          !task.isCompleted &&
          task.remindAt != null &&
          task.remindAt!.isBefore(now);
    }).toList();

    for (var task in missedMeetings) {
      task.isCompleted = true;
      task.status = 'completed';
      await task.save();
    }

    if (missedMeetings.isNotEmpty) {
      print("🧹 Cleaned up ${missedMeetings.length} missed meetings.");
      syncTasks(); // Sync the changes with the backend
    }
  }

  // 5. THE MASTER SYNC LOGIC
  Future<void> syncTasks() async {
    if (!await hasInternet()) return;

    final prefs = await SharedPreferences.getInstance();
    final String currentUserId = prefs.getString('userId') ?? '';
    if (currentUserId.isEmpty) return;

    var box = Hive.box<LocalTask>(_boxName);
    var deletedBox = Hive.box<String>(_deletedBoxName);
    final headers = await _getHeaders();

    // --- Sync Deletions ---
    if (deletedBox.isNotEmpty) {
      try {
        final List<String> idsToDelete = deletedBox.values.cast<String>().toList();
        final response = await http.post(
          Uri.parse('$baseUrl/delete-bulk'),
          headers: headers,
          body: jsonEncode({'ids': idsToDelete}),
        );
        if (response.statusCode == 200) {
          await deletedBox.clear();
        }
      } catch (e) { print("❌ Delete Sync Error: $e"); }
    }

    // --- Sync New/Updated Tasks ---
    List<LocalTask> unsyncedTasks = box.values
        .where((t) => !t.isSynced && t.userId == currentUserId)
        .toList();

    if (unsyncedTasks.isEmpty) return;

    List<Map<String, dynamic>> tasksData = unsyncedTasks.map((t) => t.toMap()).toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync-bulk'),
        headers: headers,
        body: jsonEncode(tasksData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var task in unsyncedTasks) {
          task.isSynced = true;
          await task.save();
        }
        print("✅ Bulk Sync Successful");
      }
    } catch (e) {
      print("❌ Sync Error: $e");
    }
  }

  // 6. Hydrate From Backend (JARVIS SMART SYNC)
  Future<void> hydrateFromBackend() async {
    if (!await hasInternet()) return;

    final headers = await _getHeaders();
    final box = Hive.box<LocalTask>(_boxName);

    try {
      print("🔄 Jarvis is pulling cloud data...");
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List<dynamic> serverData = jsonDecode(response.body);

        // Batch processing for better performance
        for (var data in serverData) {
          LocalTask task = LocalTask.fromMap(data);
          task.isSynced = true;

          // Sirf naya task ya updated task save karein
          bool alreadyExists = box.containsKey(task.id);

          if (!alreadyExists) {
            await box.put(task.id, task);

            // 🔥 Auto-Schedule if it's a future reminder
            if (!task.isCompleted &&
                task.remindAt != null &&
                task.remindAt!.isAfter(DateTime.now())) {

              await NotificationService.scheduleNotification(
                task.notificationId,
                task.title,
                task.remindAt!,
              );
            }
          }
        }
        print("✅ Hydration Success!");
      }
    } catch (e) {
      print("❌ Hydration Failed: $e");
    }
  }

  // Helper Methods
  Future<bool> hasInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  Future<List<LocalTask>> getAllTasksForCurrentUser() async {
    var box = Hive.box<LocalTask>(_boxName);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String currentUserId = prefs.getString('userId') ?? '';
    return box.values.where((task) => task.userId == currentUserId).toList();
  }

  Future<void> clearAllLocalData() async {
    await Hive.box<LocalTask>(_boxName).clear();
    await Hive.box<String>(_deletedBoxName).clear();
  }
}