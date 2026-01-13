import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LoadingRobot extends StatelessWidget {
  const LoadingRobot({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircleAvatar(
        radius: 55,
        backgroundColor: AppColors.lightPurple,
        child: Icon(
          Icons.smart_toy,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
}
