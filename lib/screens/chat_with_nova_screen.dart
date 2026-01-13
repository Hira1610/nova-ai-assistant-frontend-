import 'package:flutter/material.dart';

// --- Data Model for a Message ---
class Message {
  final bool isUser;
  final String text;
  final String time;

  Message({required this.isUser, required this.text, required this.time});
}

class ChatWithNovaScreen extends StatelessWidget {
  const ChatWithNovaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Message> messages = [
      Message(isUser: false, text: "Hello! I'm NOVA, your AI assistant. How can I help you today?", time: "10:30 AM"),
      Message(isUser: true, text: "Help me organize my day", time: "10:31 AM"),
      Message(isUser: false, text: "I'd be happy to help! Let me check your calendar and tasks for today.", time: "10:31 AM"),
      Message(isUser: true, text: "What meetings do I have?", time: "10:32 AM"),
      Message(isUser: false, text: "You have 2 meetings today:\n• Team Sync at 2:00 PM\n• Client Call at 4:30 PM", time: "10:32 AM"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('NOVA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
        actions: const [Icon(Icons.more_vert, color: Colors.white)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser ? const Color(0xFF4A1B7B) : const Color(0xFF6A1FB0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(message.time, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2B145E),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4A1B7B),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Color(0xFF6A1FB0),
            child: Icon(Icons.send, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Color(0xFF6A1FB0),
            child: Icon(Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
