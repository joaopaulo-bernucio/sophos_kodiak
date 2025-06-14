import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestHelpers {
  /// Configura SharedPreferences com dados mock para testes
  static Future<void> setupSharedPreferences({
    Map<String, dynamic>? userData,
    String? authToken,
    Map<String, String>? customValues,
  }) async {
    final Map<String, Object> mockData = {
      'user_data': userData != null
          ? '{"cnpj": "${userData['cnpj'] ?? '12345678000100'}", "nomePreferido": "${userData['nomePreferido'] ?? 'Test User'}"}'
          : '{"cnpj": "12345678000100", "nomePreferido": "Test User"}',
      'auth_token': authToken ?? 'mock_auth_token_12345',
      'is_logged_in': true,
      ...?customValues,
    };

    SharedPreferences.setMockInitialValues(mockData);
  }

  /// Limpa todos os dados do SharedPreferences
  static Future<void> clearSharedPreferences() async {
    SharedPreferences.setMockInitialValues({});
  }

  /// Configura um estado de usuário não logado
  static Future<void> setupLoggedOutState() async {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
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
}
