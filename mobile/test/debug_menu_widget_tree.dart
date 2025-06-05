import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/menu_page.dart';

void main() {
  testWidgets('Debug - Investigar diferença nos testes', (
    WidgetTester tester,
  ) async {
    // Configurar tela maior para os testes
    await tester.binding.setSurfaceSize(const Size(1080, 1920));

    // Arrange & Act
    await tester.pumpWidget(const MaterialApp(home: MenuPage()));
    await tester.pumpAndSettle();

    // Debug - Procurar por todos os tipos de widget
    print('\n=== CARDS ===');
    var cards = find.byType(Card);
    print('Cards encontrados: ${cards.evaluate().length}');

    print('\n=== INKWELLS ===');
    var inkwells = find.byType(InkWell);
    print('InkWells encontrados: ${inkwells.evaluate().length}');

    print('\n=== TEXTOS ESPECÍFICOS ===');
    var chatbot = find.text('Chatbot IA');
    print('Chatbot IA: ${chatbot.evaluate().length}');

    var reports = find.text('Relatórios');
    print('Relatórios: ${reports.evaluate().length}');

    var config = find.text('Configurações');
    print('Configurações: ${config.evaluate().length}');

    var help = find.text('Ajuda');
    print('Ajuda: ${help.evaluate().length}');

    // Verificar tamanho da tela
    print('\n=== TAMANHO DA TELA ===');
    var size = tester.getSize(find.byType(MaterialApp));
    print('Tamanho da tela: ${size.width}x${size.height}');

    expect(cards.evaluate().length, equals(4));
  });
}
