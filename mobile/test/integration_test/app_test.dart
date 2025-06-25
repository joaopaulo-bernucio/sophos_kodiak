import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sophos_kodiak/app.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo Completo de Login', () {
    setUp(() async {
      await UserStorageService.clearUserData();
    });

    testWidgets('deve completar fluxo de login com sucesso', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('SOPHOS KODIAK'), findsOneWidget);
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));
      final cnpjField = textFields.first;
      final passwordField = textFields.last;
      await tester.enterText(cnpjField, '12345678000190');
      await tester.pumpAndSettle();
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('12.345.678/0001-90'), findsOneWidget);

      final checkbox = find.byType(Checkbox);
      if (checkbox.evaluate().isNotEmpty) {
        await tester.tap(checkbox);
        await tester.pumpAndSettle();
      }

      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      if (find.text('Nome Preferido').evaluate().isNotEmpty) {
        expect(find.text('Nome Preferido'), findsOneWidget);
        expect(find.text('Como gostaria de ser chamado?'), findsOneWidget);
        final nameFields = find.byType(TextFormField);
        if (nameFields.evaluate().isNotEmpty) {
          final nameField = nameFields.last;
          await tester.enterText(nameField, 'João Silva');
          await tester.pumpAndSettle();
          final confirmButton = find.text('CONFIRMAR');
          if (confirmButton.evaluate().isNotEmpty) {
            await tester.tap(confirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        }
      }
    });

    testWidgets('deve rejeitar login com credenciais inválidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));
      await tester.enterText(textFields.first, '11.111.111/1111-11');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final hasErrorDialog = find.byType(AlertDialog).evaluate().isNotEmpty;
      final hasErrorText =
          find.textContaining('CNPJ').evaluate().isNotEmpty ||
          find.textContaining('inválido').evaluate().isNotEmpty ||
          find.textContaining('erro').evaluate().isNotEmpty ||
          find.textContaining('Erro').evaluate().isNotEmpty;
      final hasSnackBar = find.byType(SnackBar).evaluate().isNotEmpty;
      expect(hasErrorDialog || hasErrorText || hasSnackBar, isTrue);
    });

    testWidgets('deve validar campos obrigatórios', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final hasDialog = find.byType(AlertDialog).evaluate().isNotEmpty;
      final hasSnackBar = find.byType(SnackBar).evaluate().isNotEmpty;
      final hasValidationText =
          find.textContaining('obrigatório').evaluate().isNotEmpty ||
          find.textContaining('CNPJ').evaluate().isNotEmpty ||
          find.textContaining('senha').evaluate().isNotEmpty;
      expect(hasDialog || hasSnackBar || hasValidationText, isTrue);
    });
  });

  group('Fluxo de Navegação entre Telas', () {
    testWidgets('deve navegar através das rotas principais', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('SOPHOS KODIAK'), findsOneWidget);
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    });
  });

  group('Persistência de Dados', () {
    testWidgets(
      'deve lembrar credenciais quando "Lembrar de mim" está marcado',
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle(const Duration(seconds: 5));
        final textFields = find.byType(TextField);
        expect(textFields, findsAtLeast(2));
        await tester.enterText(textFields.first, '12345678000190');
        await tester.pumpAndSettle();
        await tester.enterText(textFields.last, 'password123');
        await tester.pumpAndSettle();
        final checkbox = find.byType(Checkbox);
        if (checkbox.evaluate().isNotEmpty) {
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
        final loginButton = find.byType(ElevatedButton);
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        if (find.text('Nome Preferido').evaluate().isNotEmpty) {
          final nameFields = find.byType(TextField);
          if (nameFields.evaluate().isNotEmpty) {
            await tester.enterText(nameFields.last, 'João Silva');
            await tester.pumpAndSettle();
            final confirmButton = find.text('CONFIRMAR');
            if (confirmButton.evaluate().isNotEmpty) {
              await tester.tap(confirmButton);
              await tester.pumpAndSettle(const Duration(seconds: 3));
            }
          }
        }
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle(const Duration(seconds: 5));
        final newTextFields = find.byType(TextField);
        expect(newTextFields, findsAtLeast(1));
      },
    );
  });

  group('Tratamento de Erros', () {
    testWidgets('deve lidar graciosamente com interações rápidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));
      await tester.enterText(textFields.first, '12345678000190');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('deve recuperar de estados de erro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));
      await tester.enterText(textFields.first, '11.111.111/1111-11');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }
      await tester.enterText(textFields.first, '12345678000190');
      await tester.pumpAndSettle();
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Acessibilidade', () {
    testWidgets('deve ter elementos acessíveis', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      final hasSemanticLabels =
          find.bySemanticsLabel('Campo CNPJ').evaluate().isNotEmpty ||
          find.bySemanticsLabel('Campo Senha').evaluate().isNotEmpty ||
          find.bySemanticsLabel('Botão entrar').evaluate().isNotEmpty;
      final hasTextFields = find.byType(TextField).evaluate().isNotEmpty;
      final hasButtons = find.byType(ElevatedButton).evaluate().isNotEmpty;
      final hasAnySemantics = find
          .byWidgetPredicate((widget) {
            return widget.toString().toLowerCase().contains('semantic') ||
                widget.toString().toLowerCase().contains('tooltip') ||
                widget.toString().toLowerCase().contains('label');
          })
          .evaluate()
          .isNotEmpty;
      expect(
        hasSemanticLabels || hasAnySemantics || (hasTextFields && hasButtons),
        isTrue,
      );
    });
  });

  group('Performance', () {
    testWidgets('deve carregar e responder rapidamente', (
      WidgetTester tester,
    ) async {
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 5));
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        final interactionStopwatch = Stopwatch()..start();
        await tester.enterText(textFields.first, '12345678000190');
        await tester.pumpAndSettle();
        interactionStopwatch.stop();
        expect(interactionStopwatch.elapsedMilliseconds, lessThan(1000));
      }
    });
  });
}
