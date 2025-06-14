import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('LoginPage Widget Tests', () {
    setUp(() async {
      await WidgetTestHelpers.setupSharedPreferences();
    });

    tearDown(() async {
      await WidgetTestHelpers.clearSharedPreferences();
    });

    group('UI Rendering', () {
      testWidgets('should render all UI elements correctly', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('SOPHOS KODIAK'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2)); // CNPJ e Senha
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('CNPJ'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
      });

      testWidgets('should display app logo', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('should have password field obscured by default', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Assert
        final passwordFields = find.byType(TextField);
        final passwordField = tester.widgetList<TextField>(passwordFields).lastWhere(
          (field) => field.obscureText == true,
        );
        expect(passwordField.obscureText, isTrue);
      });
    });

    group('Form Validation', () {
      testWidgets('should format CNPJ while typing', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Act
        final cnpjField = find.byType(TextField).first;
        await tester.enterText(cnpjField, '12345678000100');
        await tester.pump();

        // Assert
        final textField = tester.widget<TextField>(cnpjField);
        expect(textField.controller?.text, equals('12.345.678/0001-00'));
      });
    });

    group('Basic Functionality', () {
      testWidgets('should have essential UI components', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Assert essential UI elements
        expect(find.text('CNPJ'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
        expect(find.text('ENTRAR'), findsOneWidget);
        expect(find.text('Continuar conectado'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error for short password', (tester) async {
        // Set a larger screen size to avoid layout issues
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Act
        final cnpjField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        
        await tester.enterText(cnpjField, '12345678000190');
        await tester.enterText(passwordField, '123'); // Senha muito curta
        
        // Find the first (and only) ElevatedButton
        final loginButton = find.byType(ElevatedButton).first;
        await tester.tap(loginButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Senha deve ter no mínimo 8 caracteres'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should show preferred name dialog on successful login', (
        tester,
      ) async {
        // Set a larger screen size to avoid layout issues
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginPage(),
            routes: {
              '/home': (context) => const Scaffold(body: Text('Home Page')),
            },
          ),
        );
        await tester.pumpAndSettle();

        // Act - Login com credenciais válidas
        final cnpjField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).last;
        
        await tester.enterText(cnpjField, '12345678000190');
        await tester.enterText(passwordField, 'password123');
        
        // Find the first (and only) ElevatedButton
        final loginButton = find.byType(ElevatedButton).first;
        await tester.tap(loginButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Assert - Should show preferred name dialog
        expect(find.text('Nome Preferido'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
        
        // Act - Confirmar nome preferido
        final okButton = find.text('OK');
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Assert - Should navigate to home
        expect(find.text('Home Page'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should support basic navigation', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(home: LoginPage()),
        );
        await tester.pumpAndSettle();

        // Act & Assert
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });
  });
}
