import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sophos_kodiak/app.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de Login', () {
    setUp(() async {
      // Limpar dados reais antes de cada teste
      await UserStorageService.clearUserData();
    });

    testWidgets('deve completar fluxo de login com sucesso', (
      WidgetTester tester,
    ) async {
      // Inicializar aplicação
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Verificar que está na tela de login
      expect(find.text('SOPHOS'), findsOneWidget);
      expect(find.text('KODIAK'), findsOneWidget);

      // Preencher campos de login
      final cnpjField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(cnpjField, '12345678000190');
      await tester.pump();

      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Verificar formatação do CNPJ
      expect(find.text('12.345.678/0001-90'), findsOneWidget);

      // Marcar "Lembrar de mim"
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      // Fazer login
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verificar que diálogo de nome preferido apareceu
      expect(find.text('Nome Preferido'), findsOneWidget);
      expect(find.text('Como gostaria de ser chamado?'), findsOneWidget);

      // Inserir nome preferido
      final nameField = find.byType(TextFormField).last;
      await tester.enterText(nameField, 'João Silva');
      await tester.pump();

      // Confirmar nome
      final confirmButton = find.text('CONFIRMAR');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verificar que navegou para tela principal
      // (Adapte este teste baseado na implementação real da navegação)
      expect(find.text('Nome Preferido'), findsNothing);
    });

    testWidgets('deve rejeitar login com credenciais inválidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Preencher com credenciais inválidas
      await tester.enterText(
        find.byType(TextFormField).first,
        '11.111.111/1111-11',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tentar fazer login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar erro
      expect(find.text('CNPJ inválido'), findsOneWidget);
    });

    testWidgets('deve validar campos obrigatórios', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Tentar fazer login sem preencher campos
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar que algum erro foi mostrado (adapte baseado na implementação)
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Fluxo de Navegação entre Telas', () {
    testWidgets('deve navegar através das rotas principais', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Verificar rota inicial (login)
      expect(find.text('SOPHOS'), findsOneWidget);
      expect(find.text('KODIAK'), findsOneWidget);

      // Este teste pode ser expandido para incluir navegação real
      // baseada na implementação específica das suas telas
    });
  });

  group('Persistência de Dados', () {
    testWidgets(
      'deve lembrar credenciais quando "Lembrar de mim" está marcado',
      (WidgetTester tester) async {
        // Primeiro login com "Lembrar de mim"
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Fazer login completo
        await tester.enterText(
          find.byType(TextFormField).first,
          '12345678000190',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Marcar "Lembrar de mim"
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Inserir nome e confirmar
        if (find.text('Nome Preferido').evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextFormField).last, 'João Silva');
          await tester.tap(find.text('CONFIRMAR'));
          await tester.pumpAndSettle();
        }

        // Simular restart da aplicação
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();

        // Verificar que credenciais foram lembradas
        // (Adapte baseado na implementação real)
        final cnpjField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        expect(cnpjField.controller?.text, isNotEmpty);
      },
    );
  });

  group('Tratamento de Erros', () {
    testWidgets('deve lidar graciosamente com interações rápidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Preencher campos válidos
      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Múltiplos toques rápidos no botão
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verificar que apenas um diálogo apareceu
      expect(find.text('Nome Preferido'), findsOneWidget);
    });

    testWidgets('deve recuperar de estados de erro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Primeira tentativa com erro
      await tester.enterText(
        find.byType(TextFormField).first,
        '11.111.111/1111-11',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar erro
      expect(find.text('CNPJ inválido'), findsOneWidget);

      // Fechar diálogo de erro (se existir)
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      // Segunda tentativa com dados corretos
      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verificar sucesso
      expect(find.text('Nome Preferido'), findsOneWidget);
    });
  });

  group('Acessibilidade', () {
    testWidgets('deve ter elementos acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Verificar que elementos têm labels semânticos
      expect(find.bySemanticsLabel('Campo CNPJ'), findsOneWidget);
      expect(find.bySemanticsLabel('Campo Senha'), findsOneWidget);
      expect(find.bySemanticsLabel('Botão entrar'), findsOneWidget);
    });
  });

  group('Performance', () {
    testWidgets('deve carregar e responder rapidamente', (
      WidgetTester tester,
    ) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verificar tempo de carregamento (menos de 3 segundos para integração)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      // Testar responsividade de interações
      final interactionStopwatch = Stopwatch()..start();

      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.pump();

      interactionStopwatch.stop();

      // Interações devem ser rápidas (menos de 100ms)
      expect(interactionStopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
