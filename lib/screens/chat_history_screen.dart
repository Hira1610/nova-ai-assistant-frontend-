import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chat_with_nova_screen.dart';

// --- Data Model ---
class Chat {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;

  Chat({required this.name, required this.lastMessage, required this.time, this.unreadCount = 0});
}

// --- Chat History Screen ---
class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Chat> chats = [
      Chat(name: 'NOVA', lastMessage: 'How can I help you today?', time: '10:30', unreadCount: 1),
      Chat(name: 'Alice', lastMessage: 'Sure, I can help with that.', time: '10:25'),
      Chat(name: 'Bob', lastMessage: 'Let\'s schedule a meeting for tomorrow.', time: 'Yesterday', unreadCount: 3),
    ];

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
          title: const Text('Chats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF4A1B7B),
                child: Text(chat.name[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(chat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(chat.lastMessage, style: const TextStyle(color: Colors.white70)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(chat.time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  if (chat.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF9C6BFF), shape: BoxShape.circle),
                      child: Text(chat.unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatWithNovaScreen()),
                );
              },
            );
          },
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.chat),
      ),
    );
  }
}
