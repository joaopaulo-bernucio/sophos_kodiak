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
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      expect(find.text('SOPHOS'), findsOneWidget);
      expect(find.text('KODIAK'), findsOneWidget);
      final cnpjField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(cnpjField, '12345678000190');
      await tester.pump();
      await tester.enterText(passwordField, 'password123');
      await tester.pump();
      expect(find.text('12.345.678/0001-90'), findsOneWidget);
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pump();
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      expect(find.text('Nome Preferido'), findsOneWidget);
      expect(find.text('Como gostaria de ser chamado?'), findsOneWidget);
      final nameField = find.byType(TextFormField).last;
      await tester.enterText(nameField, 'João Silva');
      await tester.pump();
      final confirmButton = find.text('CONFIRMAR');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(find.text('Nome Preferido'), findsNothing);
    });

    testWidgets('deve rejeitar login com credenciais inválidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        '11.111.111/1111-11',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('CNPJ inválido'), findsOneWidget);
    });

    testWidgets('deve validar campos obrigatórios', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Fluxo de Navegação entre Telas', () {
    testWidgets('deve navegar através das rotas principais', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      expect(find.text('SOPHOS'), findsOneWidget);
      expect(find.text('KODIAK'), findsOneWidget);
    });
  });

  group('Persistência de Dados', () {
    testWidgets(
      'deve lembrar credenciais quando "Lembrar de mim" está marcado',
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          '12345678000190',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        if (find.text('Nome Preferido').evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextFormField).last, 'João Silva');
          await tester.tap(find.text('CONFIRMAR'));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
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
      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
      expect(find.text('Nome Preferido'), findsOneWidget);
    });

    testWidgets('deve recuperar de estados de erro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        '11.111.111/1111-11',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('CNPJ inválido'), findsOneWidget);
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Nome Preferido'), findsOneWidget);
    });
  });

  group('Acessibilidade', () {
    testWidgets('deve ter elementos acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
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
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      final interactionStopwatch = Stopwatch()..start();
      await tester.enterText(
        find.byType(TextFormField).first,
        '12345678000190',
      );
      await tester.pump();
      interactionStopwatch.stop();
      expect(interactionStopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
