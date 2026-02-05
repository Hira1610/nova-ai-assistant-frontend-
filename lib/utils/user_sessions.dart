import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // Global function user ka data lene ke liye
  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "username": prefs.getString('username') ?? "User",
      "email": prefs.getString('email') ?? "",
      "userId": prefs.getString('userId') ?? "",
      "token": prefs.getString('authToken') ?? "",
    };
  }

  // Check karne ke liye ke user login hai ya nahi
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Logout ke waqt sab clear karne ke liye
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}