import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/app.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  group('App Widget - Configuração', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Inicialização', () {
      testWidgets('deve criar MaterialApp corretamente', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        expect(find.byType(MaterialApp), findsOneWidget);

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.title, equals('Sophos Kodiak'));
        expect(materialApp.debugShowCheckedModeBanner, isFalse);
      });

      testWidgets('deve ter rota inicial configurada como login', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.initialRoute, equals('/login'));
      });

      testWidgets('deve navegar para a tela de login inicialmente', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        await WidgetTestHelpers.pumpAndSettle(tester);

        expect(find.text('SOPHOS KODIAK'), findsOneWidget);
      });
    });

    group('Rotas Configuradas', () {
      testWidgets('deve ter todas as rotas principais configuradas', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.routes?.containsKey('/login'), isTrue);
        expect(materialApp.routes?.containsKey('/home'), isTrue);
        expect(materialApp.routes?.containsKey('/chatbot'), isTrue);
        expect(materialApp.routes?.containsKey('/charts'), isTrue);
      });
    });

    group('Tema da Aplicação', () {
      testWidgets('deve ter tema configurado', (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.theme, isNotNull);
        expect(materialApp.theme!.colorScheme.primary, isNotNull);
      });
    });

    group('Geração de Rotas Dinâmicas', () {
      testWidgets('deve gerar rota para settings com argumentos', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.onGenerateRoute, isNotNull);
        final settings = RouteSettings(
          name: '/settings',
          arguments: {
            'cnpj': '12.345.678/0001-90',
            'password': 'password123',
            'userName': 'João Silva',
          },
        );
        final route = materialApp.onGenerateRoute!(settings);
        expect(route, isNotNull);
      });

      testWidgets('deve retornar null para rotas não reconhecidas', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        final settings = RouteSettings(name: '/rota-inexistente');
        final route = materialApp.onGenerateRoute!(settings);
        expect(route, isNull);
      });
    });

    group('Integração com Sistema', () {
      testWidgets('deve renderizar sem erros', (WidgetTester tester) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('deve manter estado durante hot reload simulado', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.text('SOPHOS KODIAK'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('deve carregar rapidamente', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
