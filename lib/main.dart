import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:nova/screens/home_screen.dart';
import 'package:nova/screens/login_screen.dart';
import 'package:nova/screens/welcome_screen.dart';
import 'package:nova/services/nlp_service.dart';
import 'package:nova/services/notification_service.dart';
import 'package:nova/services/reminders_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Alarm Manager
  try {
    await AndroidAlarmManager.initialize();
    print("⏰ Alarm Manager Initialized!");
  } catch (e) {
    print("❌ Alarm Manager Init Error: $e");
  }

  // 2. Firebase
  try {
    await Firebase.initializeApp();
    await GoogleSignIn.instance.initialize(
      serverClientId: '252086847838-5u90bhd5g4a5sba6lvdkg9k05phlnfsu.apps.googleusercontent.com',
    );
  } catch (e) {
    print("Firebase/Google Init Error: $e");
  }

  // 3. Services (Storage, Notifications, NLP)
  try {
    await TaskStorageService().init();
    await NotificationService.init();
    await NLPService().initModel();
    print("✅ NOVA Services Initialized!");
  } catch (e) {
    print("❌ Services Init Error: $e");
  }

  // 4. Session Logic
  final prefs = await SharedPreferences.getInstance();
  bool isVisited = prefs.getBool('isVisited') ?? false;
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String username = prefs.getString('username') ?? "User";

  Widget screen;
  if (!isVisited) {
    screen = const WelcomeScreen();
  } else if (isLoggedIn) {
    screen = HomeScreen(username: username);
  } else {
    screen = const LoginScreen();
  }

  runApp(NovaApp(initialScreen: screen));
}

class NovaApp extends StatelessWidget {
  final Widget initialScreen;
  const NovaApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVA',
      theme: ThemeData(
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      // 🔥 Wrapper use kiya hai taake context ka masla hal ho jaye
      home: BatteryOptimizationWrapper(child: initialScreen),
    );
  }
}

// --- Naya Wrapper Widget jo context crash ko bachayega ---
class BatteryOptimizationWrapper extends StatefulWidget {
  final Widget child;
  const BatteryOptimizationWrapper({super.key, required this.child});

  @override
  State<BatteryOptimizationWrapper> createState() => _BatteryOptimizationWrapperState();
}

class _BatteryOptimizationWrapperState extends State<BatteryOptimizationWrapper> {
  @override
  void initState() {
    super.initState();
    // PostFrameCallback zaroori hai taake UI render hone ke baad dialog aaye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimizations();
    });
  }

  Future<void> _checkBatteryOptimizations() async {
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied && mounted) {
      showDialog(
        context: context, // Ab ye context MaterialApp ke niche hai (Safe)
        builder: (context) => AlertDialog(
          title: const Text('Jarvis Power Mode'),
          content: const Text(
              'Reminders aur Voice alerts ke liye NOVA ko background mein chalne ki ijazat dein.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Baad mein'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('Ijazat Dein'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}