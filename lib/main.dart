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

  // 1. Alarm Manager Initialize
  try {
    await AndroidAlarmManager.initialize();
  } catch (e) {
    print("❌ Alarm Manager Error: $e");
  }

  // 2. Firebase & Google Init
  try {
    await Firebase.initializeApp();
    await GoogleSignIn.instance.initialize(
      serverClientId: '252086847838-5u90bhd5g4a5sba6lvdkg9k05phlnfsu.apps.googleusercontent.com',
    );
  } catch (e) {
    print("Firebase Error: $e");
  }

  // 3. Services (Storage, NLP, Notifications)
  try {
    await TaskStorageService().init();



    await NotificationService.init();
    await NotificationService.requestPermissions();
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
      home: initialScreen, // 👈 Battery Wrapper hata diya, ab seedha screen load hogi
    );
  }
}