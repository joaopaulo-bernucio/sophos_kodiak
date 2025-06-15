import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sophos_kodiak/pages/charts_page.dart';
import 'package:sophos_kodiak/services/mock_data_service.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('ChartsPage Tests', () {
    testWidgets('Deve renderizar a estrutura básica da página', (tester) async {
      // Act
      await tester.pumpWidget(createTestApp(const ChartsPage()));

      // Assert
      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Deve mostrar as três abas principais', (tester) async {
      // Act
      await tester.pumpWidget(createTestApp(const ChartsPage()));
      await tester.pump(); // Permite o primeiro frame

      // Assert
      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Funcionários'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
    });

    testWidgets('Deve mostrar indicador de loading inicialmente', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestApp(const ChartsPage()));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando dados...'), findsOneWidget);
    });

    testWidgets(
      'Deve mostrar modal de informações ao clicar no ícone de info',
      (tester) async {
        // Act
        await tester.pumpWidget(createTestApp(const ChartsPage()));
        await tester.pump();

        // Tap no botão de informações
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Sobre os Gráficos'), findsOneWidget);
        expect(
          find.text('Vendas: Mostra o total de vendas por mês'),
          findsOneWidget,
        );
        expect(find.text('Entendi'), findsOneWidget);
      },
    );

    group('MockDataService Tests', () {
      test('Deve fornecer dados de vendas válidos', () {
        final vendas = MockDataService.getVendasMockData();

        expect(vendas, isNotEmpty);
        expect(vendas.first, containsPair('mes', isA<String>()));
        expect(vendas.first, containsPair('total_vendas', isA<double>()));
        expect(vendas.first, containsPair('num_vendas', isA<int>()));
      });

      test('Deve fornecer dados de funcionários válidos', () {
        final funcionarios = MockDataService.getFuncionariosMockData();

        expect(funcionarios, isNotEmpty);
        expect(funcionarios.first, containsPair('departamento', isA<String>()));
        expect(funcionarios.first, containsPair('quantidade', isA<int>()));
        expect(funcionarios.first, containsPair('orcamento', isA<double>()));
      });

      test('Deve fornecer dados de projetos válidos', () {
        final projetos = MockDataService.getProjetosMockData();

        expect(projetos, isNotEmpty);
        expect(projetos.first, containsPair('status', isA<String>()));
        expect(projetos.first, containsPair('quantidade', isA<int>()));
        expect(projetos.first, containsPair('valor_total', isA<double>()));
      });

      test('Deve fornecer dados de receita válidos', () {
        final receita = MockDataService.getReceitaMockData();

        expect(receita, isNotEmpty);
        expect(receita.first, containsPair('cliente', isA<String>()));
        expect(receita.first, containsPair('receita', isA<double>()));
        expect(receita.first, containsPair('projetos_total', isA<int>()));
        expect(receita.first, containsPair('projetos_ativos', isA<int>()));
      });

      test('Deve fornecer métricas gerais válidas', () {
        final metricas = MockDataService.getMetricasGeraisMockData();

        expect(metricas, isNotEmpty);
        expect(metricas, containsPair('novos_clientes_ano', isA<int>()));
        expect(metricas, containsPair('projetos_ativos', isA<int>()));
        expect(metricas, containsPair('total_funcionarios', isA<int>()));
        expect(metricas, containsPair('vendas_mes_atual', isA<double>()));
        expect(metricas, containsPair('vendas_ano_atual', isA<double>()));
      });

      test('Métodos async devem simular delay de rede', () async {
        final stopwatch = Stopwatch()..start();

        await MockDataService.getVendasMockDataAsync();

        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          greaterThan(400),
        ); // Deve ter delay
      });
    });

    group('Formatação de dados', () {
      test('Deve calcular totais de vendas corretamente', () {
        final vendas = MockDataService.getVendasMockData();
        final total = vendas.fold(
          0.0,
          (sum, item) => sum + (item['total_vendas'] as double),
        );

        expect(total, greaterThan(0));
        expect(total, isA<double>());
      });

      test('Deve contar funcionários por departamento', () {
        final funcionarios = MockDataService.getFuncionariosMockData();
        final totalFuncionarios = funcionarios.fold(
          0,
          (sum, item) => sum + (item['quantidade'] as int),
        );

        expect(totalFuncionarios, greaterThan(0));
        expect(funcionarios.length, greaterThan(5)); // Múltiplos departamentos
      });

      test('Deve validar status de projetos', () {
        final projetos = MockDataService.getProjetosMockData();
        final statusValidos = [
          'Em andamento',
          'Concluído',
          'Em aprovação',
          'Cancelado',
          'Pausado',
        ];

        for (final projeto in projetos) {
          expect(statusValidos, contains(projeto['status']));
        }
      });
    });
  });
}
