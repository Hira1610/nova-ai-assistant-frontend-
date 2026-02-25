import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'welcome_screen.dart'; // Import WelcomeScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndLoginStatus(); // Renamed for clarity
  }

  Future<void> _checkOnboardingAndLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getString('authToken') != null;
    // Get the flag that the WelcomeScreen sets. Default to false if it doesn't exist.
    final bool hasVisited = prefs.getBool('isVisited') ?? false;

    // Wait for 2 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (isLoggedIn) {
        // User is already logged in, go straight to home.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen(username: 'User')),
        );
      } else {
        // User is not logged in. Check if they are a new or returning user.
        if (hasVisited) {
          // Returning user, go to login.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          // New user, go to the welcome screen for the first time.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Image.asset('assets/icon_screen.png', height: 150),
        ),
      ),
    );
  }
}
