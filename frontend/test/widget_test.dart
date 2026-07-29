// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:flinder_flutter/main.dart';
import 'package:flinder_flutter/screens/profile/profile_completion_screen.dart';
import 'package:flinder_flutter/theme/app_theme.dart';

void main() {
  testWidgets('Flinder app shell builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('profile onboarding quiz starts with mixed preference controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: const ProfileCompletionScreen(),
      ),
    );

    expect(find.text('Home basics'), findsOneWidget);
    expect(find.text('Where should we place you?'), findsOneWidget);
    expect(find.text('Room type'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
