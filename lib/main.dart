import 'package:flutter/material.dart';
import 'package:nova/screens/welcome_screen.dart';

void main() {
  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVA',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const WelcomeScreen(), // The app now starts here
    );
  }
}
