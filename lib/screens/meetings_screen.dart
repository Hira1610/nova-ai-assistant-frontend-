import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nova/widgets/custom_bottom_nav.dart'; // FIX: Corrected package name to lowercase
import '../models/local_task.dart';
import '../services/reminders_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ValueNotifier<List<LocalTask>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TaskStorageService _storageService = TaskStorageService();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadUserAndTasks();
  }

  Future<void> _loadUserAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _currentUserId = prefs.getString('userId') ?? '';
      // Load tasks for the initially selected day
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<LocalTask> _getEventsForDay(DateTime day) {
    final box = Hive.box<LocalTask>('tasksBox');
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    
    return box.values.where((task) {
      if (task.remindAt == null || task.userId != _currentUserId) return false;
      final taskDayUtc = DateTime.utc(task.remindAt!.year, task.remindAt!.month, task.remindAt!.day);
      return taskDayUtc == dayUtc;
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // update focused day as well
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _showAddTaskDialog(DateTime day) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        // Re-using the Add Task sheet logic, adapted for meetings/events
        return _AddEventDialog(selectedDay: day, storageService: _storageService);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Schedule', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                      onPressed: () => _showAddTaskDialog(_selectedDay ?? DateTime.now()),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<Box<LocalTask>>(
                valueListenable: Hive.box<LocalTask>('tasksBox').listenable(),
                builder: (context, box, _) {
                  // This builder ensures the calendar updates when tasks change
                  return _buildCalendar(box);
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Events for Today", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<LocalTask>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return const Center(
                        child: Text('No events for this day.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(value[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.meetings),
      ),
    );
  }

  TableCalendar<LocalTask> _buildCalendar(Box<LocalTask> box) {
    return TableCalendar<LocalTask>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      // This now gets events directly from your Hive database
      eventLoader: _getEventsForDay,
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white70),
        weekendTextStyle: const TextStyle(color: Colors.white),
        todayDecoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF9C6BFF), width: 2),
        ),
        selectedDecoration: const BoxDecoration(color: Color(0xFF9C6BFF), shape: BoxShape.circle),
        markerDecoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
        rightChevronIcon: Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white54),
        weekendStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildEventCard(LocalTask task) {
    Color priorityColor = task.status == 'red' ? Colors.red : (task.status == 'orange' ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF4A1B7B).withOpacity(0.6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: priorityColor, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          task.remindAt != null ? DateFormat('hh:mm a').format(task.remindAt!) : 'All day',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: (val) {
            _storageService.updateTaskStatus(task.id, val! ? 'completed' : 'pending');
          },
          activeColor: const Color(0xFF9C6BFF),
        ),
      ),
    );
  }
}

// A new Dialog for adding events, connected to the storage service
class _AddEventDialog extends StatefulWidget {
  final DateTime selectedDay;
  final TaskStorageService storageService;

  const _AddEventDialog({required this.selectedDay, required this.storageService});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleController = TextEditingController();
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.selectedDay),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleAddEvent() {
    if (_titleController.text.isEmpty) return;

    DateTime finalDateTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _selectedTime?.hour ?? DateTime.now().hour,
      _selectedTime?.minute ?? DateTime.now().minute,
    );

    widget.storageService.addTask(
      title: _titleController.text,
      type: 'meeting', // Differentiate from general reminders
      status: 'pending',
      remindTime: finalDateTime,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Event Added to your Schedule!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2D5F).withOpacity(0.8),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Event', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Event Title', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Text(
                    _selectedTime?.format(context) ?? 'Select Time',
                    style: TextStyle(color: _selectedTime == null ? Colors.white.withOpacity(0.7) : Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleAddEvent,
                  child: const Text('Add Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
