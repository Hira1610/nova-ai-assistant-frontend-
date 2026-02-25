import 'package:flutter/material.dart';

class LoadingRobot extends StatelessWidget {
  const LoadingRobot({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: This now shows your image instead of the robot icon.
    return Center(
      child: Image.asset(
        'assets/icon_screen.png',
        height: 250, // You can adjust this size if you want
      ),
    );
  }
}
