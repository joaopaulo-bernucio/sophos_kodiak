import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/app.dart';

/// Helper para criar instâncias de widget de teste com MaterialApp
Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child);
}

/// Helper para criar a aplicação completa para testes de integração
Widget createTestableApp() {
  return const App();
}

/// Helper para aguardar animações e atualizações
Future<void> waitForUI(WidgetTester tester, {Duration? timeout}) async {
  await tester.pumpAndSettle(timeout ?? const Duration(seconds: 2));
}

/// Helper para inserir texto em um campo de input
Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await tester.enterText(finder, text);
  await tester.pump();
}

/// Helper para tocar em um widget
Future<void> tapWidget(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
}

/// Helper para rolar a tela
Future<void> scrollWidget(
  WidgetTester tester,
  Finder finder,
  Offset offset,
) async {
  await tester.drag(finder, offset);
  await tester.pumpAndSettle();
}

/// Helper para verificar se um texto está presente
void expectTextPresent(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Helper para verificar se um texto não está presente
void expectTextNotPresent(String text) {
  expect(find.text(text), findsNothing);
}

/// Helper para verificar se um widget está presente
void expectWidgetPresent(Type widgetType) {
  expect(find.byType(widgetType), findsOneWidget);
}

/// Helper para aguardar que um widget apareça
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration? timeout,
}) async {
  await tester.pumpAndSettle();

  final end = DateTime.now().add(timeout ?? const Duration(seconds: 5));

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));

    if (tester.any(finder)) {
      return;
    }
  }

  throw Exception('Widget não encontrado após timeout');
}

/// Helper para limpar dados de teste
Future<void> clearTestData() async {
  // Este helper pode ser estendido para limpar dados específicos de teste
  // Por enquanto, apenas aguarda um pequeno delay para simular limpeza
  await Future.delayed(const Duration(milliseconds: 100));
}
