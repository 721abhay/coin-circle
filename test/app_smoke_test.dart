// test/app_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coin_circle/features/auth/presentation/screens/onboarding_screen.dart';

void main() {
  testWidgets('App smoke test - verify onboarding screen loads', (WidgetTester tester) async {
    // Set a large screen size to avoid overflows
    tester.view.physicalSize = const Size(2000, 3000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    
    // Verify that the OnboardingScreen widget is present
    expect(find.byType(OnboardingScreen), findsOneWidget);
    
    // Verify initial content
    expect(find.text('Create or Join Savings Pools'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    
    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
