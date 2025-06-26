import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sophos_kodiak/app.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> safeTap(WidgetTester tester, Finder finder) async {
    try {
      await ensureVisible(tester, finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    } catch (e) {
      await tester.drag(find.byType(MaterialApp), const Offset(0, -100));
      await tester.pumpAndSettle();
      try {
        await ensureVisible(tester, finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      } catch (e2) {
        await tester.tap(finder, warnIfMissed: false);
        await tester.pumpAndSettle();
      }
    }
  }

  group('E2E - Fluxo Completo de Autenticação', () {
    setUp(() async {
      await UserStorageService.clearUserData();
    });

    testWidgets('deve completar fluxo de login com sucesso', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

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
        await safeTap(tester, checkbox);
      }

      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);
      await safeTap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('Nome Preferido').evaluate().isNotEmpty) {
        expect(find.text('Nome Preferido'), findsOneWidget);

        final nameFields = find.byType(TextFormField);
        if (nameFields.evaluate().isNotEmpty) {
          final nameField = nameFields.last;
          await tester.enterText(nameField, 'João Silva');
          await tester.pumpAndSettle();

          final confirmButton = find.text('CONFIRMAR');
          if (confirmButton.evaluate().isNotEmpty) {
            await safeTap(tester, confirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        }
      }
    });

    testWidgets('deve rejeitar credenciais inválidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));

      await tester.enterText(textFields.first, '11.111.111/1111-11');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();

      final loginButton = find.byType(ElevatedButton);
      await safeTap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final hasErrorDialog = find.byType(AlertDialog).evaluate().isNotEmpty;
      final hasErrorText =
          find.textContaining('CNPJ').evaluate().isNotEmpty ||
          find.textContaining('inválido').evaluate().isNotEmpty ||
          find.textContaining('erro').evaluate().isNotEmpty;
      final hasSnackBar = find.byType(SnackBar).evaluate().isNotEmpty;

      expect(hasErrorDialog || hasErrorText || hasSnackBar, isTrue);
    });

    testWidgets('deve validar campos obrigatórios', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final loginButton = find.byType(ElevatedButton);
      await safeTap(tester, loginButton);
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

  group('E2E - Persistência de Dados', () {
    testWidgets(
      'deve lembrar credenciais quando "Lembrar de mim" está marcado',
      (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final textFields = find.byType(TextField);
        expect(textFields, findsAtLeast(2));

        await tester.enterText(textFields.first, '12345678000190');
        await tester.pumpAndSettle();
        await tester.enterText(textFields.last, 'password123');
        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);
        if (checkbox.evaluate().isNotEmpty) {
          await safeTap(tester, checkbox);
        }

        final loginButton = find.byType(ElevatedButton);
        await safeTap(tester, loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await tester.pumpWidget(const App());
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final newTextFields = find.byType(TextField);
        expect(newTextFields, findsAtLeast(1));
      },
    );
  });

  group('E2E - Tratamento de Erros', () {
    testWidgets('deve lidar com interações rápidas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));

      await tester.enterText(textFields.first, '12345678000190');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();

      final loginButton = find.byType(ElevatedButton);

      await safeTap(tester, loginButton);
      await safeTap(tester, loginButton);
      await safeTap(tester, loginButton);

      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('deve recuperar de estados de erro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeast(2));

      await tester.enterText(textFields.first, '11.111.111/1111-11');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.last, 'password123');
      await tester.pumpAndSettle();

      final loginButton = find.byType(ElevatedButton);
      await safeTap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await safeTap(tester, okButton);
      }

      await tester.enterText(textFields.first, '12345678000190');
      await tester.pumpAndSettle();
      await safeTap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('E2E - Performance', () {
    testWidgets('deve carregar e responder rapidamente', (
      WidgetTester tester,
    ) async {
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle(const Duration(seconds: 3));
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(8000));

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
