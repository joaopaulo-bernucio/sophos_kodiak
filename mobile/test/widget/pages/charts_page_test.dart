import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/charts_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('ChartsPage Tests', () {
    testWidgets('Deve renderizar a estrutura básica da página', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Deve mostrar as quatro abas principais', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));
      await tester.pump();

      expect(find.text('Visão Geral'), findsOneWidget);
      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
      expect(find.text('Equipe'), findsOneWidget);
    });

    testWidgets('Deve mostrar indicador de loading inicialmente', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Carregando dados...'), findsOneWidget);
    });

    testWidgets(
      'Deve mostrar modal de informações ao clicar no ícone de info',
      (tester) async {
        await tester.pumpWidget(createTestApp(const ChartsPage()));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.text('Sobre o Dashboard'), findsOneWidget);
        expect(
          find.text(
            'Visão Geral: Métricas consolidadas e performance executiva',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Vendas: Análise temporal de vendas com gráficos de barras',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Projetos: Status dos projetos e receita por cliente'),
          findsOneWidget,
        );
        expect(
          find.text('Equipe: Distribuição por departamento com orçamentos'),
          findsOneWidget,
        );
        expect(find.text('Fechar'), findsOneWidget);
      },
    );

    testWidgets('Deve permitir navegação entre as abas', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));
      await tester.pump();

      await tester.tap(find.text('Vendas'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Projetos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Equipe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Visão Geral'));
      await tester.pumpAndSettle();
    });

    testWidgets('Deve mostrar ícones corretos nas abas', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));
      await tester.pump();

      expect(find.byIcon(Icons.dashboard), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });
  });
}
