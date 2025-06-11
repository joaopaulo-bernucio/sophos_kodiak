// Testes para a página de configurações do Sophos Kodiak
//
// Este arquivo testa todos os componentes e funcionalidades da tela de configurações,
// incluindo validações, navegação e interações do usuário.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/pages/settings_page.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import 'package:sophos_kodiak/services/auth_service.dart';

void main() {
  group('SettingsPage Widget Tests', () {
    setUp(() {
      // Limpar shared preferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Deve exibir todos os elementos da tela de configurações', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verificar elementos principais
      expect(find.text('Conta'), findsOneWidget);
      expect(find.text('CNPJ'), findsOneWidget);
      expect(find.text('12.345.678/0001-90'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);

      // Verificar ícones
      expect(find.byIcon(Icons.business_rounded), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('Deve alternar visibilidade da senha ao tocar', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'mypassword',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Senha deve estar oculta inicialmente
      expect(find.text('••••••••'), findsOneWidget);
      expect(find.text('mypassword'), findsNothing);

      // Act - Tocar na linha da senha
      await tester.tap(find.text('Senha'));
      await tester.pumpAndSettle();

      // Assert - Senha deve estar visível
      expect(find.text('mypassword'), findsOneWidget);
      expect(find.text('••••••••'), findsNothing);

      // Act - Tocar novamente
      await tester.tap(find.text('Senha'));
      await tester.pumpAndSettle();

      // Assert - Senha deve estar oculta novamente
      expect(find.text('••••••••'), findsOneWidget);
      expect(find.text('mypassword'), findsNothing);
    });

    testWidgets('Deve exibir diálogo para editar nome', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tocar na linha do nome
      await tester.tap(find.text('Nome'));
      await tester.pumpAndSettle();

      // Assert - Diálogo deve aparecer
      expect(find.text('Modificar Nome'), findsOneWidget);
      expect(find.text('Digite seu nome preferido'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('Deve atualizar nome quando confirmado no diálogo', (
      WidgetTester tester,
    ) async {
      // Arrange - Criar um usuário no SharedPreferences para poder atualizá-lo
      final authService = AuthService();
      final usuario = Usuario(
        cnpj: '12.345.678/0001-90',
        nomePreferido: 'João Silva',
        ultimoLogin: DateTime.now(),
      );
      await authService.salvarUsuario(usuario);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tocar na linha do nome
      await tester.tap(find.text('Nome'));
      await tester.pumpAndSettle();

      // Assert - Nome original deve estar visível no ListTile (não no TextField)
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('João Silva'),
        ),
        findsOneWidget,
      );

      // Act - Digitar novo nome
      await tester.enterText(find.byType(TextField), 'Maria Santos');
      await tester.pumpAndSettle();

      // Act - Confirmar
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Assert - Nome deve ter sido atualizado no ListTile
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Maria Santos'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('João Silva'),
        ),
        findsNothing,
      );
    });

    testWidgets('Deve exibir diálogo de confirmação ao tocar em Sair', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tocar em Sair
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      // Assert - Diálogo de confirmação deve aparecer
      expect(find.text('Confirmar Saída'), findsOneWidget);
      expect(
        find.text('Tem certeza de que deseja sair da sua conta?'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(
        find.text('Sair'),
        findsNWidgets(2),
      ); // Um no botão original e outro no diálogo
    });

    testWidgets('Deve usar cores corretas do design system', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verificar cores do Scaffold
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(const Color(0xFF171717)));

      // Assert - Verificar cores da AppBar
      final appBar = find.byType(AppBar);
      final appBarWidget = tester.widget<AppBar>(appBar);
      expect(appBarWidget.backgroundColor, equals(const Color(0xFF171717)));
    });

    testWidgets('Deve navegar para LoginPage ao confirmar logout', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
          routes: {'/login': (context) => const LoginPage()},
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tocar em Sair
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      // Act - Confirmar logout
      final sairButtons = find.text('Sair');
      await tester.tap(sairButtons.last); // Tocar no botão do diálogo
      await tester.pumpAndSettle();

      // Assert - Deve navegar para a tela de login
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('SettingsPage Accessibility Tests', () {
    testWidgets('Deve ter descrições acessíveis nos elementos', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsPage(
            cnpj: '12.345.678/0001-90',
            password: 'password123',
            userName: 'João Silva',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verificar se elementos importantes são encontrados
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
    });
  });
}
