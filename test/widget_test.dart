import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/main.dart';
import 'package:nova/screens/login_screen.dart';


void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const NovaApp(initialScreen: LoginScreen(),));

    // First frame
    await tester.pump();

    // Check NOVA text exists (Splash screen)
    expect(find.text('NOVA'), findsOneWidget);
  });
}
