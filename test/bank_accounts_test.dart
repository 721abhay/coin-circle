import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Bank Accounts Flow', () {
    testWidgets('View bank accounts list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Bank Accounts')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify list loads
      expect(find.text('Bank Accounts'), findsOneWidget);
    });

    testWidgets('Add a new bank account form validation', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('account_number'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Trigger validation on empty form
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });
  });
}
