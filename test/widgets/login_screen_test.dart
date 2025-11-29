import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_circle/features/auth/presentation/screens/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen displays welcome text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify welcome text
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Login to continue managing your savings.'), findsOneWidget);
    });

    testWidgets('LoginScreen has email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify two text fields exist (email and password)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('LoginScreen has login button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify login button
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('LoginScreen has forgot password link', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify forgot password link
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('LoginScreen has remember me checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify checkbox and label
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Remember Me'), findsOneWidget);
    });

    testWidgets('Email field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      
      // Enter text
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.pump();

      // Verify controller has the text (bypassing visual obscurement issues)
      final formField = tester.widget<TextFormField>(find.byKey(const Key('password_field')));
      expect(formField.controller!.text, 'password123');
    });
  });
}
