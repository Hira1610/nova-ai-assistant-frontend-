import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/main.dart';
import 'package:nova/screens/login_screen.dart';
import 'package:nova/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Shows WelcomeScreen for new users', (WidgetTester tester) async {
    // Simulate a new user who has never visited before.
    SharedPreferences.setMockInitialValues({'isVisited': false});

    // We need to pass a screen to the app. For this test, we can pass any
    // simple screen, like a placeholder.
    await tester.pumpWidget(const NovaApp(initialScreen: WelcomeScreen()));

    // Verify that the WelcomeScreen is shown.
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Shows LoginScreen for returning users', (WidgetTester tester) async {
    // Simulate a returning user who has visited but not logged in.
    SharedPreferences.setMockInitialValues({'isVisited': true, 'isLoggedIn': false});

    await tester.pumpWidget(const NovaApp(initialScreen: LoginScreen()));

    // Verify that the LoginScreen is shown.
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
