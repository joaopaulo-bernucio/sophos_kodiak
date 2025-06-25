import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/app.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('Smoke Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });
    testWidgets('App deve inicializar sem erros', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await WidgetTestHelpers.pumpAndSettle(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('SOPHOS KODIAK'), findsOneWidget);
    });

    testWidgets('App deve ter configuração básica correta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Sophos Kodiak'));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
      expect(materialApp.initialRoute, equals('/login'));
    });
  });
}
