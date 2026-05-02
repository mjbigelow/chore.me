// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
//

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
}