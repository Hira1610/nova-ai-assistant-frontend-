import 'package:flutter/material.dart';
import 'chat_with_nova_screen.dart';
import 'inbox_screen.dart';
import 'profile_screen.dart';

// --- Data Model for a Meeting ---
class Meeting {
  final String title;
  final String time;
  final List<Color> participantColors;

  Meeting({required this.title, required this.time, required this.participantColors});
}

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final List<Meeting> _meetings = [
    Meeting(title: 'Team Standup', time: '9:00 AM - 9:30 AM', participantColors: [Colors.purple, Colors.green, Colors.orange, Colors.blue, Colors.red, Colors.teal]),
    Meeting(title: 'Client Presentation', time: '11:00 AM - 12:30 PM', participantColors: [Colors.blue, Colors.red]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meetings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              onPressed: () {
                // Handle add meeting action
              },
            ),
          ),
        ],
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Today's Meetings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildMeetingList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildMeetingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _meetings.length,
      itemBuilder: (context, index) {
        final meeting = _meetings[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: const Color(0xFF4A1B7B).withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 80, // Adjust this width for more or fewer avatars
                      child: Stack(
                        children: List.generate(meeting.participantColors.take(4).length, (i) {
                          if (i == 3) {
                             return Positioned(
                              left: i * 18.0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black.withOpacity(0.5),
                                child: Text('+${meeting.participantColors.length - 3}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }
                          return Positioned(
                            left: i * 18.0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: meeting.participantColors[i],
                              child: const CircleAvatar(radius: 11, backgroundColor: Colors.transparent), // Inner border
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen()));
            },
            icon: const Icon(Icons.email_outlined, color: Colors.white54, size: 28),
          ),
          IconButton(
            onPressed: () { /* Already on this screen */ },
            icon: const Icon(Icons.check_circle, color: Color(0xFF9C6BFF), size: 28),
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
