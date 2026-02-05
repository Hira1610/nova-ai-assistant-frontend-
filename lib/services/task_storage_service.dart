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

  // Emulator ke liye 10.0.2.2, Real device ke liye apni IP use karein
  // final String baseUrl = "http://10.0.2.2:8000/api/v1";
  final String baseUrl = "http://192.168.100.22:8000/api/v1";
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
    print("DEBUG: Sending Token to Backend -> $token");
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 2. Add Task (Notification Logic ke sath)
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

    // 🔥 Generate Unique Integer ID for Android Notification
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

    // 🔥 Schedule Notification agar time set hai
    if (remindTime != null && remindTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
          generatedNotifId,
          title,
          remindTime
      );
    }

    print("✅ Task Saved & Notification Scheduled (ID: $generatedNotifId)");
    syncTasks();
  }

  // 3. Delete Task (System se Notification bhi cancel karega)
  Future<void> deleteTask(String id) async {
    var box = Hive.box<LocalTask>(_boxName);
    var deletedBox = Hive.box<String>(_deletedBoxName);

    LocalTask? taskToDelete = box.get(id);

    if (taskToDelete != null) {
      // 🔥 1. Android Notification Cancel karein
      await NotificationService.cancelNotification(taskToDelete.notificationId);

      // 2. Server sync ke liye queue mein dalein
      await deletedBox.add(id);

      // 3. Hive se delete karein
      await box.delete(id);

      print("🗑️ Task and Notification (ID: ${taskToDelete.notificationId}) Deleted");
    }

    syncTasks();
    hydrateFromBackend();
  }

  // 4. Update Status (Sync trigger karega)
  Future<void> updateTaskStatus(String id, String newStatus) async {
    var box = Hive.box<LocalTask>(_boxName);
    var task = box.get(id);
    if (task != null) {
      task.status = newStatus;
      task.isCompleted = (newStatus == 'completed');
      task.isSynced = false;

      // Agar task complete ho jaye, toh notification cancel kar deni chahiye
      if (task.isCompleted) {
        await NotificationService.cancelNotification(task.notificationId);
      }

      await task.save();
      syncTasks();
      hydrateFromBackend();
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

    // --- 1. Sync Deletions (Pehle purana kachra saaf karein) ---
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
          print("✅ Deletions Synced");
        }
      } catch (e) { print("❌ Delete Sync Error: $e"); }
    }

    // --- 2. Sync New/Updated Tasks ---
    // Note: cast<LocalTask>() lagaya hai taake type safety rahe
    List<LocalTask> unsyncedTasks = box.values
        .where((t) => !t.isSynced && t.userId == currentUserId)
        .toList();

    if (unsyncedTasks.isEmpty) {
      print("ℹ️ Nothing to sync.");
      return;
    }

    // 🔥 Yahan dhayan dein: toMap() ke andar wahi keys honi chahiye jo Pydantic schema mein hain
    List<Map<String, dynamic>> tasksData = unsyncedTasks.map((t) => t.toMap()).toList();

    try {
      print("🔄 Syncing ${unsyncedTasks.length} tasks...");
      final response = await http.post(
        Uri.parse('$baseUrl/sync-bulk'),
        headers: headers,
        body: jsonEncode(tasksData), // Direct list bhej rahe hain kyunki backend List[Schema] le raha hai
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Background mein Hive update karein
        for (var task in unsyncedTasks) {
          task.isSynced = true;
          await task.save(); // Hive data update
        }
        print("✅ Bulk Sync Successful");
      } else {
        print("⚠️ Sync Failed with status: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Sync Error: $e");
    }
  }

  Future<void> hydrateFromBackend() async {
    if (!await hasInternet()) return;

    final headers = await _getHeaders();
    final box = Hive.box<LocalTask>(_boxName);

    try {
      print("🔄 Pulling data from server...");
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // 1. Parsing (CPU Heavy work - Memory mein karein)
        List<dynamic> serverData = jsonDecode(response.body);
        Map<String, LocalTask> tasksMap = {};

        // 2. Notification Management: Pehle purani notifications saaf karein
        await NotificationService.cancelAllNotifications();

        for (var data in serverData) {
          try {
            LocalTask task = LocalTask.fromMap(data);
            task.isSynced = true; // Ye server se aaya hai, so synced hai

            // Map mein collect karein (Abhi save nahi kar rahe)
            tasksMap[task.id] = task;

            // 3. Notification Scheduling Logic (Sirf valid future reminders)
            if (task.type == 'reminder' &&
                !task.isCompleted &&
                task.remindAt != null &&
                task.remindAt!.isAfter(DateTime.now())) {

              await NotificationService.scheduleNotification(
                task.notificationId,
                task.title,
                task.remindAt!,
              );
            }
          } catch (e) {
            print("⚠️ Skipping Corrupt Task: $data");
          }
        }

        // 4. Batch Write (Disk I/O) - Super Fast 🚀
        // Pehle purana clear karein, phir naya bulk mein dalein
        if (tasksMap.isNotEmpty) {
          await box.clear();
          await box.putAll(tasksMap);
          print("✅ Hydration Success! ${tasksMap.length} tasks synced & scheduled.");
        } else {
          print("ℹ️ Server returned empty list. Cleared local storage.");
          await box.clear();
        }

      } else {
        print("⚠️ Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Hydration Failed: $e");
      // Note: Yahan humne box.clear() nahi kiya, taake error aane par
      // user ka purana data safe rahe.
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