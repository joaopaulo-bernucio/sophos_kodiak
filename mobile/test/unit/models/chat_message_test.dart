import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/models/chat_message.dart';
import 'package:sophos_kodiak/services/api_service.dart';
import '../../helpers/test_data.dart';

void main() {
  group('ChatMessage Model', () {
    group('Constructor', () {
      test('deve criar mensagem do usuário corretamente', () {
        final message = TestData.createUserMessage();
        expect(message.text, equals(TestData.sampleQuestion));
        expect(message.isUser, isTrue);
        expect(message.timestamp, isNotNull);
        expect(message.isAnimating, isFalse);
        expect(message.isError, isFalse);
        expect(message.apiError, isNull);
      });

      test('deve criar mensagem do sistema corretamente', () {
        final message = TestData.createSystemMessage();
        expect(message.text, equals(TestData.sampleResponse));
        expect(message.isUser, isFalse);
        expect(message.timestamp, isNotNull);
        expect(message.isAnimating, isFalse);
        expect(message.isError, isFalse);
        expect(message.apiError, isNull);
      });

      test('deve criar mensagem de erro corretamente', () {
        const apiError = ApiException(
          'Connection error',
          userFriendlyMessage: 'Erro de conexão',
          type: ApiErrorType.connectionError,
        );
        final message = ChatMessage(
          text: 'Erro de conexão',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
          apiError: apiError,
        );
        expect(message.text, equals('Erro de conexão'));
        expect(message.isUser, isFalse);
        expect(message.isError, isTrue);
        expect(message.apiError, equals(apiError));
      });

      test('deve criar mensagem animada corretamente', () {
        final message = ChatMessage(
          text: 'Digitando...',
          isUser: false,
          timestamp: DateTime.now(),
          isAnimating: true,
        );
        expect(message.text, equals('Digitando...'));
        expect(message.isAnimating, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('deve converter ChatMessage para JSON corretamente', () {
        final now = DateTime.now();
        final message = ChatMessage(
          text: TestData.sampleQuestion,
          isUser: true,
          timestamp: now,
          isAnimating: false,
          isError: false,
        );
        final json = message.toJson();
        expect(json['text'], equals(TestData.sampleQuestion));
        expect(json['isUser'], isTrue);
        expect(json['timestamp'], equals(now.toIso8601String()));
        expect(json['isAnimating'], isFalse);
        expect(json['isError'], isFalse);
      });

      test('deve converter JSON para ChatMessage corretamente', () {
        final now = DateTime.now();
        final json = {
          'text': TestData.sampleResponse,
          'isUser': false,
          'timestamp': now.toIso8601String(),
          'isAnimating': true,
          'isError': false,
        };
        final message = ChatMessage.fromJson(json);
        expect(message.text, equals(TestData.sampleResponse));
        expect(message.isUser, isFalse);
        expect(message.timestamp, equals(now));
        expect(message.isAnimating, isTrue);
        expect(message.isError, isFalse);
      });

      test('deve lidar com campos opcionais nulos no JSON', () {
        final now = DateTime.now();
        final json = {
          'text': TestData.sampleQuestion,
          'isUser': true,
          'timestamp': now.toIso8601String(),
        };
        final message = ChatMessage.fromJson(json);
        expect(message.text, equals(TestData.sampleQuestion));
        expect(message.isUser, isTrue);
        expect(message.timestamp, equals(now));
        expect(message.isAnimating, isFalse);
        expect(message.isError, isFalse);
      });

      test(
        'deve manter consistência na conversão JSON -> ChatMessage -> JSON',
        () {
          final originalJson = {
            'text': TestData.sampleQuestion,
            'isUser': true,
            'timestamp': DateTime.now().toIso8601String(),
            'isAnimating': false,
            'isError': false,
          };
          final message = ChatMessage.fromJson(originalJson);
          final convertedJson = message.toJson();
          expect(convertedJson, equals(originalJson));
        },
      );
    });

    group('CopyWith', () {
      test('deve criar cópia com novos valores', () {
        final originalMessage = TestData.createUserMessage();
        const newText = 'Nova pergunta';
        const apiError = ApiException(
          'Timeout error',
          userFriendlyMessage: 'Timeout',
          type: ApiErrorType.timeout,
        );
        final updatedMessage = originalMessage.copyWith(
          text: newText,
          isError: true,
          apiError: apiError,
        );
        expect(updatedMessage.text, equals(newText));
        expect(updatedMessage.isUser, equals(originalMessage.isUser));
        expect(updatedMessage.timestamp, equals(originalMessage.timestamp));
        expect(updatedMessage.isError, isTrue);
        expect(updatedMessage.apiError, equals(apiError));
      });

      test('deve manter valores originais quando não especificado', () {
        final originalMessage = TestData.createSystemMessage();
        final copiedMessage = originalMessage.copyWith();
        expect(copiedMessage.text, equals(originalMessage.text));
        expect(copiedMessage.isUser, equals(originalMessage.isUser));
        expect(copiedMessage.timestamp, equals(originalMessage.timestamp));
        expect(copiedMessage.isAnimating, equals(originalMessage.isAnimating));
        expect(copiedMessage.isError, equals(originalMessage.isError));
        expect(copiedMessage.apiError, equals(originalMessage.apiError));
      });

      test('deve poder remover erro com copyWith', () {
        final errorMessage = TestData.createSystemMessage(
          text: 'Erro',
          isError: true,
        );
        final fixedMessage = errorMessage.copyWith(
          text: 'Resposta corrigida',
          isError: false,
        );
        expect(fixedMessage.text, equals('Resposta corrigida'));
        expect(fixedMessage.isError, isFalse);
      });
    });

    group('Equality', () {
      test('deve considerar iguais mensagens com mesmos dados', () {
        final now = DateTime.now();
        final message1 = ChatMessage(
          text: TestData.sampleQuestion,
          isUser: true,
          timestamp: now,
          isAnimating: false,
          isError: false,
        );
        final message2 = ChatMessage(
          text: TestData.sampleQuestion,
          isUser: true,
          timestamp: now,
          isAnimating: false,
          isError: false,
        );
        expect(message1, equals(message2));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('deve considerar diferentes mensagens com textos diferentes', () {
        final message1 = TestData.createUserMessage(text: 'Pergunta 1');
        final message2 = TestData.createUserMessage(text: 'Pergunta 2');
        expect(message1, isNot(equals(message2)));
        expect(message1.hashCode, isNot(equals(message2.hashCode)));
      });

      test('deve considerar diferentes mensagens com isUser diferentes', () {
        final message1 = TestData.createUserMessage();
        final message2 = TestData.createSystemMessage(text: message1.text);
        expect(message1, isNot(equals(message2)));
      });

      test(
        'deve considerar diferentes mensagens com timestamps diferentes',
        () {
          final now = DateTime.now();
          final message1 = TestData.createUserMessage(timestamp: now);
          final message2 = TestData.createUserMessage(
            timestamp: now.add(const Duration(seconds: 1)),
          );
          expect(message1, isNot(equals(message2)));
        },
      );
    });

    group('ToString', () {
      test('deve gerar string representativa da mensagem', () {
        final message = TestData.createUserMessage();
        final messageString = message.toString();
        expect(messageString, contains('ChatMessage('));
        expect(messageString, contains('text: ${TestData.sampleQuestion}'));
        expect(messageString, contains('isUser: true'));
        expect(messageString, contains('timestamp:'));
        expect(messageString, contains('isAnimating: false'));
        expect(messageString, contains('isError: false'));
      });

      test('deve incluir informações de erro na string', () {
        final message = TestData.createSystemMessage(
          text: 'Erro de conexão',
          isError: true,
        );
        final messageString = message.toString();
        expect(messageString, contains('isError: true'));
      });

      test('deve incluir informações de animação na string', () {
        final message = TestData.createSystemMessage(
          text: 'Digitando...',
          isAnimating: true,
        );
        final messageString = message.toString();
        expect(messageString, contains('isAnimating: true'));
      });
    });

    group('Edge Cases', () {
      test('deve lidar com texto vazio', () {
        final message = ChatMessage(
          text: '',
          isUser: true,
          timestamp: DateTime.now(),
        );
        expect(message.text, isEmpty);
        expect(() => message.toJson(), returnsNormally);
      });

      test('deve lidar com texto muito longo', () {
        final message = ChatMessage(
          text: TestData.longQuestion,
          isUser: true,
          timestamp: DateTime.now(),
        );
        expect(message.text, equals(TestData.longQuestion));
        expect(message.text.length, greaterThan(100));
        expect(() => message.toJson(), returnsNormally);
      });

      test('deve manter consistência com múltiplas operações copyWith', () {
        final original = TestData.createUserMessage();
        final step1 = original.copyWith(isAnimating: true);
        final step2 = step1.copyWith(text: 'Novo texto');
        final step3 = step2.copyWith(isError: true);
        final finalMessage = step3.copyWith(isAnimating: false);
        expect(finalMessage.text, equals('Novo texto'));
        expect(finalMessage.isUser, equals(original.isUser));
        expect(finalMessage.timestamp, equals(original.timestamp));
        expect(finalMessage.isAnimating, isFalse);
        expect(finalMessage.isError, isTrue);
      });
    });
  });
}
