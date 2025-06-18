import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/app.dart';
import 'helpers/test_helpers.dart';

void main() {
  group('Smoke Tests', () {
    testWidgets('App deve inicializar sem erros', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await waitForUI(tester);

      expectWidgetPresent(MaterialApp);
      expectTextPresent('SOPHOS');
      expectTextPresent('KODIAK');
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
