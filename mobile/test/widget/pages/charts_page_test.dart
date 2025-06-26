import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/charts_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  group('ChartsPage Tests', () {
    testWidgets('Deve renderizar a estrutura básica da página', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));

      expect(find.text('Relatórios e Gráficos'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Deve mostrar as três abas principais', (tester) async {
      await tester.pumpWidget(createTestApp(const ChartsPage()));
      await tester.pump();

      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Funcionários'), findsOneWidget);
      expect(find.text('Projetos'), findsOneWidget);
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

        expect(find.text('Sobre os Gráficos'), findsOneWidget);
        expect(
          find.text('Vendas: Mostra o total de vendas por mês'),
          findsOneWidget,
        );
        expect(find.text('Entendi'), findsOneWidget);
      },
    );
  });
}
