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
  // 1. Flutter Engine Ko Taiyar Karein
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase & Google Sign-In Init
  try {
    await Firebase.initializeApp();
    // Web Client ID configure karein
    await GoogleSignIn.instance.initialize(
      serverClientId: '252086847838-5u90bhd5g4a5sba6lvdkg9k05phlnfsu.apps.googleusercontent.com',
    );
  } catch (e) {
    print("Firebase/Google Init Error: $e");
  }

  // 3. Local Services (Hive, Notifications)
  try {
    // Hive Initialization
    final storageService = TaskStorageService();
    await storageService.init();

    // Notification Service Initialization
    await NotificationService.init();

    // 🔥 Permissions Request
    await NotificationService.requestPermissions();
    // NLP sevice initialization
    await NLPService().initModel();

    print("NOVA Services Initialized Successfully! ✅");
  } catch (e) {
    print("Services Init Error: $e");
  }

  // 4. Session & Navigation Logic
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

  runApp(
    NovaApp(initialScreen: screen),
  );
}

class NovaApp extends StatefulWidget {
  final Widget initialScreen;
  const NovaApp({super.key, required this.initialScreen});

  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBatteryOptimizations();
    });
  }

  Future<void> _checkBatteryOptimizations() async {
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Important: Enable Notifications'),
          content: const Text(
              'For reminders to work correctly, please allow the app to run in the background. Tap \'Open Settings\' and disable battery optimization for NOVA.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

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
      home: widget.initialScreen,
    );
  }
}
