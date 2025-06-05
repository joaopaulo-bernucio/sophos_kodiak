import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/menu_page.dart';

void main() {
  testWidgets('Debug simples - verificar cards renderizados', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MenuPage()));
    await tester.pumpAndSettle();

    // Debug: Listar todos os elementos encontrados
    final allWidgets = find.byType(Widget);
    print('Total de widgets: ${allWidgets.evaluate().length}');

    final cards = find.byType(Card);
    print('Cards encontrados: ${cards.evaluate().length}');

    final inkWells = find.byType(InkWell);
    print('InkWells encontrados: ${inkWells.evaluate().length}');

    final texts = find.byType(Text);
    print('Textos encontrados: ${texts.evaluate().length}');

    // Procurar textos específicos
    final chatbotText = find.text('Chatbot IA');
    final relatoriosText = find.text('Relatórios');
    final configText = find.text('Configurações');
    final ajudaText = find.text('Ajuda');

    print('Chatbot IA: ${chatbotText.evaluate().length}');
    print('Relatórios: ${relatoriosText.evaluate().length}');
    print('Configurações: ${configText.evaluate().length}');
    print('Ajuda: ${ajudaText.evaluate().length}');

    // Procurar por partes do texto
    final configPartial = find.textContaining('Config');
    final ajudaPartial = find.textContaining('Ajuda');

    print('Config (parcial): ${configPartial.evaluate().length}');
    print('Ajuda (parcial): ${ajudaPartial.evaluate().length}');

    // Verificar se o GridView está sendo renderizado
    final gridView = find.byType(GridView);
    print('GridView encontrado: ${gridView.evaluate().length}');

    // Teste básico - pelo menos deve ter algum card
    expect(cards.evaluate().length, greaterThan(0));
  });
}
