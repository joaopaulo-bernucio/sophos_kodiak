import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import 'package:sophos_kodiak/services/auth_service.dart';
import '../helpers/widget_test_helpers.dart';

// Gerar mocks com build_runner
@GenerateMocks([AuthService])
import 'test_login_page.mocks.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      WidgetTestHelpers.setupSharedPreferences();
    });

    tearDown(() {
      WidgetTestHelpers.clearSharedPreferences();
    });

    group('UI Rendering', () {
      testWidgets('should render all UI elements correctly', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Assert
        expect(find.text('Login'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2)); // CNPJ e Senha
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('CNPJ'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
      });

      testWidgets('should display app logo', (tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Assert
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('should have password field obscured by default', (
        tester,
      ) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Assert
        final passwordField = tester.widget<TextField>(
          find.byKey(const Key('password_field')),
        );
        expect(passwordField.obscureText, isTrue);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation error for empty CNPJ', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        final loginButton = find.byType(ElevatedButton);
        await tester.tap(loginButton);
        await tester.pump();

        // Assert
        expect(find.text('CNPJ é obrigatório'), findsOneWidget);
      });

      testWidgets('should show validation error for empty password', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act - Preencher apenas CNPJ
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert
        expect(find.text('Senha é obrigatória'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid CNPJ format', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '123456789', // CNPJ inválido
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert
        expect(find.text('CNPJ deve ter 14 dígitos'), findsOneWidget);
      });

      testWidgets('should format CNPJ while typing', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.pump();

        // Assert
        final cnpjField = tester.widget<TextField>(
          find.byKey(const Key('cnpj_field')),
        );
        expect(cnpjField.controller?.text, equals('12.345.678/0001-00'));
      });
    });

    group('Authentication Flow', () {
      testWidgets('should show loading indicator during login', (tester) async {
        // Arrange
        when(mockAuthService.login(any, any)).thenAnswer(
          (_) async => Future.delayed(const Duration(seconds: 1), () => true),
        );

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Entrando...'), findsOneWidget);

        // Aguardar conclusão
        await tester.pumpAndSettle();
      });

      testWidgets('should navigate to home page on successful login', (
        tester,
      ) async {
        // Arrange
        when(mockAuthService.login(any, any)).thenAnswer((_) async => true);

        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(authService: mockAuthService),
            routes: {
              '/home': (context) => const Scaffold(body: Text('Home Page')),
            },
          ),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Home Page'), findsOneWidget);
        verify(
          mockAuthService.login('12345678000100', 'password123'),
        ).called(1);
      });

      testWidgets('should show error message on failed login', (tester) async {
        // Arrange
        when(
          mockAuthService.login(any, any),
        ).thenThrow(Exception('Credenciais inválidas'));

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'wrongpassword',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Credenciais inválidas'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should show network error message on connection failure', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthService.login(any, any),
        ).thenThrow(Exception('Erro de conexão'));

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('Erro de conexão'), findsOneWidget);
      });
    });

    group('User Interaction', () {
      testWidgets('should toggle password visibility', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act - Encontrar botão de toggle
        final toggleButton = find.byKey(const Key('password_toggle'));
        await tester.tap(toggleButton);
        await tester.pump();

        // Assert
        final passwordField = tester.widget<TextField>(
          find.byKey(const Key('password_field')),
        );
        expect(passwordField.obscureText, isFalse);

        // Act - Toggle novamente
        await tester.tap(toggleButton);
        await tester.pump();

        // Assert
        final passwordField2 = tester.widget<TextField>(
          find.byKey(const Key('password_field')),
        );
        expect(passwordField2.obscureText, isTrue);
      });

      testWidgets('should submit form on Enter key press', (tester) async {
        // Arrange
        when(mockAuthService.login(any, any)).thenAnswer((_) async => true);

        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(authService: mockAuthService),
            routes: {
              '/home': (context) => const Scaffold(body: Text('Home Page')),
            },
          ),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );

        // Simular tecla Enter
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthService.login(any, any)).called(1);
      });

      testWidgets('should disable login button when form is invalid', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act - Deixar campos vazios
        await tester.pump();

        // Assert
        final loginButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(loginButton.onPressed, isNull); // Botão deve estar desabilitado
      });

      testWidgets('should enable login button when form is valid', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act
        await tester.enterText(
          find.byKey(const Key('cnpj_field')),
          '12345678000100',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );
        await tester.pump();

        // Assert
        final loginButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(loginButton.onPressed, isNotNull); // Botão deve estar habilitado
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper accessibility labels', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Assert
        expect(find.bySemanticsLabel('Campo CNPJ'), findsOneWidget);
        expect(find.bySemanticsLabel('Campo Senha'), findsOneWidget);
        expect(find.bySemanticsLabel('Botão Entrar'), findsOneWidget);
      });

      testWidgets('should support screen reader navigation', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Act & Assert
        final semantics = tester.getSemantics(find.byType(LoginPage));
        expect(semantics.hasFlag(SemanticsFlag.isTextField), isFalse);
        expect(semantics.hasFlag(SemanticsFlag.isButton), isFalse);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (tester) async {
        // Arrange - Simular tela pequena
        await tester.binding.setSurfaceSize(const Size(360, 640));

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(authService: mockAuthService)),
        );

        // Assert
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Arrange - Simular tela grande
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pump();

        // Assert - Layout deve se adaptar
        expect(find.byType(LoginPage), findsOneWidget);
      });
    });
  });
}
