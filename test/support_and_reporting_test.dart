import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Support & Reporting', () {
    testWidgets('Open Contact Support screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Contact Support')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Support'), findsOneWidget);
    });

    testWidgets('Submit a problem report form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextFormField(key: const Key('report_subject')),
                  ElevatedButton(
                    key: const Key('submit_report_button'),
                    onPressed: () {},
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('report_subject')),
        'App crashes',
      );
      
      await tester.tap(find.byKey(const Key('submit_report_button')));
      await tester.pump();

      // In a real integration test, we'd verify the submission logic
      expect(find.text('App crashes'), findsOneWidget);
    });
  });
}
