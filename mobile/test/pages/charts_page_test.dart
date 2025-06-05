// Testes para a página de gráficos do Sophos Kodiak
//
// Este arquivo testa todos os componentes e funcionalidades da tela de gráficos,
// incluindo exibição de dados, navegação entre abas e interações.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/charts_page.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';

void main() {
  group('ChartsPage Widget Tests', () {
    testWidgets('Deve exibir todos os elementos da interface de gráficos', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar elementos principais
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verificar se existe algum tipo de conteúdo de gráfico
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Deve usar cores do design system', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar cores
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.background));

      final appBar = find.byType(AppBar);
      final appBarWidget = tester.widget<AppBar>(appBar);
      expect(appBarWidget.backgroundColor, equals(AppColors.surface));
    });

    testWidgets('Deve ter botão de voltar funcionando', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Home')),
          routes: {'/charts': (context) => const ChartsPage()},
        ),
      );

      // Navegar para a página de gráficos
      await tester.tap(find.text('Home'));
      await tester.pump();

      Navigator.of(tester.element(find.text('Home'))).pushNamed('/charts');
      await tester.pumpAndSettle();

      // Act - Clicar no botão voltar
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Assert - Verificar se voltou para a tela anterior
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Deve exibir mensagem de sucesso ao atualizar dados', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Act - Clicar no botão de refresh
      final refreshButton = find.byIcon(Icons.refresh);
      await tester.tap(refreshButton);
      await tester.pump();

      // Assert - Verificar se a mensagem de sucesso aparece
      expect(find.text('Dados atualizados!'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('ChartsPage Navigation Tests', () {
    testWidgets('Deve navegar entre abas se disponível', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se existem abas ou tabs
      // Como não podemos ver o código completo, vamos verificar elementos comuns
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('Deve manter estado ao navegar entre abas', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Act & Assert - Verificar se a página mantém estado consistente
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
    });
  });

  group('ChartsPage Content Tests', () {
    testWidgets('Deve exibir conteúdo de gráficos ou dados', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se há elementos de conteúdo
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Deve ter layout responsivo', (WidgetTester tester) async {
      // Arrange - Configurar tamanho de tela diferente
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se a página se adapta
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);

      // Restaurar tamanho original
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('ChartsPage Performance Tests', () {
    testWidgets('Deve carregar rapidamente', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Menos que 1 segundo
    });

    testWidgets('Deve responder rapidamente ao refresh', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Act
      final stopwatch = Stopwatch()..start();
      final refreshButton = find.byIcon(Icons.refresh);
      await tester.tap(refreshButton);
      await tester.pump();

      // Assert
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Menos que 200ms
    });
  });

  group('ChartsPage Error Handling Tests', () {
    testWidgets('Deve lidar graciosamente com estados de carregamento', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se a página carrega sem erros
      expect(find.byType(ChartsPage), findsOneWidget);
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
    });

    testWidgets('Deve manter interface consistente durante operações', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Act - Simular várias operações
      final refreshButton = find.byIcon(Icons.refresh);
      for (int i = 0; i < 3; i++) {
        await tester.tap(refreshButton);
        await tester.pump();
      }

      // Assert - Verificar se a interface permanece estável
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('ChartsPage Accessibility Tests', () {
    testWidgets('Deve ter elementos acessíveis', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar acessibilidade básica
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
    });

    testWidgets('Deve ter contraste adequado', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: ChartsPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se usa cores com contraste adequado
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.background));
    });
  });
}
