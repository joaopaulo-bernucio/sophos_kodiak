import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/pages/menu_page.dart';
import '../lib/constants/app_constants.dart';

void main() {
  group('Debug MenuPage Tests', () {
    testWidgets('Debug - Configuração exata do teste original', (
      WidgetTester tester,
    ) async {
      // Mesma configuração do teste original
      await tester.pumpWidget(const MaterialApp(home: MenuPage()));
      await tester.pumpAndSettle();

      // Debug - imprimir informações detalhadas
      final cards = find.byType(Card);
      final gridView = find.byType(GridView);
      final inkWells = find.byType(InkWell);

      print('=== Debug Detalhado ===');
      print('Cards encontrados: ${cards.evaluate().length}');
      print('GridView encontrado: ${gridView.evaluate().length}');
      print('InkWells encontrados: ${inkWells.evaluate().length}');

      // Buscar por cada texto específico
      final textos = [
        'Chatbot IA',
        'Assistente inteligente',
        'Relatórios',
        'Gráficos e análises',
        'Configurações',
        'Ajustes do sistema',
        'Ajuda',
        'Suporte e documentação',
      ];

      for (final texto in textos) {
        final finder = find.text(texto);
        print('$texto: ${finder.evaluate().length}');
      }

      // Verificar se todos os textos estão presentes
      bool todosTextosPresentess = textos.every(
        (texto) => find.text(texto).evaluate().isNotEmpty,
      );
      print('Todos os textos presentes: $todosTextosPresentess');

      // Verificar se estão visíveis
      final chatbotVisible = find.text('Chatbot IA');
      final relatoriosVisible = find.text('Relatórios');
      final configVisible = find.text('Configurações');
      final ajudaVisible = find.text('Ajuda');

      print('Chatbot visível: ${chatbotVisible.evaluate().isNotEmpty}');
      print('Relatórios visível: ${relatoriosVisible.evaluate().isNotEmpty}');
      print('Configurações visível: ${configVisible.evaluate().isNotEmpty}');
      print('Ajuda visível: ${ajudaVisible.evaluate().isNotEmpty}');

      // Tentar scroll no GridView para ver se algum card está fora da tela
      if (gridView.evaluate().isNotEmpty) {
        await tester.drag(gridView, const Offset(0, -100));
        await tester.pumpAndSettle();

        print('=== Após scroll ===');
        for (final texto in textos) {
          final finder = find.text(texto);
          print('$texto após scroll: ${finder.evaluate().length}');
        }
      }

      // Verificar se todos os cards são encontrados
      expect(cards.evaluate().length, greaterThanOrEqualTo(2));
    });

    testWidgets('Debug - Verificar com viewport maior', (
      WidgetTester tester,
    ) async {
      // Configurar tela grande
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const MaterialApp(home: MenuPage()));
      await tester.pumpAndSettle();

      final cards = find.byType(Card);
      print('=== Com tela grande ===');
      print('Cards encontrados: ${cards.evaluate().length}');

      final textos = ['Chatbot IA', 'Relatórios', 'Configurações', 'Ajuda'];
      for (final texto in textos) {
        final finder = find.text(texto);
        print('$texto: ${finder.evaluate().length}');
      }

      expect(cards.evaluate().length, greaterThanOrEqualTo(4));
    });
  });
}
