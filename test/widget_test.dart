import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vez/main.dart';

void main() {
  testWidgets('App loads and shows loading indicator', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the LoadingPage shows a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}