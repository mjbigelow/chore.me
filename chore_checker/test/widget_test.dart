// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
//
// Read more about testing Widgets: https://flutter.dev/docs/testing
// Read more about integration testing: https://flutter.dev/docs/testing/integration-tests/integration_tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chore_checker/main.dart';

void main() {
  testWidgets('ChoreScreen displays TabBar with Overview and Kids tabs', (WidgetTester tester) async {
    await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);
    final supabase = Supabase.instance.client;
    await supabase.auth.signInAnonymously();
    await tester.pumpWidget(MaterialApp(home: ChoreScreen()));
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Kids'), findsOneWidget);
  });

  testWidgets('EditChoreDialog initializes with chore data and calls onUpdate on update', (WidgetTester tester) async {
    final chore = {'task': 'Test Chore', 'points': 10};
    String capturedTask = '';
    int capturedPoints = 0;
    final onUpdate = (String task, int points) {
      capturedTask = task;
      capturedPoints = points;
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => EditChoreDialog(
                  chore: chore,
                  onUpdate: onUpdate,
                ),
              ),
              child: Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Check initial values
    expect(find.text('Test Chore'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // Simulate edits
    await tester.enterText(find.byType(TextField).first, 'Updated Chore');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '20');
    await tester.pump();

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(capturedTask, 'Updated Chore');
    expect(capturedPoints, 20);
  });
}