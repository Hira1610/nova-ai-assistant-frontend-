import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/custom_bottom_nav.dart';
import '../utils/user_sessions.dart'; // Session utility
import 'chat_history_screen.dart';
import 'email_history_screen.dart';
import 'chat_with_nova_screen.dart';

// --- Data Models ---
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

class Meeting {
  final String title;
  final String time;
  Meeting({required this.title, required this.time});
}

// --- Home Screen ---
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = ""; // Local variable for name

  List<Chat> _recentChats = [];
  List<Email> _recentEmails = [];
  List<Meeting> _meetings = [];

  // State for the automation toggles
  bool _autoReplyEnabled = true;
  bool _dailySummaryEnabled = false;
  bool _meetingRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
    _refreshUserData(); // Load real name from storage
    _fetchData();
  }

  // Session se data refresh karne ke liye
  Future<void> _refreshUserData() async {
    final userData = await UserSession.getUserData();
    if (mounted) {
      setState(() {
        _displayName = userData['username']!;
      });
    }
  }

  void _fetchData() {
    final mockChats = [
      Chat(sender: 'NOVA', message: 'How can I help you today?', time: '10:30 AM'),
    ];
    final mockEmails = [
      Email(subject: 'Team Meeting', sender: 'Project Updates', snippet: 'Review milestones...', time: '10:55 AM'),
    ];
    final mockMeetings = [
      Meeting(title: 'Team Standup', time: '9:00 AM - 9:30 AM'),
      Meeting(title: 'Client Presentation', time: '11:00 AM - 12:30 PM'),
    ];

    setState(() {
      _recentChats = mockChats;
      _recentEmails = mockEmails;
      _meetings = mockMeetings;
    });
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRecentChats(context),
                        const SizedBox(height: 25),
                        _buildRecentEmails(context),
                        const SizedBox(height: 25),
                        _buildMeetingsSection(context),
                        const SizedBox(height: 25),
                        _buildAutomationsSection(),
                      ],
                    ),
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
        // FIX: Replaced the robot icon with your image.
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

  Widget _buildMeetingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.calendar_today, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Today's Meetings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        glassCard(
          child: Column(
            children: _meetings.asMap().entries.map((entry) {
              int idx = entry.key;
              Meeting meeting = entry.value;
              return Column(
                children: [
                  _buildMeetingTile(meeting),
                  if (idx < _meetings.length - 1) const Divider(color: Colors.white24, height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingTile(Meeting meeting) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meeting.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(meeting.time, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reminder set for ${meeting.title}')),
              );
            },
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
