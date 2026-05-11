import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permas_hub_system/forgot_password_screen.dart';
import 'package:permas_hub_system/register_screen.dart';

void main() {
  testWidgets('registration validates required Sprint 2 fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);
  });

  testWidgets('registration requires terms agreement before Firebase submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test Member');
    await tester.enterText(fields.at(1), 'member@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');

    await tester.ensureVisible(find.text('CREATE ACCOUNT'));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pump();

    expect(
      find.text('Please agree to the terms and conditions.'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password validates email before reset request', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    await tester.tap(find.text('SEND RESET EMAIL'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
  });
}
