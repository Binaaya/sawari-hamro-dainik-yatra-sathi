// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sawari/main.dart';

void main() {
  testWidgets('Sawari app loads login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SawariApp());

    // Verify that the login screen is displayed
    expect(find.text('Sawari'), findsOneWidget);
    expect(find.text('Hamro dainik yatra sathi'), findsOneWidget);

    // Verify login button exists
    expect(find.text('Login'), findsOneWidget);

    // Verify input fields exist
    expect(find.byType(TextField), findsWidgets);
  });
}
