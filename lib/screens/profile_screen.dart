import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/auth_service.dart';
import '../services/task_storage_service.dart'; // Aapka service import kiya
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TaskStorageService _storageService = TaskStorageService();

  String _username = "Loading...";
  String _email = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final details = await _authService.getUserDetails();
    if (mounted) {
      setState(() {
        _username = details['username'] ?? "User";
        _email = details['email'] ?? "";
      });
    }
  }

  // 🔥 1. INTERNET CHECK (Using your TaskStorageService)
  Future<void> _handleLogoutPress(BuildContext context) async {
    // Aapka banaya hua function use ho raha hai 👇
    bool hasNet = await _storageService.hasInternet();

    if (!hasNet) {
      // Agar net nahi hai -> Warning Dialog
      if (context.mounted) _showNoInternetDialog(context);
    } else {
      // Agar net hai -> Sync & Logout Dialog
      if (context.mounted) _showSyncAndLogoutDialog(context);
    }
  }

  // 🔥 2. NO INTERNET DIALOG (Warning)
  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A2D5F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            const Text('No Internet!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Please connect to the internet to sync your data.\n\nLogging out without internet may cause DATA LOSS for unsaved tasks.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK, I will connect', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context); // Force Logout (Risk)
            },
            child: const Text('Force Logout', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 🔥 3. SYNC & LOGOUT DIALOG
  void _showSyncAndLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSyncing = false;

            return AlertDialog(
              backgroundColor: const Color(0xFF3A2D5F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(
                isSyncing
                    ? 'Syncing your data to cloud...\nPlease wait.'
                    : 'Are you sure you want to log out? We will sync your data to keep it safe.',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                if (!isSyncing)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSyncing ? Colors.grey : Colors.redAccent,
                  ),
                  onPressed: isSyncing
                      ? null
                      : () async {
                    setDialogState(() => isSyncing = true);
                    try {
                      // Aapka banaya hua Sync function 👇
                      print("🔄 Logout Sync start...");
                      await _storageService.syncTasks();

                      if (context.mounted) {
                        await _performLogout(context);
                      }
                    } catch (e) {
                      print("Logout Error: $e");
                      setDialogState(() => isSyncing = false);
                    }
                  },
                  child: isSyncing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sync & Logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper: Asli Logout
  Future<void> _performLogout(BuildContext context) async {
    await _authService.logout();
    await _storageService.clearAllLocalData(); // Aapka clear data function
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2B145E), Color(0xFF4A1B7B), Color(0xFF6A1FB0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF9C6BFF),
                child: Icon(Icons.person, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              Text(_username, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
              const SizedBox(height: 30),

              _buildProfileOption(context, icon: Icons.account_circle_outlined, title: 'Account Information', onTap: () {}),
              _buildProfileOption(context, icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
              _buildProfileOption(context, icon: Icons.palette_outlined, title: 'Appearance', onTap: () {}),
              _buildProfileOption(context, icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
              const SizedBox(height: 30),

              // --- LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogoutPress(context), // Logic yahan connect hai
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentItem: NavItem.profile),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 20),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}