import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/custom_bottom_nav.dart';
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

// --- Home Screen ---
class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Chat> _recentChats = [];
  List<Email> _recentEmails = [];

  // State for the automation toggles
  bool _autoReplyEnabled = true;
  bool _dailySummaryEnabled = false;
  bool _meetingRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    // Mock data source
    final mockChats = [
      Chat(sender: 'NOVA', message: 'How can I help you today?', time: '10:30 AM'),
    ];

    final mockEmails = [
      Email(subject: 'Team Meeting', sender: 'Project Updates', snippet: 'Review the latest project milestones...', time: '10:55 AM'),
    ];

    setState(() {
      _recentChats = mockChats;
      _recentEmails = mockEmails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                        _buildAutomationsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.home),
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
              widget.username,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFF9C6BFF),
          child: Icon(Icons.smart_toy, color: Colors.white),
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen()));
              },
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentChats.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWithNovaScreen()));
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailHistoryScreen()));
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF7C3AED),
            inactiveThumbColor: Colors.grey.shade300,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
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
