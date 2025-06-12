// Testes para a página de login do Sophos Kodiak
//
// Este arquivo testa todos os componentes e funcionalidades da tela de login,
// incluindo validações, navegação e interações do usuário.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('Deve exibir todos os elementos da tela de login', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar elementos principais
      expect(find.text('SOPHOS KODIAK'), findsOneWidget);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
      expect(find.text('Acesse sua conta'), findsOneWidget);

      // Verificar campos de entrada
      expect(find.text('CNPJ'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Digite o seu CNPJ'), findsOneWidget);
      expect(find.text('Digite a sua senha'), findsOneWidget);

      // Verificar botão de login
      expect(find.text('ENTRAR'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);

      // Verificar checkbox "Lembrar-me"
      expect(find.text('Lembrar-me'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('Deve aplicar cores e estilos do design system', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se usa as constantes de design
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      // Verificar se o background é escuro
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.background));
    });

    testWidgets('Deve formatar CNPJ automaticamente durante digitação', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Encontrar campo CNPJ pelo hint text
      final cnpjField = find.widgetWithText(TextField, 'Digite o seu CNPJ');

      // Act - Digitar CNPJ completo
      await tester.enterText(cnpjField, '12345678000195');
      await tester.pump();

      // Assert - Verificar formatação completa
      final cnpjController = tester.widget<TextField>(cnpjField).controller;
      expect(cnpjController!.text, equals('12.345.678/0001-95'));
    });

    testWidgets('Deve mostrar/ocultar senha ao clicar no ícone', (
      WidgetTester tester,
    ) async {
      // Arrange - Configurar tamanho maior de tela
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Encontrar o ícone de visibilidade da senha (inicialmente visibility, pois senha está oculta)
      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);

      // Act - Clicar no ícone para mostrar senha
      await tester.tap(visibilityIcon, warnIfMissed: false);
      await tester.pump();

      // Assert - Verificar se mudou para ícone de visibilidade desligada (senha agora visível)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Act - Clicar novamente para ocultar senha
      await tester.tap(find.byIcon(Icons.visibility_off), warnIfMissed: false);
      await tester.pump();

      // Assert - Verificar se voltou para ícone de visibilidade
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('Deve permitir entrada de dados nos campos', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Act - Preencher campos com dados válidos
      final cnpjField = find.widgetWithText(TextField, 'Digite o seu CNPJ');
      final passwordField = find.widgetWithText(
        TextField,
        'Digite a sua senha',
      );

      await tester.enterText(cnpjField, '12345678000195');
      await tester.enterText(passwordField, 'senha123456');
      await tester.pump();

      // Assert - Verificar se dados foram preenchidos corretamente
      final cnpjController = tester.widget<TextField>(cnpjField).controller;
      final passwordController = tester
          .widget<TextField>(passwordField)
          .controller;

      expect(cnpjController!.text, equals('12.345.678/0001-95'));
      expect(passwordController!.text, equals('senha123456'));
    });
  });

  group('LoginPage Validation Tests', () {
    testWidgets('Deve limitar CNPJ a 14 dígitos', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final cnpjField = find.widgetWithText(TextField, 'Digite o seu CNPJ');

      // Act - Inserir mais de 14 dígitos
      await tester.enterText(cnpjField, '123456789001951234567890');
      await tester.pump();

      // Assert - Verificar se foi limitado a 14 dígitos formatados
      final cnpjController = tester.widget<TextField>(cnpjField).controller;
      expect(cnpjController!.text, equals('12.345.678/9001-95'));
    });

    testWidgets('Deve filtrar apenas números no CNPJ', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final cnpjField = find.widgetWithText(TextField, 'Digite o seu CNPJ');

      // Act - Inserir caracteres inválidos
      await tester.enterText(cnpjField, 'abc123def456');
      await tester.pump();

      // Assert - Verificar se apenas números foram aceitos e formatados
      final cnpjController = tester.widget<TextField>(cnpjField).controller;
      expect(cnpjController!.text, matches(RegExp(r'^[\d.\/-]*$')));
    });
  });

  group('LoginPage Performance Tests', () {
    testWidgets('Deve carregar rapidamente', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Assert
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Menos que 1 segundo
    });

    testWidgets('Deve responder rapidamente a entrada de texto', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final cnpjField = find.widgetWithText(TextField, 'Digite o seu CNPJ');
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.enterText(cnpjField, '12345678000195');
      await tester.pump();

      // Assert
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Menos que 200ms
    });

    testWidgets('Deve permitir marcar/desmarcar checkbox Lembrar-me', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Encontrar o checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verificar estado inicial (desmarcado)
      Checkbox checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, equals(false));

      // Act - Marcar checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Assert - Verificar se foi marcado
      checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, equals(true));

      // Act - Desmarcar checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Assert - Verificar se foi desmarcado
      checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, equals(false));
    });
  });
}
