import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nova/widgets/custom_bottom_nav.dart';

// --- Data Model for Recent Chat Item ---
class RecentChat {
  final String name;
  final String lastMessage;

  RecentChat({required this.name, required this.lastMessage});
}

class ChatWithNovaScreen extends StatefulWidget {
  const ChatWithNovaScreen({super.key});

  @override
  State<ChatWithNovaScreen> createState() => _ChatWithNovaScreenState();
}

class _ChatWithNovaScreenState extends State<ChatWithNovaScreen> {
  // This state would be used to switch between the initial UI and an active chat

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
          title: Row(
            children: [
              // FIX: Increased the height of your image, as you requested.
              Image.asset('assets/icon_screen.png', height: 40),
              const SizedBox(width: 12),
              const Text('Let\'s Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white70), // Sets drawer icon color
          actions: const [Padding(padding: EdgeInsets.only(right: 8.0), child: Icon(Icons.more_vert, color: Colors.white))],
        ),
        drawer: _buildChatDrawer(context),
        body: Column(
          children: [
            Expanded(
              child: _buildInitialChatUI(), // Show the new initial UI
            ),
            _buildMessageComposer(),
          ],
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.chat),
      ),
    );
  }

  // New Widget for the ChatGPT-style initial interface
  Widget _buildInitialChatUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF9C6BFF),
            child: Icon(Icons.lightbulb_outline, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'How can I help you today?',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Write a professional email'),
              _buildSuggestionChip('Summarize a long article'),
              _buildSuggestionChip('Explain quantum computing'),
              _buildSuggestionChip('Plan a trip to Japan'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF9C6BFF),
            child: Icon(Icons.send, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF9C6BFF),
            child: Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildChatDrawer(BuildContext context) {
    final List<RecentChat> recentChats = [
      RecentChat(name: 'NOVA', lastMessage: 'You have 2 meetings today...'),
      RecentChat(name: 'Alice', lastMessage: 'Sure, I can help with that.'),
      RecentChat(name: 'Bob', lastMessage: 'Let\'s schedule a meeting for...'),
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), // Darker overlay for better readability
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24, width: 0.5)),
                  ),
                  child: Text(
                    'Recent Chats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.white),
                  title: const Text('New Chat', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    // Logic to start a new chat would go here
                  },
                ),
                const Divider(color: Colors.white24, height: 1),
                ...recentChats.map((chat) {
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFF9C6BFF), child: Text(chat.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(chat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(chat.lastMessage, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Logic to switch to this chat would go here
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
