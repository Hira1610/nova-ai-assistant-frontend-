import 'package:flutter/material.dart';

class ComposeEmailScreen extends StatelessWidget {
  const ComposeEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B145E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Compose', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2B145E),
        elevation: 0,
        actions: [
          // Send Button
          TextButton(
            onPressed: () {
              // Handle send email action
              Navigator.pop(context);
            },
            child: const Text('Send', style: TextStyle(color: Color(0xFF9C6BFF), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(hint: 'To'),
            const Divider(color: Colors.white24),
            _buildTextField(hint: 'Subject'),
            const Divider(color: Colors.white24),
            Expanded(
              child: _buildTextField(hint: 'Compose email', maxLines: null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, int? maxLines = 1}) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }
}
