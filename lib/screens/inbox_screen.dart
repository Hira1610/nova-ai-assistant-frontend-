import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';
import 'chat_with_nova_screen.dart';

// --- Data Model for Email ---
class EmailItem {
  final String sender;
  final String subject;
  final String snippet;
  final String time;
  final bool isRead;

  EmailItem({
    required this.sender,
    required this.subject,
    required this.snippet,
    required this.time,
    this.isRead = false,
  });
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  void _showComposeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const _ComposeEmailDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<EmailItem> emails = [
      EmailItem(sender: 'Sarah Johnson', subject: 'Project Update - Q4 Review', snippet: 'Hi team, I wanted to share the latest updates on our Q4 project milestones...', time: '9:00 AM'),
      EmailItem(sender: 'Marketing Team', subject: 'New Campaign Launch', snippet: 'Exciting news! We\'re launching our new marketing campaign next week...', time: 'Yesterday', isRead: true),
      EmailItem(sender: 'David Chen', subject: 'Meeting Notes - Design Review', snippet: 'Here are the notes from our design review meeting on Monday...', time: '2 days ago'),
      EmailItem(sender: 'HR Department', subject: 'Benefits Enrollment Reminder', snippet: 'Don\'t forget to complete your benefits enrollment by the end of month...', time: '3 days ago'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Inbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            onPressed: () => _showComposeDialog(context),
          ),
        ],
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: emails.length,
        itemBuilder: (context, index) {
          final email = emails[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFF4A1B7B).withOpacity(0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (!email.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9C6BFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (!email.isRead) const SizedBox(width: 8),
                          Text(email.sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(email.time, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(email.subject, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email.snippet, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A1B7B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatWithNovaScreen()));
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () { /* Already on this screen */ },
            icon: const Icon(Icons.email, color: Color(0xFF9C6BFF), size: 28),
          ),
          IconButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
            },
            icon: const Icon(Icons.check_box_outline_blank, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.person_outline, color: Colors.white54, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ComposeEmailDialog extends StatelessWidget {
  const _ComposeEmailDialog();

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compose Email', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(hint: 'To'),
                const SizedBox(height: 16),
                _buildTextField(hint: 'Subject'),
                const SizedBox(height: 16),
                _buildTextField(hint: 'Message', maxLines: 5),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    label: const Text('Send'),
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
    );
  }

  Widget _buildTextField({required String hint, int maxLines = 1}) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
