import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('Login Page Tests', () {
    testWidgets('LoginPage deve renderizar corretamente', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Assert - Verificar elementos básicos da tela de login
      expect(find.byType(LoginPage), findsOneWidget);

      // Verificar se campos de entrada existem
      expect(find.byType(TextField), findsAtLeast(1));

      // Verificar se botões existem
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('Campos de CNPJ e senha devem estar presentes', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Assert - Verificar campos específicos
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2)); // CNPJ e senha
    });

    testWidgets('Botão de login deve estar presente', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Assert - Verificar se há pelo menos um botão
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('Deve aceitar entrada de texto nos campos', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Act - Inserir texto no primeiro campo (CNPJ)
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await enterText(tester, textFields.first, '12.345.678/0001-90');
        await waitForUI(tester);

        // Assert - Verificar se o texto foi inserido
        expect(find.text('12.345.678/0001-90'), findsOneWidget);
      }
    });

    testWidgets('Interface deve ter elementos visuais básicos', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Assert - Verificar elementos visuais
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsAtLeast(1));
    });

    testWidgets('Deve lidar com interações básicas sem erros', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(const LoginPage()));
      await waitForUI(tester);

      // Act - Tentar tocar em elementos interativos
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tapWidget(tester, buttons.first);
        await waitForUI(tester);
      }

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tapWidget(tester, textFields.first);
        await waitForUI(tester);
      }

      // Assert - A página deve continuar funcional após interações
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}
