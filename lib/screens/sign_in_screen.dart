import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- REGISTRATION LOGIC ---
  void _validateAndSignIn() async {
    if (!mounted) return;
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Please enter your username' : null;
      _emailError = _emailController.text.isEmpty || !_emailController.text.contains('@')
          ? 'Please enter a valid email' : null;
      _passwordError = _passwordController.text.isEmpty ? 'Please enter your password' : null;
    });

    if (_nameError == null && _emailError == null && _passwordError == null) {
      setState(() => _isLoading = true);

      try {
        final result = await _authService.register(
          _emailController.text.trim(),
          _nameController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (result['email'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your email!")),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(email: _emailController.text.trim()),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['detail'] ?? "Registration failed"), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- GOOGLE SIGN IN (FIXED CRASH) ---
  void _handleGoogleSignIn() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      // Google Sign-In Popup
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw "Google ID Token generation failed.";

      // Backend API Call (Saves session automatically in SharedPreferences)
      final res = await _authService.googleLogin(idToken);

      // 🔥 CRITICAL FIX: Check if widget is still in tree before updating UI
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              username: res['username'] ?? googleUser.displayName ?? "User",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['detail'] ?? "API Login Failed"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Google Sign-In Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkPurple, AppColors.lightPurple],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 20),
                    const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Sign up to get started", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 40),
                    _inputField(controller: _nameController, icon: Icons.person_outline, hint: "Username", errorText: _nameError),
                    const SizedBox(height: 20),
                    _inputField(controller: _emailController, icon: Icons.email_outlined, hint: "Email address", errorText: _emailError),
                    const SizedBox(height: 20),
                    _inputField(
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      hint: "Password",
                      isPassword: !_isPasswordVisible,
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _validateAndSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white54)),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR", style: TextStyle(color: Colors.white54))),
                        Expanded(child: Divider(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                        label: const Text('Continue with Google', style: TextStyle(fontSize: 16, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.lightPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Already have an account? Log In",
                          style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({required IconData icon, required String hint, bool isPassword = false, TextEditingController? controller, String? errorText, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null) Padding(padding: const EdgeInsets.only(left: 20, bottom: 4), child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(38),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: errorText != null ? Colors.redAccent : Colors.transparent),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.white70),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}