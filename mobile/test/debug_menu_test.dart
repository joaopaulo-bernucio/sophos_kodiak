import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/pages/menu_page.dart';
import '../lib/constants/app_constants.dart';

void main() {
  group('Debug MenuPage Tests', () {
    testWidgets('Debug - Verificar quantos cards são renderizados', (
      WidgetTester tester,
    ) async {
      // Arranjar com tamanho específico de tela
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const MenuPage()),
      );
      await tester.pumpAndSettle();

      // Debug - imprimir informações
      final cards = find.byType(Card);
      final gridView = find.byType(GridView);
      final inkWells = find.byType(InkWell);

      print('Cards encontrados: ${cards.evaluate().length}');
      print('GridView encontrado: ${gridView.evaluate().length}');
      print('InkWells encontrados: ${inkWells.evaluate().length}');

      // Verificar textos específicos
      final chatbotText = find.text('Chatbot IA');
      final relatoriosText = find.text('Relatórios');
      final configText = find.text('Configurações');
      final ajudaText = find.text('Ajuda');

      print('Chatbot IA: ${chatbotText.evaluate().length}');
      print('Relatórios: ${relatoriosText.evaluate().length}');
      print('Configurações: ${configText.evaluate().length}');
      print('Ajuda: ${ajudaText.evaluate().length}');

      // Verificar se todos os widgets estão sendo renderizados
      expect(cards, findsAtLeast(2));
    });

    testWidgets('Debug - Teste com tamanho maior de tela', (
      WidgetTester tester,
    ) async {
      // Arranjar com tamanho maior de tela
      await tester.binding.setSurfaceSize(const Size(600, 1000));
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const MenuPage()),
      );
      await tester.pumpAndSettle();

      // Verificar novamente
      final cards = find.byType(Card);
      print('Cards com tela maior: ${cards.evaluate().length}');

      expect(cards, findsAtLeast(2));
    });
  });
}
