import 'package:flutter/material.dart';
import 'dart:async'; // Needed for Future.delayed

// --- Data Model for a Chat Message ---
class ChatMessage {
  final String sender;
  final String text;
  final String time;

  ChatMessage({required this.sender, required this.text, required this.time});

  /*
  // --- Backend Integration Example ---
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      text: json['text'],
      time: json['time'],
    );
  }
  */
}

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  // --- Data Fetching ---
  void _fetchChatHistory() {
    final mockMessages = [
      ChatMessage(sender: 'NOVA', text: 'How can I help you today?', time: '10:30 AM'),
      ChatMessage(sender: 'You', text: 'What\'s the weather like tomorrow?', time: '10:31 AM'),
      ChatMessage(sender: 'NOVA', text: 'It will be sunny with a high of 25°C.', time: '10:32 AM'),
    ];

    setState(() {
      _messages = mockMessages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History', style: TextStyle(color: Colors.white70)),
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF9C6BFF),
                child: Text(message.sender[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(message.sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(message.text, style: const TextStyle(color: Colors.white70)),
              trailing: Text(message.time, style: const TextStyle(color: Colors.white54)),
            );
          },
        ),
      ),
    );
  }
}
