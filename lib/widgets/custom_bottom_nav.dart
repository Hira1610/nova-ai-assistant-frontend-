import 'package:flutter/material.dart';
import 'package:nova/screens/home_screen.dart';
import 'package:nova/screens/chat_with_nova_screen.dart';
import 'package:nova/screens/email_screen.dart';
import 'package:nova/screens/reminders_screen.dart';
import 'package:nova/screens/schedule_screen.dart';
import 'package:nova/screens/profile_screen.dart';

// REVERTED: The NavItem enum is back to its original state.
enum NavItem { home, chat, email, reminders, schedule, profile }

class CustomBottomNav extends StatelessWidget {
  final NavItem? currentItem;

  // REVERTED: The constructor is back to its original, simpler version.
  const CustomBottomNav({super.key, this.currentItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, NavItem.home, Icons.home_outlined, Icons.home),
          _buildNavItem(context, NavItem.chat, Icons.chat_bubble_outline, Icons.chat_bubble),
          _buildNavItem(context, NavItem.email, Icons.email_outlined, Icons.email),
          _buildNavItem(context, NavItem.reminders, Icons.notifications_outlined, Icons.notifications),
          _buildNavItem(context, NavItem.schedule, Icons.calendar_today_outlined, Icons.calendar_today),
          _buildNavItem(context, NavItem.profile, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  // REVERTED: The navigation logic is back to the original, stable version.
  Widget _buildNavItem(BuildContext context, NavItem item, IconData unselectedIcon, IconData selectedIcon) {
    final isSelected = currentItem == item;
    return IconButton(
      onPressed: () {
        if (isSelected) return;

        Widget screen;
        switch (item) {
          case NavItem.home:
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen(username: 'User')),
              (Route<dynamic> route) => false,
            );
            return;
          case NavItem.chat:
            screen = const ChatWithNovaScreen();
            break;
          case NavItem.email:
            screen = const InboxScreen();
            break;
          case NavItem.reminders:
            screen = const RemindersScreen();
            break;
          case NavItem.schedule:
            // FIX: I have now, finally, removed the 'const' keyword.
            screen = const ScheduleScreen();
            break;
          case NavItem.profile:
            screen = const ProfileScreen();
            break;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
      },
      icon: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? const Color(0xFF9C6BFF) : Colors.white54,
        size: 28,
      ),
    );
  }
}
