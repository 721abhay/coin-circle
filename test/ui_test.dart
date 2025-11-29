import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_circle/features/profile/presentation/screens/personal_details_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('UI/UX Tests', () {
    testWidgets('Personal Details Screen renders correctly', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PersonalDetailsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify UI elements exist
      expect(find.text('Personal Details'), findsOneWidget);
    });

    testWidgets('Form validation logic', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                key: const Key('pan_field'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(value)) {
                    return 'Invalid PAN format';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Test invalid PAN
      await tester.enterText(find.byKey(const Key('pan_field')), 'INVALID');
      await tester.pump();
      
      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();
      
      // Validation should fail
      expect(find.text('Invalid PAN format'), findsOneWidget);
    });
  });
}
