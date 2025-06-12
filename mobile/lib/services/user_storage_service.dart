import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserStorageService {
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';

  static Future<bool> saveUser(User user, {bool rememberMe = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userJson = jsonEncode(user.toJson());

      final userSaved = await prefs.setString(_userKey, userJson);

      final rememberSaved = await prefs.setBool(_rememberMeKey, rememberMe);

      return userSaved && rememberSaved;
    } catch (e) {
      print('Erro ao salvar usuário: $e');
      return false;
    }
  }

  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (!rememberMe) {
        return null;
      }

      final userJsonString = prefs.getString(_userKey);

      if (userJsonString == null) {
        return null;
      }

      final userJson = jsonDecode(userJsonString) as Map<String, dynamic>;

      return User.fromJson(userJson);
    } catch (e) {
      print('Erro ao recuperar usuário: $e');
      return null;
    }
  }

  static Future<bool> hasUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasData = prefs.containsKey(_userKey);
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return hasData && rememberMe;
    } catch (e) {
      print('Erro ao verificar dados do usuário: $e');
      return false;
    }
  }

  static Future<bool> updateLastLogin() async {
    try {
      final currentUser = await getUser();

      if (currentUser == null) {
        return false;
      }

      final updatedUser = currentUser.copyWith(ultimoLogin: DateTime.now());

      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return await saveUser(updatedUser, rememberMe: rememberMe);
    } catch (e) {
      print('Erro ao atualizar último login: $e');
      return false;
    }
  }

  static Future<bool> updatePreferredName(String nomePreferido) async {
    try {
      final currentUser = await getUser();

      if (currentUser == null) {
        return false;
      }

      final updatedUser = currentUser.copyWith(nomePreferido: nomePreferido);

      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      return await saveUser(updatedUser, rememberMe: rememberMe);
    } catch (e) {
      print('Erro ao atualizar nome preferido: $e');
      return false;
    }
  }

  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userRemoved = await prefs.remove(_userKey);

      final rememberRemoved = await prefs.remove(_rememberMeKey);

      return userRemoved && rememberRemoved;
    } catch (e) {
      print('Erro ao limpar dados do usuário: $e');
      return false;
    }
  }

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
