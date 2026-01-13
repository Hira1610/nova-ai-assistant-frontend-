import 'package:flutter/material.dart';

class Task {
  final String title;
  DateTime? dueDate;
  final Color priorityColor;
  bool isCompleted;

  Task({
    required this.title,
    this.dueDate,
    required this.priorityColor,
    this.isCompleted = false,
  });
}
