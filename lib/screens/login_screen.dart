import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'sign_in_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isPasswordVisible = false;

  void _validateAndLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (_emailController.text.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_emailController.text.contains('@')) {
        _emailError = 'Please enter a valid email';
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Please enter your password';
      }
    });

    if (_emailError == null && _passwordError == null) {
      final email = _emailController.text;
      final username = email.split('@').first;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(username: username)),
      );
    }
  }

  void _showGoogleSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A2D5F),
        title: const Text('Continue with Google', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to continue signing in with your Google account?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen(username: 'Google User')),
              );
            },
            child: const Text('Continue', style: TextStyle(color: Color(0xFF9C6BFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkPurple, AppColors.lightPurple],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const Text("Welcome Back", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Sign in to continue", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 40),
                    _inputField(
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hint: "Email address",
                      errorText: _emailError,
                    ),
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
                        onPressed: _validateAndLogin,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.lightPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white54)),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR", style: TextStyle(color: Colors.white54))),
                        const Expanded(child: Divider(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _showGoogleSignInDialog,
                        icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.lightPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
                        child: const Text(
                          "Didn't have an account ? Sign In",
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
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
          child: TextField(controller: controller, obscureText: isPassword, style: const TextStyle(color: Colors.white), decoration: InputDecoration(icon: Icon(icon, color: Colors.white70), hintText: hint, hintStyle: const TextStyle(color: Colors.white70), border: InputBorder.none, suffixIcon: suffixIcon)),
        ),
      ],
    );
  }
}
