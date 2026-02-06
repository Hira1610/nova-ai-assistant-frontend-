import 'package:flutter/material.dart';
import 'package:nova/screens/tasks_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chat_with_nova_screen.dart';
import '../screens/inbox_screen.dart';
import '../screens/todo_screen.dart';
import '../screens/profile_screen.dart';

enum NavItem { home, chat, email, tasks, profile,todo, meetings }

class CustomBottomNav extends StatelessWidget {
  final NavItem currentItem;

  const CustomBottomNav({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A1B7B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, NavItem.home, Icons.home_outlined, Icons.home),
          _buildNavItem(context, NavItem.chat, Icons.chat_bubble_outline, Icons.chat_bubble),
          _buildNavItem(context, NavItem.email, Icons.email_outlined, Icons.email),
          _buildNavItem(context, NavItem.todo, Icons.check_box_outline_blank, Icons.check_box),
          _buildNavItem(context, NavItem.tasks, Icons.notifications_outlined , Icons.notifications),
          _buildNavItem(context, NavItem.profile, Icons.person_outline, Icons.person),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item, IconData unselectedIcon, IconData selectedIcon) {
    final isSelected = currentItem == item;
    return IconButton(
      onPressed: () {
        if (isSelected) return; // Don't navigate to the same screen

        Widget screen;
        switch (item) {
          case NavItem.home:
            // Correctly navigate to the home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen(username: 'User')), // Assuming a default username
              (Route<dynamic> route) => false,
            );
            return;
          case NavItem.chat:
            screen = const ChatWithNovaScreen();
            break;
          case NavItem.email:
            screen = const InboxScreen();
            break;
          case NavItem.todo:
            screen = const TodoScreen();
            break;
          case NavItem.profile:
            screen = const ProfileScreen();
            break;
          case NavItem.tasks:
            screen = const TasksScreen();
            break;
          case NavItem.meetings:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
        // Use pushReplacement to avoid building up a large stack of screens
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
