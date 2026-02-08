// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:safeplate/main.dart';

void main() {
  testWidgets('Allergen screen is shown on first launch', (WidgetTester tester) async {
    // Set up mock shared preferences for first launch
    SharedPreferences.setMockInitialValues({'profile_setup_complete': false});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The first frame is a loading indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Re-render after the future has completed.
    await tester.pumpAndSettle();

    // Verify that the AllergenScreen is shown.
    expect(find.text('What are you avoiding?'), findsOneWidget);
  });
}
