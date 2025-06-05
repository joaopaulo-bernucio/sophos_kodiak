// Testes para o serviço de API do Sophos Kodiak
//
// Este arquivo testa todas as funcionalidades do ApiService,
// incluindo comunicação com backend, tratamento de erros e modelos de dados.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sophos_kodiak/services/api_service.dart';

// Gerar mocks
@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(client: mockClient);
    });

    tearDown(() {
      apiService.dispose();
    });

    group('PerguntaResponse Model Tests', () {
      test('Deve criar PerguntaResponse a partir de JSON válido', () {
        // Arrange
        final json = {
          'resposta': 'Esta é uma resposta de teste',
          'sucesso': true,
          'erro': null,
        };

        // Act
        final response = PerguntaResponse.fromJson(json);

        // Assert
        expect(response.resposta, equals('Esta é uma resposta de teste'));
        expect(response.sucesso, isTrue);
        expect(response.erro, isNull);
      });

      test(
        'Deve criar PerguntaResponse com valores padrão quando campos ausentes',
        () {
          // Arrange
          final json = <String, dynamic>{};

          // Act
          final response = PerguntaResponse.fromJson(json);

          // Assert
          expect(response.resposta, equals(''));
          expect(response.sucesso, isFalse);
          expect(response.erro, isNull);
        },
      );

      test('Deve criar PerguntaResponse com erro', () {
        // Arrange
        final json = {
          'resposta': '',
          'sucesso': false,
          'erro': 'Erro de processamento',
        };

        // Act
        final response = PerguntaResponse.fromJson(json);

        // Assert
        expect(response.resposta, equals(''));
        expect(response.sucesso, isFalse);
        expect(response.erro, equals('Erro de processamento'));
      });
    });

    group('ChartData Model Tests', () {
      test('Deve criar ChartData a partir de JSON válido', () {
        // Arrange
        final json = {
          'dados': [
            {'nome': 'Janeiro', 'valor': 100},
            {'nome': 'Fevereiro', 'valor': 150},
          ],
          'tipo': 'bar',
          'titulo': 'Vendas por Mês',
        };

        // Act
        final chartData = ChartData.fromJson(json);

        // Assert
        expect(chartData.dados.length, equals(2));
        expect(chartData.dados[0]['nome'], equals('Janeiro'));
        expect(chartData.dados[0]['valor'], equals(100));
        expect(chartData.tipo, equals('bar'));
        expect(chartData.titulo, equals('Vendas por Mês'));
      });

      test(
        'Deve criar ChartData com valores padrão quando campos ausentes',
        () {
          // Arrange
          final json = <String, dynamic>{};

          // Act
          final chartData = ChartData.fromJson(json);

          // Assert
          expect(chartData.dados, isEmpty);
          expect(chartData.tipo, equals(''));
          expect(chartData.titulo, equals(''));
        },
      );
    });

    group('ApiException Tests', () {
      test('Deve criar ApiException com mensagem', () {
        // Arrange & Act
        const exception = ApiException('Erro de teste');

        // Assert
        expect(exception.message, equals('Erro de teste'));
        expect(exception.statusCode, isNull);
        expect(exception.toString(), equals('ApiException: Erro de teste'));
      });

      test('Deve criar ApiException com mensagem e status code', () {
        // Arrange & Act
        const exception = ApiException('Erro HTTP', statusCode: 404);

        // Assert
        expect(exception.message, equals('Erro HTTP'));
        expect(exception.statusCode, equals(404));
        expect(
          exception.toString(),
          equals('ApiException: Erro HTTP (Status: 404)'),
        );
      });
    });

    group('enviarPergunta Tests', () {
      test('Deve enviar pergunta com sucesso', () async {
        // Arrange
        final responseBody = jsonEncode({
          'resposta': 'Resposta do chatbot',
          'sucesso': true,
        });

        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.enviarPergunta('Como está o tempo?');

        // Assert
        expect(result.resposta, equals('Resposta do chatbot'));
        expect(result.sucesso, isTrue);

        // Verificar se a requisição foi feita corretamente
        verify(
          mockClient.post(
            Uri.parse('http://127.0.0.1:5000/pergunta'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'pergunta': 'Como está o tempo?'}),
          ),
        ).called(1);
      });

      test('Deve falhar com pergunta vazia', () async {
        // Act & Assert
        expect(
          () => apiService.enviarPergunta(''),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              equals('Pergunta não pode estar vazia'),
            ),
          ),
        );

        expect(
          () => apiService.enviarPergunta('   '),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              equals('Pergunta não pode estar vazia'),
            ),
          ),
        );

        // Verificar que nenhuma requisição foi feita
        verifyNever(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        );
      });

      test('Deve tratar erro HTTP 400', () async {
        // Arrange
        final responseBody = jsonEncode({
          'erro': 'Requisição inválida',
          'sucesso': false,
        });

        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 400));

        // Act & Assert
        expect(
          () => apiService.enviarPergunta('Pergunta de teste'),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  equals('Requisição inválida'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(400)),
          ),
        );
      });

      test('Deve tratar erro HTTP 500', () async {
        // Arrange
        final responseBody = jsonEncode({
          'erro': 'Erro interno do servidor',
          'sucesso': false,
        });

        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 500));

        // Act & Assert
        expect(
          () => apiService.enviarPergunta('Pergunta de teste'),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  equals('Erro interno do servidor'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(500)),
          ),
        );
      });

      test('Deve tratar erro de conexão', () async {
        // Arrange
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenThrow(Exception('Conexão recusada'));

        // Act & Assert
        expect(
          () => apiService.enviarPergunta('Pergunta de teste'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Erro de conexão'),
            ),
          ),
        );
      });
    });

    group('buscarDadosGraficos Tests', () {
      test('Deve buscar dados de gráfico com sucesso', () async {
        // Arrange
        final responseBody = jsonEncode({
          'dados': [
            {'nome': 'Produto A', 'vendas': 100},
            {'nome': 'Produto B', 'vendas': 150},
          ],
          'tipo': 'bar',
          'titulo': 'Vendas por Produto',
        });

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.buscarDadosGraficos('vendas');

        // Assert
        expect(result.dados.length, equals(2));
        expect(result.dados[0]['nome'], equals('Produto A'));
        expect(result.tipo, equals('bar'));
        expect(result.titulo, equals('Vendas por Produto'));

        // Verificar se a requisição foi feita corretamente
        verify(
          mockClient.get(
            Uri.parse('http://127.0.0.1:5000/charts/vendas'),
            headers: {'Accept': 'application/json'},
          ),
        ).called(1);
      });

      test('Deve falhar com tipo vazio', () async {
        // Act & Assert
        expect(
          () => apiService.buscarDadosGraficos(''),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              equals('Tipo de gráfico é obrigatório'),
            ),
          ),
        );

        expect(
          () => apiService.buscarDadosGraficos('   '),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              equals('Tipo de gráfico é obrigatório'),
            ),
          ),
        );

        // Verificar que nenhuma requisição foi feita
        verifyNever(mockClient.get(any, headers: anyNamed('headers')));
      });

      test('Deve tratar erro ao buscar gráfico', () async {
        // Arrange
        final responseBody = jsonEncode({
          'erro': 'Tipo de gráfico não encontrado',
        });

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response(responseBody, 404));

        // Act & Assert
        expect(
          () => apiService.buscarDadosGraficos('inexistente'),
          throwsA(
            isA<ApiException>()
                .having(
                  (e) => e.message,
                  'message',
                  equals('Tipo de gráfico não encontrado'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(404)),
          ),
        );
      });
    });

    group('verificarSaude Tests', () {
      test('Deve retornar true quando API está funcionando', () async {
        // Arrange
        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{"status": "ok"}', 200));

        // Act
        final result = await apiService.verificarSaude();

        // Assert
        expect(result, isTrue);

        verify(
          mockClient.get(
            Uri.parse('http://127.0.0.1:5000/health'),
            headers: {'Accept': 'application/json'},
          ),
        ).called(1);
      });

      test('Deve retornar false quando API não está funcionando', () async {
        // Arrange
        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        // Act
        final result = await apiService.verificarSaude();

        // Assert
        expect(result, isFalse);
      });

      test('Deve retornar false quando há erro de conexão', () async {
        // Arrange
        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenThrow(Exception('Conexão recusada'));

        // Act
        final result = await apiService.verificarSaude();

        // Assert
        expect(result, isFalse);
      });
    });

    group('Performance Tests', () {
      test('Deve responder rapidamente a perguntas', () async {
        // Arrange
        final responseBody = jsonEncode({
          'resposta': 'Resposta rápida',
          'sucesso': true,
        });

        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response(responseBody, 200);
        });

        final stopwatch = Stopwatch()..start();

        // Act
        await apiService.enviarPergunta('Pergunta rápida');

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1000),
        ); // Menos que 1 segundo
      });

      test('Deve timeout após 30 segundos', () async {
        // Arrange
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async {
          // Simula um timeout real (reduzido para ser mais rápido)
          await Future.delayed(const Duration(seconds: 3));
          return http.Response('{"resposta": "tarde demais"}', 200);
        });

        // Act & Assert
        await expectLater(
          apiService.enviarPergunta('Pergunta que demora'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Erro de conexão'),
            ),
          ),
        );
      });
    });
  });
}
