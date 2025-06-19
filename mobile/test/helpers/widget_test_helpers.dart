import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';
import 'package:sophos_kodiak/models/user.dart';
import 'package:sophos_kodiak/app.dart';

class WidgetTestHelpers {
  /// Configura dados de usuário reais para testes
  static Future<void> setupUserData({
    String? cnpj,
    String? nomePreferido,
    bool rememberMe = true,
  }) async {
    final user = User(
      cnpj: cnpj ?? '12345678000100',
      senha: 'password123',
      nomePreferido: nomePreferido ?? 'Test User',
      ultimoLogin: DateTime.now(),
    );

    await UserStorageService.saveUser(user, rememberMe: rememberMe);
  }

  /// Limpa todos os dados do usuário
  static Future<void> clearUserData() async {
    await UserStorageService.clearUserData();
  }

  /// Configura um estado de usuário não logado
  static Future<void> setupLoggedOutState() async {
    await UserStorageService.clearUserData();
  }

  /// Aguarda que todas as animações terminem
  static Future<void> pumpAndSettle(
    WidgetTester tester, [
    Duration? duration,
  ]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 500));
  }

  /// Encontra um widget por texto específico
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Encontra um widget por key
  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  /// Simula entrada de texto em um campo
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Simula tap em um widget
  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  /// Simula scroll em uma lista
  static Future<void> scrollDown(
    WidgetTester tester,
    Finder finder, {
    double offset = 300.0,
  }) async {
    await tester.drag(finder, Offset(0, -offset));
    await tester.pump();
  }

  /// Verifica se um widget está visível
  static void expectWidgetVisible(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifica se um widget não está visível
  static void expectWidgetNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifica se múltiplos widgets estão visíveis
  static void expectMultipleWidgets(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Helper para aguardar que um widget apareça
  static Future<void> waitForWidget(
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
  static Future<void> clearTestData() async {
    await clearUserData();
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

/// Helper para criar instâncias de widget de teste com MaterialApp
Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child);
}

/// Helper para criar a aplicação completa para testes de integração
Widget createTestableApp() {
  return const App();
}

/// Cria um aplicativo de teste com MaterialApp para widgets
Widget createTestApp(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.orange),
  );
}
