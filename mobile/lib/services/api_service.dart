import 'dart:async';
import 'dart:convert';
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

  factory ApiException.connectionError() => const ApiException(
    'Connection refused or network error',
    userFriendlyMessage:
        'Não foi possível conectar ao servidor.\n\nVerifique se:\n'
        '• Sua conexão com a internet está funcionando\n'
        '• O servidor da aplicação está em execução\n'
        '• Não há bloqueios de firewall\n\nTente novamente em alguns instantes.',
    type: ApiErrorType.connectionError,
  );

  factory ApiException.timeout() => const ApiException(
    'Request timeout',
    userFriendlyMessage:
        'O servidor está demorando para responder.\nTente novamente em alguns instantes.',
    type: ApiErrorType.timeout,
  );

  factory ApiException.serverError(
    String? serverMessage,
    int statusCode,
  ) => ApiException(
    serverMessage ?? 'Server error',
    userFriendlyMessage:
        'Ocorreu um problema no servidor (status $statusCode).\nNossa equipe foi notificada.',
    type: ApiErrorType.serverError,
    statusCode: statusCode,
  );

  factory ApiException.invalidData(String message) => ApiException(
    message,
    userFriendlyMessage:
        'Os dados enviados/recebidos estão em formato inválido.\nTente novamente.',
    type: ApiErrorType.invalidData,
  );

  factory ApiException.unknown(String message) => ApiException(
    message,
    userFriendlyMessage:
        'Algo inesperado aconteceu.\nTente novamente em alguns instantes.',
    type: ApiErrorType.unknown,
  );

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

  factory PerguntaResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    final hasBody = (json['resposta']?.toString().isNotEmpty ?? false);
    return PerguntaResponse(
      resposta: json['resposta'] ?? '',
      sucesso: statusCode == 200 && hasBody,
      erro: json['erro'],
    );
  }
}

class ApiService {
  static const String _baseUrl =
      'http://sk-sk.cxbwajafbngqhhej.brazilsouth.azurecontainer.io:5000';
  // Para rodar local no emulador Android: 'http://10.0.2.2:5000'
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  ApiException _handleConnectionError(dynamic error) {
    final err = error.toString().toLowerCase();
    if (error is TimeoutException || err.contains('timeout')) {
      return ApiException.timeout();
    }
    if (error is http.ClientException ||
        err.contains('connection') ||
        err.contains('socketexception') ||
        err.contains('failed host lookup') ||
        err.contains('network error')) {
      return ApiException.connectionError();
    }
    if (error is ApiException) {
      return error;
    }
    return ApiException.unknown(error.toString());
  }

  /// Envia a pergunta ao endpoint `/pergunta`
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

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return PerguntaResponse.fromJson(data, response.statusCode);
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

  /// Helper genérico para endpoints GET que retornam listas JSON
  Future<List<Map<String, dynamic>>> _getList(
    String path,
    String errorMessage,
  ) async {
    try {
      final url = '$_baseUrl$path';
      final response = await _client
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 404) {
        throw ApiException.serverError('Endpoint não encontrado', 404);
      }
      if (response.statusCode != 200) {
        String? serverMsg;
        try {
          serverMsg =
              (jsonDecode(response.body) as Map<String, dynamic>)['error'];
        } catch (_) {}
        throw ApiException.serverError(serverMsg, response.statusCode);
      }

      final decoded = jsonDecode(response.body);
      final raw = (decoded is Map && decoded.containsKey('data'))
          ? decoded['data']
          : decoded;

      // Normaliza valores:
      // 1) Strings numéricas → num
      // 2) Doubles sem parte fracionária → int
      return (raw as List).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        map.forEach((key, value) {
          dynamic newValue = value;

          // String → num
          if (value is String) {
            final num? parsed = num.tryParse(value);
            if (parsed != null) newValue = parsed;
          }

          // num → int se for double sem fração
          if (newValue is num) {
            if (newValue is double && newValue == newValue.toInt()) {
              newValue = newValue.toInt();
            }
          }

          map[key] = newValue;
        });
        return map;
      }).toList();
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<Map<String, dynamic>>> buscarVendasPorMes() =>
      _getList('/api/query/total_vendas_por_mes', 'Erro ao buscar vendas');

  Future<List<Map<String, dynamic>>> buscarFuncionariosPorDepartamento() =>
      _getList(
        '/api/query/funcionarios_por_departamento',
        'Erro ao buscar funcionários',
      );

  Future<List<Map<String, dynamic>>> buscarProjetosPorStatus() =>
      _getList('/api/query/projetos_por_status', 'Erro ao buscar projetos');

  Future<List<Map<String, dynamic>>> buscarReceitaPorCliente() =>
      _getList('/api/query/receita_por_cliente', 'Erro ao buscar receita');

  /// Verifica health-check em `/health`
  Future<bool> verificarSaude() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
