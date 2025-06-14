// Este é um teste básico para garantir que o Flutter encontre pelo menos um teste
// quando executar flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sophos_kodiak/app.dart';

void main() {
  testWidgets('App starts correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that the app initializes without throwing errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
