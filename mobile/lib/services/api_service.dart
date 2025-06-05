import 'dart:convert';
import 'package:http/http.dart' as http;

/// Exceção personalizada para erros de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Modelo de resposta para pergunta
class PerguntaResponse {
  final String resposta;
  final bool sucesso;
  final String? erro;

  const PerguntaResponse({
    required this.resposta,
    required this.sucesso,
    this.erro,
  });

  factory PerguntaResponse.fromJson(Map<String, dynamic> json) {
    return PerguntaResponse(
      resposta: json['resposta'] ?? '',
      sucesso: json['sucesso'] ?? false,
      erro: json['erro'],
    );
  }
}

/// Modelo de dados para gráficos
class ChartData {
  final List<Map<String, dynamic>> dados;
  final String tipo;
  final String titulo;

  const ChartData({
    required this.dados,
    required this.tipo,
    required this.titulo,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      dados: List<Map<String, dynamic>>.from(json['dados'] ?? []),
      tipo: json['tipo'] ?? '',
      titulo: json['titulo'] ?? '',
    );
  }
}

/// Serviço para comunicação com a API do backend
class ApiService {
  static const String _baseUrl = 'http://127.0.0.1:5000';
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Faz uma pergunta para o chatbot
  Future<PerguntaResponse> enviarPergunta(String pergunta) async {
    if (pergunta.trim().isEmpty) {
      throw const ApiException('Pergunta não pode estar vazia');
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/pergunta'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'pergunta': pergunta}),
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return PerguntaResponse.fromJson(data);
      } else {
        throw ApiException(
          data['erro'] ?? 'Erro desconhecido',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  /// Busca dados para gráficos
  Future<ChartData> buscarDadosGraficos(String tipo) async {
    if (tipo.trim().isEmpty) {
      throw const ApiException('Tipo de gráfico é obrigatório');
    }

    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/charts/$tipo'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ChartData.fromJson(data);
      } else {
        throw ApiException(
          data['erro'] ?? 'Erro ao buscar dados do gráfico',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erro de conexão: ${e.toString()}');
    }
  }

  /// Verifica se a API está funcionando
  Future<bool> verificarSaude() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fecha o cliente HTTP
  void dispose() {
    _client.close();
  }
}
