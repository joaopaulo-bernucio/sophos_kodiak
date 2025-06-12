import '../models/user.dart';
import 'user_storage_service.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  static const String _cnpjValido = '12.345.678/0001-90';
  static const String _senhaValida = 'password123';

  Future<User> login(String cnpj, String senha) async {
    if (cnpj.trim().isEmpty) {
      throw const AuthException('CNPJ é obrigatório');
    }

    if (senha.trim().isEmpty) {
      throw const AuthException('Senha é obrigatória');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (cnpj != _cnpjValido || senha != _senhaValida) {
      throw const AuthException('CNPJ ou senha incorretos');
    }

    final existingUser = await UserStorageService.getUser();

    return User(
      cnpj: cnpj,
      senha: senha,
      nomePreferido: existingUser?.nomePreferido,
      ultimoLogin: DateTime.now(),
    );
  }

  Future<bool> estaLogado() async {
    return await UserStorageService.hasUserData();
  }

  Future<User?> obterUsuarioAtual() async {
    return await UserStorageService.getUser();
  }

  Future<void> atualizarNomePreferido(String nomePreferido) async {
    final sucesso = await UserStorageService.updatePreferredName(nomePreferido);
    if (!sucesso) {
      throw const AuthException('Nenhum usuário logado');
    }
  }

  Future<void> logout() async {
    await UserStorageService.clearUserData();
  }

  bool validarFormatoCnpj(String cnpj) {
    final regex = RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$');
    return regex.hasMatch(cnpj);
  }

  bool validarSenha(String senha) {
    return senha.length >= 8;
  }

  Future<DateTime?> obterUltimoLogin() async {
    final user = await UserStorageService.getUser();
    return user?.ultimoLogin;
  }

  Future<void> salvarUsuario(User usuario) async {
    await UserStorageService.saveUser(usuario, rememberMe: true);
  }

  Future<void> limparDados() async {
    await logout();
  }
}
