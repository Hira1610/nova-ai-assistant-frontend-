import 'package:flutter/material.dart';
import 'dart:async'; // Needed for Future.delayed
import '../widgets/loading_robot.dart'; // This is no longer needed
import '../widgets/custom_bottom_nav.dart';

// --- Data Model for an Email ---
class Email {
  final String subject;
  final String sender;
  final String snippet;
  final String time;

  Email({required this.subject, required this.sender, required this.snippet, required this.time});
}

class EmailHistoryScreen extends StatefulWidget {
  const EmailHistoryScreen({super.key});

  @override
  State<EmailHistoryScreen> createState() => _EmailHistoryScreenState();
}

class _EmailHistoryScreenState extends State<EmailHistoryScreen> {
  bool _isLoading = true;
  List<Email> _emails = [];

  @override
  void initState() {
    super.initState();
    _fetchEmailHistory();
  }

  // --- Backend Data Fetching ---
  Future<void> _fetchEmailHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 2));

    // Using mock data for demonstration
    final mockEmails = [
      Email(subject: 'Team Meeting', sender: 'Alice', snippet: 'Project Updates and milestones review.', time: '11:45 AM'),
      Email(subject: 'Marketing Report', sender: 'Bob', snippet: 'Q4 Analytics are now available.', time: '10:02 AM'),
      Email(subject: 'Design Feedback', sender: 'Charlie', snippet: 'Thoughts on the new UI mockups.', time: 'Yesterday'),
      Email(subject: 'Weekly Summary', sender: 'Project Manager', snippet: 'A summary of this week\'s progress.', time: 'Yesterday'),
    ];

    if (mounted) {
      setState(() {
        _emails = mockEmails;
        _isLoading = false;
      });
    }
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Email History', style: TextStyle(color: Colors.white70)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            // FIX: Replaced the LoadingRobot with your icon_screen.png image.
            ? Center(child: Image.asset('assets/icon_screen.png', height: 150))
            : Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: _emails.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final email = _emails[index];
                  return ListTile(
                    leading: const Icon(Icons.email, color: Colors.white),
                    title: Text(email.subject, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(email.sender, style: const TextStyle(color: Colors.white70)),
                    trailing: Text(email.time, style: const TextStyle(color: Colors.white54)),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.email),
      ),
    );
  }
}
