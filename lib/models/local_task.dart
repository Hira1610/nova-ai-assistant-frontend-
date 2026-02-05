import 'package:hive/hive.dart';

part 'local_task.g.dart';

@HiveType(typeId: 0)
class LocalTask extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late bool isSynced;

  @HiveField(5)
  late bool isCompleted;

  @HiveField(6)
  DateTime? remindAt;

  @HiveField(7)
  late String status;

  @HiveField(8)
  late String userId;

  @HiveField(9)
  late int notificationId; // Unique ID for each reminder

  LocalTask({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.notificationId,
    this.status = 'pending',
    this.isSynced = false,
    this.isCompleted = false,
    this.remindAt,
  });

  // --- SYNC KE LIYE YE DO FUNCTIONS ZARURI HAIN ---

  // 1. Model ko Map (JSON) mein convert karne ke liye (Sync bhejte waqt)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'status': status,
      'isCompleted': isCompleted,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(), // DateTime ko String banana parta hai
      'remindAt': remindAt?.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  // 2. Map (JSON) ko wapis Model banane ke liye (Server se data lete waqt)
  factory LocalTask.fromMap(Map<String, dynamic> map) {
    return LocalTask(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      type: map['type'],
      status: map['status'] ?? 'pending',
      isCompleted: map['isCompleted'] ?? false,
      isSynced: true, // Server se aa raha hai toh matlab synced hai
      createdAt: DateTime.parse(map['createdAt']),
      remindAt: map['remindAt'] != null ? DateTime.parse(map['remindAt']) : null,
      notificationId: map['notificationId'] ?? 0,
    );
  }
}