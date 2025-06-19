import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

enum ApiErrorType {
  connectionError,
  serverError,
  timeout,
  invalidData,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final String userFriendlyMessage;
  final ApiErrorType type;
  final int? statusCode;

  const ApiException(
    this.message, {
    required this.userFriendlyMessage,
    required this.type,
    this.statusCode,
  });

  factory ApiException.connectionError() {
    return const ApiException(
      'Connection refused or network error',
      userFriendlyMessage:
          'Não foi possível conectar ao servidor.\n\nVerifique se:\n• Sua conexão com a internet está funcionando\n• O servidor da aplicação está em execução\n• Não há bloqueios de firewall\n\nTente novamente em alguns instantes.',
      type: ApiErrorType.connectionError,
    );
  }

  factory ApiException.timeout() {
    return const ApiException(
      'Request timeout',
      userFriendlyMessage:
          'O servidor está demorando para responder.\nTente novamente em alguns instantes.',
      type: ApiErrorType.timeout,
    );
  }

  factory ApiException.serverError(String? serverMessage, int statusCode) {
    return ApiException(
      serverMessage ?? 'Server error',
      userFriendlyMessage:
          'Ocorreu um problema no servidor.\nNossa equipe foi notificada.',
      type: ApiErrorType.serverError,
      statusCode: statusCode,
    );
  }

  factory ApiException.invalidData(String message) {
    return ApiException(
      message,
      userFriendlyMessage:
          'Os dados recebidos estão em formato inválido.\nTente novamente.',
      type: ApiErrorType.invalidData,
    );
  }

  factory ApiException.unknown(String message) {
    return ApiException(
      message,
      userFriendlyMessage:
          'Algo inesperado aconteceu.\nTente novamente em alguns instantes.',
      type: ApiErrorType.unknown,
    );
  }

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

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
      sucesso:
          json['sucesso'] ??
          json['sucesso_sql'] ??
          (json['resposta']?.toString().isNotEmpty ?? false),
      erro: json['erro'],
    );
  }
}

class ApiService {
  static const String _baseUrl =
      'http://ip-do-endpoint-mefeus:5000'; //http://10.0.2.2:5000
  static const Duration _timeout = Duration(seconds: 30);
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Método auxiliar para tratar erros de conexão
  ApiException _handleConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Verifica diferentes tipos de erro de conexão
    if (error is http.ClientException ||
        errorString.contains('connection refused') ||
        errorString.contains('socketexception') ||
        errorString.contains('network error') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection reset') ||
        errorString.contains('connection timed out')) {
      return ApiException.connectionError();
    }

    if (error is TimeoutException || errorString.contains('timeout')) {
      return ApiException.timeout();
    }

    if (error is ApiException) {
      return error;
    }

    // Se contém "connection" ou "network", trata como erro de conexão
    if (errorString.contains('connection') || errorString.contains('network')) {
      return ApiException.connectionError();
    }

    return ApiException.unknown(error.toString());
  }

  Future<PerguntaResponse> enviarPergunta(String pergunta) async {
    if (pergunta.trim().isEmpty) {
      throw ApiException.invalidData('Pergunta não pode estar vazia');
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
        throw ApiException.serverError(
          data['erro'] ?? 'Erro desconhecido',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<Map<String, dynamic>>> buscarVendasPorMes() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/total_vendas_por_mes'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Verifica se a resposta tem o novo formato com 'data'
        if (jsonData is Map && jsonData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        // Fallback para formato antigo
        return List<Map<String, dynamic>>.from(jsonData);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException.serverError(
          data['error'] ?? 'Erro ao buscar dados de vendas',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<Map<String, dynamic>>> buscarFuncionariosPorDepartamento() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/funcionarios_por_departamento'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Verifica se a resposta tem o novo formato com 'data'
        if (jsonData is Map && jsonData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        // Fallback para formato antigo
        return List<Map<String, dynamic>>.from(jsonData);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException.serverError(
          data['error'] ?? 'Erro ao buscar dados de funcionários',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<Map<String, dynamic>>> buscarProjetosPorStatus() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/projetos_por_status'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Verifica se a resposta tem o novo formato com 'data'
        if (jsonData is Map && jsonData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        // Fallback para formato antigo
        return List<Map<String, dynamic>>.from(jsonData);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException.serverError(
          data['error'] ?? 'Erro ao buscar dados de projetos',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<Map<String, dynamic>>> buscarReceitaPorCliente() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/receita_por_cliente'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Verifica se a resposta tem o novo formato com 'data'
        if (jsonData is Map && jsonData.containsKey('data')) {
          return List<Map<String, dynamic>>.from(jsonData['data']);
        }
        // Fallback para formato antigo
        return List<Map<String, dynamic>>.from(jsonData);
      } else {
        final data = jsonDecode(response.body);
        throw ApiException.serverError(
          data['error'] ?? 'Erro ao buscar dados de receita',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<bool> verificarSaude() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Busca métricas gerais do sistema para o dashboard
  Future<Map<String, dynamic>> buscarMetricasGerais() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/api/graphs/metricas_gerais'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Verifica se a resposta tem o novo formato com 'data'
        if (jsonData is Map && jsonData.containsKey('data')) {
          final data = jsonData['data'] as List;
          return data.isNotEmpty ? data.first : {};
        }
        // Fallback para formato antigo
        if (jsonData is List && jsonData.isNotEmpty) {
          return jsonData.first;
        }
        return {};
      } else {
        final data = jsonDecode(response.body);
        throw ApiException.serverError(
          data['error'] ?? 'Erro ao buscar métricas gerais',
          response.statusCode,
        );
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  void dispose() {
    _client.close();
  }
}
