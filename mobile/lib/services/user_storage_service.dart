import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserStorageService {
  /// Chave usada para armazenar os dados do usuário no SharedPreferences
  static const String _userKey = 'user_data';

  /// Chave usada para armazenar se o usuário escolheu "lembrar-me"
  static const String _rememberMeKey = 'remember_me';

  /// Salva os dados do usuário no armazenamento local
  ///
  /// [user] - O objeto User a ser salvo
  /// [rememberMe] - Se true, os dados serão persistidos entre sessões
  ///
  /// Retorna true se a operação foi bem-sucedida, false caso contrário
  static Future<bool> saveUser(User user, {bool rememberMe = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converte o objeto User para JSON string
      final userJson = jsonEncode(user.toJson());

      // Salva os dados do usuário
      final userSaved = await prefs.setString(_userKey, userJson);

      // Salva a preferência de "lembrar-me"
      final rememberSaved = await prefs.setBool(_rememberMeKey, rememberMe);

      return userSaved && rememberSaved;
    } catch (e) {
      // Em caso de erro, imprime no console para debug
      print('Erro ao salvar usuário: $e');
      return false;
    }
  }

  /// Recupera os dados do usuário do armazenamento local
  ///
  /// Retorna o objeto User se encontrado, null caso contrário
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica se o usuário escolheu "lembrar-me"
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      // Se não escolheu lembrar, não retorna os dados
      if (!rememberMe) {
        return null;
      }

      // Recupera a string JSON dos dados do usuário
      final userJsonString = prefs.getString(_userKey);

      // Se não há dados salvos, retorna null
      if (userJsonString == null) {
        return null;
      }

      // Converte a string JSON de volta para um Map
      final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;

      // Cria e retorna o objeto User
      return User.fromJson(userJson);
    } catch (e) {
      // Em caso de erro, imprime no console para debug
      print('Erro ao recuperar usuário: $e');
      return null;
    }
  }

  /// Verifica se há dados de usuário salvos
  ///
  /// Retorna true se há dados salvos e o usuário escolheu "lembrar-me"
  static Future<bool> hasUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica se há dados salvos e se o usuário escolheu lembrar
      final hasData = prefs.containsKey(_userKey);
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return hasData && rememberMe;
    } catch (e) {
      print('Erro ao verificar dados do usuário: $e');
      return false;
    }
  }

  /// Atualiza o último login do usuário
  ///
  /// Este método é útil para atualizar apenas a data do último login
  /// sem precisar passar todos os dados do usuário novamente
  static Future<bool> updateLastLogin() async {
    try {
      // Primeiro, recupera o usuário atual
      final currentUser = await getUser();

      if (currentUser == null) {
        return false;
      }

      // Cria uma nova instância com o último login atualizado
      final updatedUser = currentUser.copyWith(ultimoLogin: DateTime.now());

      // Salva o usuário atualizado (mantém a configuração atual do "lembrar-me")
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return await saveUser(updatedUser, rememberMe: rememberMe);
    } catch (e) {
      print('Erro ao atualizar último login: $e');
      return false;
    }
  }

  /// Atualiza o nome preferido do usuário
  ///
  /// [nomePreferido] - O novo nome preferido do usuário
  static Future<bool> updatePreferredName(String nomePreferido) async {
    try {
      // Primeiro, recupera o usuário atual
      final currentUser = await getUser();

      if (currentUser == null) {
        return false;
      }

      // Cria uma nova instância com o nome preferido atualizado
      final updatedUser = currentUser.copyWith(nomePreferido: nomePreferido);

      // Salva o usuário atualizado (mantém a configuração atual do "lembrar-me")
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return await saveUser(updatedUser, rememberMe: rememberMe);
    } catch (e) {
      print('Erro ao atualizar nome preferido: $e');
      return false;
    }
  }

  /// Remove todos os dados do usuário do armazenamento local
  ///
  /// Este método é útil para fazer logout ou limpar dados corrompidos
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove os dados do usuário
      final userRemoved = await prefs.remove(_userKey);

      // Remove a preferência de "lembrar-me"
      final rememberRemoved = await prefs.remove(_rememberMeKey);

      return userRemoved && rememberRemoved;
    } catch (e) {
      print('Erro ao limpar dados do usuário: $e');
      return false;
    }
  }

  /// Verifica se o usuário escolheu "lembrar-me"
  ///
  /// Retorna true se o usuário escolheu ser lembrado
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Erro ao verificar remember me: $e');
      return false;
    }
  }
}
