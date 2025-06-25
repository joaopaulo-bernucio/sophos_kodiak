import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';
import 'package:sophos_kodiak/models/user.dart';
import 'package:sophos_kodiak/app.dart';

class WidgetTestHelpers {
  static Future<void> setupUserData({
    String? cnpj,
    String? nomePreferido,
    bool rememberMe = true,
  }) async {
    SharedPreferences.setMockInitialValues({});

    final user = User(
      cnpj: cnpj ?? '12345678000100',
      senha: 'password123',
      nomePreferido: nomePreferido ?? 'Test User',
      ultimoLogin: DateTime.now(),
    );

    await UserStorageService.saveUser(user, rememberMe: rememberMe);
  }

  static Future<void> clearUserData() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorageService.clearUserData();
  }

  static Future<void> setupLoggedOutState() async {
    SharedPreferences.setMockInitialValues({});
    await UserStorageService.clearUserData();
  }

  static Future<void> pumpAndSettle(
    WidgetTester tester, [
    Duration? duration,
  ]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 500));
  }

  static Finder findByText(String text) {
    return find.text(text);
  }

  static Finder findByKey(String key) {
    return find.byKey(Key(key));
  }

  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pump();
  }

  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  static Future<void> scrollDown(
    WidgetTester tester,
    Finder finder, {
    double offset = 300.0,
  }) async {
    await tester.drag(finder, Offset(0, -offset));
    await tester.pump();
  }

  static void expectWidgetVisible(Finder finder) {
    expect(finder, findsOneWidget);
  }

  static void expectWidgetNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  static void expectMultipleWidgets(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

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

  static Future<void> clearTestData() async {
    SharedPreferences.setMockInitialValues({});
    await clearUserData();
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

Widget createTestableWidget(Widget child) {
  return MaterialApp(home: child);
}

Widget createTestableApp() {
  return const App();
}

Widget createTestApp(Widget child) {
  return MaterialApp(
    home: child,
    theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.orange),
  );
}
