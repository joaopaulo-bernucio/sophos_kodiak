import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de usuário
class Usuario {
  final String cnpj;
  final String nomePreferido;
  final DateTime ultimoLogin;

  const Usuario({
    required this.cnpj,
    required this.nomePreferido,
    required this.ultimoLogin,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      cnpj: json['cnpj'] ?? '',
      nomePreferido: json['nomePreferido'] ?? '',
      ultimoLogin: DateTime.parse(
        json['ultimoLogin'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'nomePreferido': nomePreferido,
      'ultimoLogin': ultimoLogin.toIso8601String(),
    };
  }
}

/// Exceção personalizada para erros de autenticação
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Serviço de autenticação e gerenciamento de usuário
class AuthService {
  static const String _usuarioKey = 'usuario_atual';
  static const String _logadoKey = 'usuario_logado';

  // Credenciais temporárias para desenvolvimento
  static const String _cnpjValido = '12.345.678/0001-90';
  static const String _senhaValida = 'password123';

  /// Faz login do usuário
  Future<Usuario> login(String cnpj, String senha) async {
    if (cnpj.trim().isEmpty) {
      throw const AuthException('CNPJ é obrigatório');
    }

    if (senha.trim().isEmpty) {
      throw const AuthException('Senha é obrigatória');
    }

    // Simula validação de credenciais
    await Future.delayed(const Duration(milliseconds: 500));

    if (cnpj != _cnpjValido || senha != _senhaValida) {
      throw const AuthException('CNPJ ou senha incorretos');
    }

    final usuario = Usuario(
      cnpj: cnpj,
      nomePreferido: '', // Será definido posteriormente
      ultimoLogin: DateTime.now(),
    );

    return usuario;
  }

  /// Salva os dados do usuário após login
  Future<void> salvarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_usuarioKey, jsonEncode(usuario.toJson()));
    await prefs.setBool(_logadoKey, true);
  }

  /// Obtém o usuário atual salvo
  Future<Usuario?> obterUsuarioAtual() async {
    final prefs = await SharedPreferences.getInstance();

    final usuarioJson = prefs.getString(_usuarioKey);
    if (usuarioJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(usuarioJson);
        return Usuario.fromJson(data);
      } catch (e) {
        // Se houver erro ao decodificar, limpa os dados
        await limparDados();
        return null;
      }
    }

    return null;
  }

  /// Verifica se o usuário está logado
  Future<bool> estaLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_logadoKey) ?? false;
  }

  /// Atualiza o nome preferido do usuário
  Future<void> atualizarNomePreferido(String nomePreferido) async {
    final usuario = await obterUsuarioAtual();
    if (usuario == null) {
      throw const AuthException('Nenhum usuário logado');
    }

    final usuarioAtualizado = Usuario(
      cnpj: usuario.cnpj,
      nomePreferido: nomePreferido,
      ultimoLogin: usuario.ultimoLogin,
    );

    await salvarUsuario(usuarioAtualizado);
  }

  /// Faz logout do usuário
  Future<void> logout() async {
    await limparDados();
  }

  /// Limpa todos os dados do usuário
  Future<void> limparDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_usuarioKey);
    await prefs.remove(_logadoKey);
  }

  /// Valida formato do CNPJ
  bool validarFormatoCnpj(String cnpj) {
    final regex = RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$');
    return regex.hasMatch(cnpj);
  }

  /// Valida critérios de senha
  bool validarSenha(String senha) {
    return senha.length >= 8;
  }

  /// Obtém informações do último login
  Future<DateTime?> obterUltimoLogin() async {
    final usuario = await obterUsuarioAtual();
    return usuario?.ultimoLogin;
  }
}
