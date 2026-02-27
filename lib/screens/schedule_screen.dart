import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nova/widgets/custom_bottom_nav.dart';
import '../models/local_task.dart';
import '../services/reminders_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EventFilter { all, pending, completed }

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
  EventFilter _currentFilter = EventFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _loadUserAndTasks();
    _storageService.cleanupMissedMeetings();
  }

  Future<void> _loadUserAndTasks() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _currentUserId = prefs.getString('userId') ?? '';
      _updateSelectedEvents();
    }
  }

  void _updateSelectedEvents() {
    if (!mounted) return;
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay ?? DateTime.now());
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<LocalTask> _getEventsForDay(DateTime day) {
    final box = Hive.box<LocalTask>('tasksBox');
    final dayUtc = DateTime.utc(day.year, day.month, day.day);

    List<LocalTask> events = box.values.where((task) {
      if (task.remindAt == null || task.userId != _currentUserId || task.type != 'meeting') return false;
      final taskDayUtc = DateTime.utc(task.remindAt!.year, task.remindAt!.month, task.remindAt!.day);
      return isSameDay(taskDayUtc, dayUtc);
    }).toList();

    if (_currentFilter == EventFilter.pending) {
      events = events.where((event) => !event.isCompleted).toList();
    } else if (_currentFilter == EventFilter.completed) {
      events = events.where((event) => event.isCompleted).toList();
    } else {
      events = events.where((event) => !event.isCompleted).toList();
    }

    return events..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _updateSelectedEvents();
    }
  }

  void _showAddTaskDialog(DateTime day) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return _AddEventDialog(
          selectedDay: day,
          storageService: _storageService,
          onEventAdded: () => _updateSelectedEvents(),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(LocalTask task) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
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
                    const Text("Delete Meeting?", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text("Are you sure you want to permanently delete this meeting?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                          onPressed: () {
                            _storageService.deleteTask(task.id);
                            Navigator.of(context).pop();
                            _updateSelectedEvents();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Meeting deleted."), backgroundColor: Colors.redAccent)
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
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
          child: SingleChildScrollView(
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if(mounted) _updateSelectedEvents();
                    });
                    return _buildCalendar(box);
                  },
                ),
                const SizedBox(height: 16),
                _buildFilterButtons(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Today's Meetings", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<List<LocalTask>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No meetings for this day.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(value[index]);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.schedule),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: EventFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentFilter = filter;
                  _updateSelectedEvents();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9C6BFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  filter.name[0].toUpperCase() + filter.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
      eventLoader: _getEventsForDay,
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white70),
        weekendTextStyle: const TextStyle(color: Colors.white),
        todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF9C6BFF), width: 2)),
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
    final Map<String, Color> colorMap = {'green': const Color(0xFF2DD4BF), 'orange': const Color(0xFFF59E0B), 'red': const Color(0xFFEF4444)};
    final statusMap = {'red': 'High', 'orange': 'Medium', 'green': 'Low'};
    final priority = statusMap[task.status] ?? 'Low';
    final priorityColor = colorMap[task.status] ?? colorMap['green']!;
    final bool isCompleted = task.isCompleted;

    return Opacity(
      opacity: isCompleted ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [priorityColor, priorityColor.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: priorityColor.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.type.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priority,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 16.0,
                        runSpacing: 4.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                              const SizedBox(width: 8),
                              Text(DateFormat('MMMM dd, yyyy').format(task.remindAt!), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled, color: Colors.white70, size: 14),
                              const SizedBox(width: 8),
                              Text(DateFormat('hh:mm a').format(task.remindAt!), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmationDialog(task),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  final DateTime selectedDay;
  final TaskStorageService storageService;
  final VoidCallback onEventAdded;

  const _AddEventDialog({required this.selectedDay, required this.storageService, required this.onEventAdded});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedPriority = 'green';

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.fromDateTime(widget.selectedDay);
    _endTime = TimeOfDay.fromDateTime(widget.selectedDay.add(const Duration(hours: 1)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleAddEvent() async {
    if (_titleController.text.isEmpty) return;

    DateTime finalStartTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    DateTime finalEndTime = DateTime(
      widget.selectedDay.year,
      widget.selectedDay.month,
      widget.selectedDay.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    await widget.storageService.addTask(
      title: _titleController.text,
      type: 'meeting',
      status: _selectedPriority,
      remindTime: finalStartTime,
    );

    widget.onEventAdded();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Meeting Added to your Schedule!'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _timePickerRow({required String label, required TimeOfDay? selectedTime, required Function(TimeOfDay) onTimeChanged}) {
    return GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
          if(picked != null) {
            onTimeChanged(picked);
          }
        },
        child: Row(
          children: [
            const Icon(Icons.access_time_filled, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const Spacer(),
            Text(selectedTime?.format(context) ?? 'Select', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        )
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Meeting', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Meeting Title', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)))),
                  const SizedBox(height: 20),
                  _timePickerRow(
                    label: "Start Time",
                    selectedTime: _startTime,
                    onTimeChanged: (newTime) => setState(() => _startTime = newTime),
                  ),
                  const SizedBox(height: 12),
                  _timePickerRow(
                    label: "End Time",
                    selectedTime: _endTime,
                    onTimeChanged: (newTime) => setState(() => _endTime = newTime),
                  ),
                  const SizedBox(height: 24),
                  const Text('Priority', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Low', 'Medium', 'High'].map((p) {
                      final Map<String, String> pMap = {'Low': 'green', 'Medium': 'orange', 'High': 'red'};
                      final Map<String, Color> colorMap = {'green': const Color(0xFF2DD4BF), 'orange': const Color(0xFFF59E0B), 'red': const Color(0xFFEF4444)};
                      final priorityValue = pMap[p]!;
                      final isSelected = _selectedPriority == priorityValue;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPriority = priorityValue),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                                color: isSelected ? colorMap[priorityValue] : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: isSelected ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.2), width: 1.5)
                            ),
                            child: Center(child: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _handleAddEvent, child: const Text('Add Meeting'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}