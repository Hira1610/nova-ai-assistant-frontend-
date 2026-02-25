import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart'; // FIX: Added import for the bottom nav bar

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

  @override
  Widget build(BuildContext context) {
    final List<EmailItem> emails = [
      EmailItem(sender: 'Sarah Johnson', subject: 'Project Update - Q4 Review', snippet: 'Hi team, I wanted to share the latest updates on our Q4 project milestones...', time: '9:00 AM'),
      EmailItem(sender: 'Marketing Team', subject: 'New Campaign Launch', snippet: 'Exciting news! We\'re launching our new marketing campaign next week...', time: 'Yesterday', isRead: true),
      EmailItem(sender: 'David Chen', subject: 'Meeting Notes - Design Review', snippet: 'Here are the notes from our design review meeting on Monday...', time: '2 days ago'),
      EmailItem(sender: 'HR Department', subject: 'Benefits Enrollment Reminder', snippet: 'Don\'t forget to complete your benefits enrollment by the end of month...', time: '3 days ago'),
    ];

    // FIX: Added Container with gradient to restore the theme.
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
          automaticallyImplyLeading: false, // Ensures no back arrow appears
          title: const Text('Inbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // FIX: Corrected title
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white70),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),
        drawer: _buildInboxDrawer(context),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showComposeDialog(context),
          backgroundColor: const Color(0xFF9C6BFF),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        // FIX: Added the bottom navigation bar back to the screen.
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.email),
      ),
    );
  }

  Widget _buildInboxDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24, width: 0.5)),
                  ),
                  child: Text('NOVA Mail', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                _buildDrawerItem(context, icon: Icons.inbox, text: 'Inbox', isSelected: true, onTap: () => Navigator.pop(context)),
                _buildDrawerItem(context, icon: Icons.star_border, text: 'Starred', onTap: () => Navigator.pop(context)),
                _buildDrawerItem(context, icon: Icons.send_outlined, text: 'Sent', onTap: () => Navigator.pop(context)),
                const Divider(color: Colors.white24),
                _buildDrawerItem(context, icon: Icons.delete_outline, text: 'Trash', onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, VoidCallback? onTap, bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF9C6BFF) : Colors.white70),
      title: Text(text, style: TextStyle(color: isSelected ? const Color(0xFF9C6BFF) : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showComposeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const _ComposeEmailDialog(),
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
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'To', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: 'Subject', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'Message', hintStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.white70),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.schedule, color: Colors.white70),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF9C6BFF),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
