import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nova/widgets/custom_bottom_nav.dart';

// --- Data Model for a Meeting ---
class CalendarEvent {
  final String title;
  final String time;
  final List<Color> participantColors;
  final bool hasReminder;
  final Color labelColor;

  CalendarEvent({
    required this.title,
    required this.time,
    required this.participantColors,
    this.hasReminder = false,
    required this.labelColor,
  });
}

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<CalendarEvent>> _meetings = {
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      CalendarEvent(title: 'Team Standup', time: '9:00 AM - 9:30 AM', participantColors: [Colors.purple, Colors.green], hasReminder: true, labelColor: Colors.blue),
      CalendarEvent(title: 'Client Presentation', time: '11:00 AM - 12:30 PM', participantColors: [Colors.blue, Colors.red], labelColor: Colors.red),
    ],
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day + 5): [
       CalendarEvent(title: 'Project Kick-off', time: '2:00 PM - 3:00 PM', participantColors: [Colors.yellow, Colors.cyan], labelColor: Colors.green, hasReminder: true),
    ]
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _meetings[dayUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }
  
  void _showAddMeetingDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return _AddMeetingDialog(
          selectedDay: _selectedDay!,
          onAdd: (newEvent) {
            setState(() {
              final dayUtc = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              if (_meetings.containsKey(dayUtc)) {
                _meetings[dayUtc]!.add(newEvent);
              } else {
                _meetings[dayUtc] = [newEvent];
              }
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            });
          },
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Meetings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                      onPressed: _showAddMeetingDialog,
                    ),
                  ],
                ),
              ),
              _buildCalendar(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Today's Meetings", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<CalendarEvent>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return const Center(
                        child: Text('No meetings for this day.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        return _buildMeetingCard(value[index]);
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

  Widget _buildCalendar() {
    return TableCalendar<CalendarEvent>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      eventLoader: _getEventsForDay,
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white70),
        weekendTextStyle: const TextStyle(color: Colors.white),
        todayDecoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF9C6BFF), width: 2),
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF9C6BFF),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(color: Color(0xFF9C6BFF), shape: BoxShape.circle),
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

  Widget _buildMeetingCard(CalendarEvent meeting) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF4A1B7B).withOpacity(0.6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: meeting.labelColor, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(meeting.time, style: const TextStyle(color: Colors.white70)),
                if (meeting.hasReminder) const SizedBox(width: 12),
                if (meeting.hasReminder) const Icon(Icons.alarm, color: Colors.white70, size: 16),
              ],
            ),
            if (meeting.participantColors.isNotEmpty)
            const SizedBox(height: 12),
            if (meeting.participantColors.isNotEmpty)
            Row(
              children: [
                SizedBox(
                  width: 80, // Adjust width for more avatars
                  child: Stack(
                    children: List.generate(meeting.participantColors.take(3).length, (i) {
                      return Positioned(
                        left: i * 20.0,
                        child: CircleAvatar(radius: 12, backgroundColor: meeting.participantColors[i]),
                      );
                    }),
                  ),
                ),
                 if (meeting.participantColors.length > 3)
                 Text('+${meeting.participantColors.length - 3}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMeetingDialog extends StatefulWidget {
  final DateTime selectedDay;
  final Function(CalendarEvent) onAdd;

  const _AddMeetingDialog({required this.selectedDay, required this.onAdd});

  @override
  State<_AddMeetingDialog> createState() => _AddMeetingDialogState();
}

class _AddMeetingDialogState extends State<_AddMeetingDialog> {
  final _titleController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _setReminder = false;
  Color _selectedLabelColor = Colors.blue;
  final List<Color> _labelColors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];


  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, {required bool isStartTime}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _handleAddMeeting() {
    if (_titleController.text.isNotEmpty && _startTime != null && _endTime != null) {
      final newEvent = CalendarEvent(
        title: _titleController.text,
        time: '${_startTime!.format(context)} - ${_endTime!.format(context)}',
        participantColors: [], // Start with no participants
        hasReminder: _setReminder,
        labelColor: _selectedLabelColor,
      );
      widget.onAdd(newEvent);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2D5F).withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Meeting', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(hintText: 'Title', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, isStartTime: true),
                          child: Text(
                            _startTime?.format(context) ?? 'Start Time',
                            style: TextStyle(color: _startTime == null ? Colors.white.withOpacity(0.7) : Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const Text(' - ', style: TextStyle(color: Colors.white, fontSize: 16)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context, isStartTime: false),
                          child: Text(
                            _endTime?.format(context) ?? 'End Time',
                            style: TextStyle(color: _endTime == null ? Colors.white.withOpacity(0.7) : Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Set Reminder', style: TextStyle(color: Colors.white70)),
                    value: _setReminder,
                    onChanged: (bool value) {
                      setState(() {
                        _setReminder = value;
                      });
                    },
                    activeColor: const Color(0xFF9C6BFF),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.black.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Label Color', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _labelColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLabelColor = color;
                          });
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: color,
                          child: _selectedLabelColor == color
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleAddMeeting,
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      label: const Text('Add Meeting'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF9C6BFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
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
