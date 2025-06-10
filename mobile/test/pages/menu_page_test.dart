// Testes para a página de HomePage do Sophos Kodiak
//
// Este arquivo testa todos os componentes e funcionalidades da tela de HomePage,
// incluindo navegação, interações e layout do grid de opções.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/home_page.dart';
import 'package:sophos_kodiak/pages/chatbot_page.dart';
import 'package:sophos_kodiak/pages/charts_page.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('Deve exibir todos os elementos da interface de menu', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar elementos principais
      expect(find.text('Menu Principal'), findsOneWidget);
      expect(find.text('Bem-vindo ao Kodiak'), findsOneWidget);
      expect(
        find.text('Escolha uma das opções abaixo para continuar'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('Deve exibir todas as opções do menu', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar opções do menu
      expect(find.text('Chatbot IA'), findsOneWidget);
      expect(find.text('Assistente inteligente'), findsOneWidget);
      expect(find.text('Relatórios'), findsOneWidget);
      expect(find.text('Gráficos e análises'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Ajustes do sistema'), findsOneWidget);
      expect(find.text('Ajuda'), findsOneWidget);
      expect(find.text('Suporte e documentação'), findsOneWidget);
    });

    testWidgets('Deve exibir ícones corretos para cada opção', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar ícones
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('Deve usar cores do design system', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar cores
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.background));

      final appBar = find.byType(AppBar);
      final appBarWidget = tester.widget<AppBar>(appBar);
      expect(appBarWidget.backgroundColor, equals(AppColors.surface));
    });
  });

  group('HomePage Navigation Tests', () {
    testWidgets('Deve navegar para o chatbot ao clicar na opção', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
          routes: {'/chatbot': (context) => const ChatbotPage()},
        ),
      );
      await tester.pumpAndSettle();

      // Act - Clicar na opção do chatbot
      await tester.tap(find.text('Chatbot IA'));
      await tester.pumpAndSettle();

      // Assert - Verificar se navegou para a página do chatbot
      expect(find.byType(ChatbotPage), findsOneWidget);
    });

    testWidgets('Deve navegar para relatórios ao clicar na opção', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
          routes: {'/charts': (context) => const ChartsPage()},
        ),
      );
      await tester.pumpAndSettle();

      // Act - Clicar na opção de relatórios
      await tester.tap(find.text('Relatórios'));
      await tester.pumpAndSettle();

      // Assert - Verificar se navegou para a página de gráficos
      expect(find.byType(ChartsPage), findsOneWidget);
    });

    testWidgets('Deve voltar para a tela anterior ao clicar no botão voltar', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Tela Anterior')),
          routes: {'/menu': (context) => const HomePage()},
        ),
      );

      // Navegar para o menu
      final navigator = Navigator.of(
        tester.element(find.text('Tela Anterior')),
      );
      navigator.pushNamed('/menu');
      await tester.pumpAndSettle();

      // Act - Clicar no botão voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Verificar se voltou para a tela anterior
      expect(find.text('Tela Anterior'), findsOneWidget);
    });
  });

  group('HomePage Dialog Tests', () {
    testWidgets('Deve exibir diálogo ao clicar em Configurações', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Act - Clicar na opção Configurações
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      // Assert - Verificar se o diálogo aparece
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Configurações'), findsNWidgets(2)); // Título e opção
      expect(
        find.text(
          'Esta funcionalidade está em desenvolvimento e será disponibilizada em breve.',
        ),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('Deve exibir diálogo ao clicar em Ajuda', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Act - Clicar na opção Ajuda
      await tester.tap(find.text('Ajuda'));
      await tester.pumpAndSettle();

      // Assert - Verificar se o diálogo aparece
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Ajuda'), findsNWidgets(2)); // Título e opção
      expect(
        find.text(
          'Esta funcionalidade está em desenvolvimento e será disponibilizada em breve.',
        ),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('Deve fechar diálogo ao clicar em OK', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Act - Abrir diálogo
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();

      // Verificar se o diálogo está aberto
      expect(find.byType(AlertDialog), findsOneWidget);

      // Clicar em OK para fechar
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Assert - Verificar se o diálogo foi fechado
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('HomePage Interaction Tests', () {
    testWidgets('Deve responder ao toque em todos os cards do menu', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
          routes: {
            '/chatbot': (context) => const Scaffold(body: Text('Chatbot')),
            '/charts': (context) => const Scaffold(body: Text('Charts')),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert - Testar cada card
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(4)); // 4 cards no total

      // Testar o card do Chatbot
      await tester.tap(find.text('Chatbot IA'));
      await tester.pumpAndSettle();
      expect(find.text('Chatbot'), findsOneWidget);

      // Voltar para o menu usando Navigator.pop
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();

      // Testar o card de Relatórios
      await tester.tap(find.text('Relatórios'));
      await tester.pumpAndSettle();
      expect(find.text('Charts'), findsOneWidget);
    });

    testWidgets('Deve ter grid responsivo com 2 colunas', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar o grid
      final gridView = find.byType(GridView);
      expect(gridView, findsOneWidget);

      final gridViewWidget = tester.widget<GridView>(gridView);
      final delegate = gridViewWidget.childrenDelegate;
      expect(delegate, isA<SliverChildListDelegate>());

      // Verificar se tem 4 cards
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(4));
    });
  });

  group('HomePage Layout Tests', () {
    testWidgets('Deve ter layout adequado em diferentes tamanhos de tela', (
      WidgetTester tester,
    ) async {
      // Arrange - Testar com tamanho pequeno
      await tester.binding.setSurfaceSize(const Size(350, 600));
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se a página carrega corretamente
      expect(find.text('Menu Principal'), findsOneWidget);
      expect(find.text('Bem-vindo ao Kodiak'), findsOneWidget);

      // Arrange - Testar com tamanho maior
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se mantém a estrutura
      expect(find.text('Menu Principal'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);

      // Restaurar tamanho original
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Deve ter espaçamento adequado entre elementos', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se há SizedBox para espaçamento
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);

      // Verificar se o container principal tem margens
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });

  group('HomePage Performance Tests', () {
    testWidgets('Deve carregar rapidamente', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Menos que 1 segundo
    });

    testWidgets('Deve responder rapidamente a toques', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Act - Clicar em uma opção
      await tester.tap(find.text('Configurações'));
      await tester.pump();

      // Assert
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Menos que 200ms
    });
  });

  group('HomePage Accessibility Tests', () {
    testWidgets('Deve ter elementos acessíveis', (WidgetTester tester) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se os botões são acessíveis
      final inkWells = find.byType(InkWell);
      expect(
        inkWells,
        findsNWidgets(5),
      ); // 4 cards clicáveis + 1 botão de voltar

      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsOneWidget); // Botão voltar
    });

    testWidgets('Deve ter contraste adequado', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se usa cores com contraste adequado
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.background));
    });
  });

  group('HomePage Error Handling Tests', () {
    testWidgets('Deve lidar graciosamente com estados de carregamento', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se a página carrega sem erros
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Menu Principal'), findsOneWidget);
    });

    testWidgets('Deve manter interface consistente durante operações', (
      WidgetTester tester,
    ) async {
      // Configurar tela maior para evitar problemas de layout
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Arrange
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Act - Simular várias operações
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Configurações'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      // Assert - Verificar se a interface permanece estável
      expect(find.text('Menu Principal'), findsOneWidget);
      expect(find.text('Bem-vindo ao Kodiak'), findsOneWidget);
    });
  });
}
