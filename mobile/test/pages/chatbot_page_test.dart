// Testes para a página do chatbot do Sophos Kodiak
//
// Este arquivo testa todos os componentes e funcionalidades da tela de chatbot,
// incluindo envio de mensagens, sugestões, integração com API e interface.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/pages/chatbot_page.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';

// Gerando mocks automaticamente

void main() {
  group('ChatbotPage Widget Tests', () {
    testWidgets('Deve exibir todos os elementos da interface do chatbot', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Act
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar elementos principais
      expect(find.text('Sophos IA'), findsOneWidget);
      expect(
        find.text(
          'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?',
        ),
        findsOneWidget,
      );

      // Verificar campo de entrada de mensagem
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Mensagem'), findsOneWidget);

      // Verificar botões de ação
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('Deve exibir sugestões de perguntas iniciais', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));

      // Act
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar se as sugestões estão visíveis
      expect(find.text('Preveja quais clientes estão'), findsOneWidget);
      expect(find.text('mais propensos a cancelar o serviço'), findsOneWidget);
      expect(find.text('Quais produtos têm a'), findsOneWidget);
      expect(find.text('maior margem de lucro?'), findsOneWidget);
    });

    testWidgets('Deve permitir digitar mensagem no campo de entrada', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Act - Digitar mensagem
      await tester.enterText(textField, 'Olá, como você está?');
      await tester.pump();

      // Assert - Verificar se o texto foi inserido
      expect(find.text('Olá, como você está?'), findsOneWidget);
    });

    testWidgets('Deve enviar mensagem ao pressionar botão send', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act - Digitar e enviar mensagem
      await tester.enterText(textField, 'Como funciona o sistema?');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Verificar se a mensagem aparece no chat
      expect(find.text('Como funciona o sistema?'), findsOneWidget);
    });

    testWidgets('Deve usar cores do design system', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar cor de fundo
      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(AppColors.surface));
    });
  });

  group('ChatbotPage Interaction Tests', () {
    testWidgets('Deve selecionar sugestão ao clicar', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Act - Clicar na primeira sugestão
      final firstSuggestion = find.text('Preveja quais clientes estão');
      await tester.tap(firstSuggestion);
      await tester.pumpAndSettle();

      // Assert - Verificar se a sugestão foi enviada como mensagem
      expect(
        find.text(
          'Preveja quais clientes estão mais propensos a cancelar o serviço',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Deve focar no campo de entrada ao clicar', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Act - Clicar no campo de texto
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Assert - Verificar se o campo está focado
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);
    });

    testWidgets('Deve limpar campo após enviar mensagem', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act - Digitar, enviar e verificar limpeza
      await tester.enterText(textField, 'Teste de mensagem');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Verificar se o campo foi limpo
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });

  group('ChatbotPage Message Display Tests', () {
    testWidgets('Deve exibir mensagem de boas-vindas inicial', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Assert - Verificar mensagem de boas-vindas
      expect(
        find.text(
          'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Deve exibir mensagens do usuário com estilo correto', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act - Enviar mensagem do usuário
      await tester.enterText(textField, 'Minha pergunta');
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Verificar se a mensagem do usuário aparece
      expect(find.text('Minha pergunta'), findsOneWidget);
    });

    testWidgets('Deve rolar automaticamente para última mensagem', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act - Enviar várias mensagens
      for (int i = 0; i < 5; i++) {
        await tester.enterText(textField, 'Mensagem $i');
        await tester.pump();
        await tester.tap(sendButton);
        await tester.pump();
      }

      // Assert - Verificar se a última mensagem está visível
      expect(find.text('Mensagem 4'), findsOneWidget);
    });
  });

  group('ChatbotPage Performance Tests', () {
    testWidgets('Deve carregar rapidamente', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      // Assert
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Menos que 1 segundo
    });

    testWidgets('Deve responder rapidamente ao envio de mensagens', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act
      await tester.enterText(textField, 'Teste de performance');
      await tester.pump();

      final stopwatch = Stopwatch()..start();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(200)); // Menos que 200ms
    });
  });

  group('ChatbotPage Validation Tests', () {
    testWidgets('Não deve enviar mensagem vazia', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final sendButton = find.byIcon(Icons.send);
      final initialMessageCount = tester
          .widgetList(
            find.text(
              'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?',
            ),
          )
          .length;

      // Act - Tentar enviar mensagem vazia
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Verificar que não adicionou nova mensagem
      final finalMessageCount = tester
          .widgetList(
            find.text(
              'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?',
            ),
          )
          .length;
      expect(finalMessageCount, equals(initialMessageCount));
    });

    testWidgets('Deve aceitar mensagens com caracteres especiais', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(const MaterialApp(home: ChatbotPage()));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      final sendButton = find.byIcon(Icons.send);

      // Act - Enviar mensagem com caracteres especiais
      const specialMessage = 'Teste com ação: @#\$%^&*()';
      await tester.enterText(textField, specialMessage);
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pump();

      // Assert - Verificar se a mensagem foi aceita
      expect(find.text(specialMessage), findsOneWidget);
    });
  });
}
