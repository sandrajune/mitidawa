import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitidawa/screens/home_screen.dart';

void main() {
  testWidgets('Home screen renders two primary actions and chatbot FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome to MitiDawa'), findsOneWidget);
    expect(find.text('Plant Catalogue'), findsOneWidget);
    expect(find.text('Health Conditions'), findsOneWidget);
    expect(find.byIcon(Icons.spa), findsWidgets);
  });
}
