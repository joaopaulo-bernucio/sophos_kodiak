import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('LoginPage Widget Tests', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      await WidgetTestHelpers.clearUserData();
    });

    tearDown(() async {
      await WidgetTestHelpers.clearUserData();
    });

    group('UI Rendering', () {
      testWidgets('should render all UI elements correctly', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        expect(find.text('SOPHOS KODIAK'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('CNPJ'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
      });

      testWidgets('should display app logo', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('should have password field obscured by default', (
        tester,
      ) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        final passwordFields = find.byType(TextField);
        final passwordField = tester
            .widgetList<TextField>(passwordFields)
            .lastWhere((field) => field.obscureText == true);
        expect(passwordField.obscureText, isTrue);
      });
    });

    group('Form Validation', () {
      testWidgets('should format CNPJ while typing', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        final cnpjField = find.byType(TextField).first;
        await tester.enterText(cnpjField, '12345678000100');
        await tester.pump();
        final textField = tester.widget<TextField>(cnpjField);
        expect(textField.controller?.text, equals('12.345.678/0001-00'));
      });
    });

    group('Basic Functionality', () {
      testWidgets('should have essential UI components', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        expect(find.text('CNPJ'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
        expect(find.text('ENTRAR'), findsOneWidget);
        expect(find.text('Continuar conectado'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error for short password', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        final cnpjField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(cnpjField, '12345678000190');
        await tester.enterText(passwordField, '123');
        final loginButton = find.byType(ElevatedButton).first;
        await tester.tap(loginButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(
          find.text('Senha deve ter no mínimo 8 caracteres'),
          findsOneWidget,
        );
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should show preferred name dialog on successful login', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginPage(),
            routes: {
              '/home': (context) => const Scaffold(body: Text('Home Page')),
            },
          ),
        );
        await tester.pumpAndSettle();
        final cnpjField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        await tester.enterText(cnpjField, '12345678000190');
        await tester.enterText(passwordField, 'password123');
        final loginButton = find.byType(ElevatedButton).first;
        await tester.tap(loginButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Nome Preferido'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        final okButton = find.text('OK');
        await tester.tap(okButton);
        await tester.pumpAndSettle();
        expect(find.text('Home Page'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should support basic navigation', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
