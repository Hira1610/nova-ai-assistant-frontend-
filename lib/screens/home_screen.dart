import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/local_task.dart';
import '../widgets/custom_bottom_nav.dart';
import '../utils/user_sessions.dart';
import 'chat_history_screen.dart';
import 'email_history_screen.dart';
import 'chat_with_nova_screen.dart';
import 'schedule_screen.dart';

// --- Data Models (for mock data) ---
class Chat {
  final String sender;
  final String message;
  final String time;
  Chat({required this.sender, required this.message, required this.time});
}

class Email {
  final String subject;
  final String sender;
  final String snippet;
  final String time;
  Email({required this.subject, required this.sender, required this.snippet, required this.time});
}

// --- Home Screen ---
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = "";

  // State for mock data
  List<Chat> _recentChats = [];
  List<Email> _recentEmails = [];

  // State for the automation toggles
  bool _autoReplyEnabled = true;
  bool _dailySummaryEnabled = false;
  bool _meetingRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
    _refreshUserData();
    _fetchMockData(); // FIX: Renamed to clarify it only fetches mock data now
  }

  Future<void> _refreshUserData() async {
    final userData = await UserSession.getUserData();
    if (mounted) {
      setState(() {
        _displayName = userData['username']!;
      });
    }
  }

  // FIX: This now only loads mock data for chats and emails.
  void _fetchMockData() {
    final mockChats = [
      Chat(sender: 'NOVA', message: 'How can I help you today?', time: '10:30 AM'),
    ];
    final mockEmails = [
      Email(subject: 'Team Meeting', sender: 'Project Updates', snippet: 'Review milestones...', time: '10:55 AM'),
    ];

    setState(() {
      _recentChats = mockChats;
      _recentEmails = mockEmails;
    });
  }

  // FIX: This function now gets REAL meeting data from your database.
  List<LocalTask> _getTodaysMeetings(Box<LocalTask> box) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return box.values.where((task) {
      return task.type == 'meeting' &&
          !task.isCompleted &&
          task.remindAt != null &&
          task.remindAt!.isAfter(today) &&
          task.remindAt!.isBefore(tomorrow);
    }).toList()..sort((a, b) => a.remindAt!.compareTo(b.remindAt!));
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                Expanded(
                  // FIX: Added ValueListenableBuilder to get live updates from the database
                  child: ValueListenableBuilder<Box<LocalTask>>(
                    valueListenable: Hive.box<LocalTask>('tasksBox').listenable(),
                    builder: (context, box, _) {
                      final todaysMeetings = _getTodaysMeetings(box);
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecentChats(context),
                            const SizedBox(height: 25),
                            _buildRecentEmails(context),
                            const SizedBox(height: 25),
                            // FIX: Passing the real meeting data to the widget
                            _buildMeetingsSection(context, todaysMeetings),
                            const SizedBox(height: 25),
                            _buildAutomationsSection(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.home),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Good Morning", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              _displayName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 22,
          backgroundImage: AssetImage('assets/icon_screen.png'),
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Chats", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen())).then((_) => _refreshUserData());
              },
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentChats.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWithNovaScreen())).then((_) => _refreshUserData());
            },
            child: glassCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF9C6BFF),
                    child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_recentChats.first.sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_recentChats.first.message, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_recentChats.first.time, style: const TextStyle(color: Colors.white60)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentEmails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Recent Emails", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailHistoryScreen())).then((_) => _refreshUserData());
              },
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentEmails.isNotEmpty)
          glassCard(
            borderColor: const Color(0xFF9C6BFF),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, backgroundColor: Color(0xFF9C6BFF), child: Icon(Icons.email_outlined, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_recentEmails.first.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_recentEmails.first.sender, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(_recentEmails.first.time, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
      ],
    );
  }

  // FIX: This widget now takes a list of LocalTask objects.
  Widget _buildMeetingsSection(BuildContext context, List<LocalTask> meetings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text("Today's Meetings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen())),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        glassCard(
          child: meetings.isEmpty
              ? const Center(child: Text("No meetings scheduled for today.", style: TextStyle(color: Colors.white70)))
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meetings.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 1),
            itemBuilder: (_, index) => _buildMeetingTile(meetings[index]),
          ),
        ),
      ],
    );
  }

  // FIX: This widget now takes a LocalTask object.
  Widget _buildMeetingTile(LocalTask meeting) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('hh:mm a').format(meeting.remindAt!), style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bolt, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text("Automations", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        glassCard(
          child: Column(
            children: [
              _buildAutomationTile(
                title: 'Auto-reply to emails',
                value: _autoReplyEnabled,
                onChanged: (value) => setState(() => _autoReplyEnabled = value),
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildAutomationTile(
                title: 'Daily task summary',
                value: _dailySummaryEnabled,
                onChanged: (value) => setState(() => _dailySummaryEnabled = value),
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildAutomationTile(
                title: 'Meeting reminders',
                value: _meetingRemindersEnabled,
                onChanged: (value) => setState(() => _meetingRemindersEnabled = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF7C3AED),
        inactiveThumbColor: Colors.grey.shade300,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }
}

Widget glassCard({required Widget child, Color borderColor = Colors.white24}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(20),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}