import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sophos_kodiak/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deve carregar o app sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Debug: ver que widgets estão na tela
    final allWidgets = find.descendant(
      of: find.byType(MaterialApp),
      matching: find.byWidgetPredicate((widget) => true),
    );

    print('Widgets encontrados: ${allWidgets.evaluate().length}');

    // Verificar se o MaterialApp foi criado
    expect(find.byType(MaterialApp), findsOneWidget);

    // Procurar por qualquer texto que deveria estar na tela
    final sophosText = find.textContaining('SOPHOS');
    final welcomeText = find.textContaining('Bem-vindo');
    final loginText = find.textContaining('login');

    print('SOPHOS text found: ${sophosText.evaluate().length}');
    print('Welcome text found: ${welcomeText.evaluate().length}');
    print('Login text found: ${loginText.evaluate().length}');

    // Procurar por tipos de widgets específicos
    final textFields = find.byType(TextField);
    final textFormFields = find.byType(TextFormField);
    final buttons = find.byType(ElevatedButton);

    print('TextField found: ${textFields.evaluate().length}');
    print('TextFormField found: ${textFormFields.evaluate().length}');
    print('ElevatedButton found: ${buttons.evaluate().length}');

    // Teste básico: app não deve ter travado
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
