import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vez/main.dart';
import 'package:vez/screens/loading_screen.dart';

void main() {
  testWidgets('App boots into the loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoadingPage), findsOneWidget);
  });
}
