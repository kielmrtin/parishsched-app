import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:churchapp/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen shows sign in and create account actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('ParishSched'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });
}
