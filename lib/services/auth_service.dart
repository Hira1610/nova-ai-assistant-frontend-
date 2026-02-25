import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // final String baseUrl = "http://10.0.2.2:8000/api/v1/auth";
  final String baseUrl = "http://192.168.100.17:8000/api/v1/auth";
  // --- 1. REGISTER (Same as before) ---
  Future<Map<String, dynamic>> register(String email, String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // --- 2. VERIFY OTP (Updated) ---
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Backend ab user_id, username, email bhej raha hai
      await _saveSession(
        data['token'],
        data['user_id'],
        data['username'],
        data['email'],
      );
    }
    return data;
  }

  // --- 3. MANUAL LOGIN (Updated) ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'provider': 'email',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == 'success') {
      await _saveSession(
        data['token'],
        data['user_id'],
        data['username'],
        data['email'],
      );
    }
    return data;
  }

  // --- 4. GOOGLE LOGIN (Updated) ---
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': 'google',
        'idToken': idToken,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      await _saveSession(
        data['token'],
        data['user_id'],
        data['username'],
        data['email'],
      );
    }
    return data;
  }

  // --- 5. SESSION MANAGEMENT (Main Change) ---
  Future<void> _saveSession(String token, String userId, String username, String email) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('authToken', token);
    await prefs.setString('userId', userId);
    await prefs.setString('username', username); // Username saved
    await prefs.setString('email', email);       // Email saved
    await prefs.setBool('isLoggedIn', true);

    print("Session Saved: $username ($email)");
  }

  // --- 6. GET USER DATA (Helper Function) ---
  // Is function ko poori app mein kahin bhi use kar sakte hain data lene ke liye
  Future<Map<String, String>> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "token": prefs.getString('authToken') ?? "",
      "id": prefs.getString('userId') ?? "",
      "username": prefs.getString('username') ?? "Guest",
      "email": prefs.getString('email') ?? "",
    };
  }

  // --- 7. LOGOUT ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Sab kuch delete kar dega
  }
}