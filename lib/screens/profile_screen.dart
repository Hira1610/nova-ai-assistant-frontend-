import 'package:flutter/material.dart';
import 'tasks_screen.dart';
import 'meetings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // --- Profile Header ---
            const Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF9C6BFF),
                    child: Icon(Icons.person, color: Colors.white, size: 60),
                  ),
                  SizedBox(height: 16),
                  Text('Alex Johnson', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('alex.johnson@example.com', style: TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // --- Menu Items ---
            _buildMenuItem(
              context,
              icon: Icons.check_box_outlined,
              title: 'My Tasks',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'My Meetings',
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen()));
              },
            ),
             const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () { /* Handle settings tap */ },
            ),
            const Spacer(),
            // --- Logout Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { /* Handle logout */ },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A1B7B).withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF4A1B7B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9C6BFF)),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
