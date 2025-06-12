// Testes para o UserStorageService
//
// Este arquivo testa as funcionalidades de persistência de dados do usuário
// usando SharedPreferences, incluindo operações de salvar, recuperar e limpar dados.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/models/user.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';

void main() {
  group('UserStorageService Tests', () {
    setUp(() {
      // Limpar SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
    });

    group('saveUser', () {
      test('deve salvar usuário com rememberMe = true', () async {
        // Arrange
        final user = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          nomePreferido: 'João',
          ultimoLogin: DateTime(2024, 1, 1),
        );

        // Act
        final result = await UserStorageService.saveUser(
          user,
          rememberMe: true,
        );

        // Assert
        expect(result, isTrue);

        // Verificar se os dados foram salvos
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('user_data'), isTrue);
        expect(prefs.getBool('remember_me'), isTrue);
      });

      test('deve salvar usuário com rememberMe = false', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');

        // Act
        final result = await UserStorageService.saveUser(
          user,
          rememberMe: false,
        );

        // Assert
        expect(result, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('user_data'), isTrue);
        expect(prefs.getBool('remember_me'), isFalse);
      });

      test('deve salvar dados JSON válidos', () async {
        // Arrange
        final user = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          nomePreferido: 'João',
          ultimoLogin: DateTime(2024, 1, 1, 10, 30),
        );

        // Act
        await UserStorageService.saveUser(user, rememberMe: true);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        expect(userJson, isNotNull);
        expect(userJson, contains('12.345.678/0001-90'));
        expect(userJson, contains('teste123'));
        expect(userJson, contains('João'));
        expect(userJson, contains('2024-01-01T10:30:00.000'));
      });
    });

    group('getUser', () {
      test('deve retornar usuário quando rememberMe = true', () async {
        // Arrange
        final originalUser = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          nomePreferido: 'João',
          ultimoLogin: DateTime(2024, 1, 1),
        );

        await UserStorageService.saveUser(originalUser, rememberMe: true);

        // Act
        final retrievedUser = await UserStorageService.getUser();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.cnpj, equals('12.345.678/0001-90'));
        expect(retrievedUser.senha, equals('teste123'));
        expect(retrievedUser.nomePreferido, equals('João'));
        expect(retrievedUser.ultimoLogin, equals(DateTime(2024, 1, 1)));
      });

      test('deve retornar null quando rememberMe = false', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');

        await UserStorageService.saveUser(user, rememberMe: false);

        // Act
        final retrievedUser = await UserStorageService.getUser();

        // Assert
        expect(retrievedUser, isNull);
      });

      test('deve retornar null quando não há dados salvos', () async {
        // Act
        final retrievedUser = await UserStorageService.getUser();

        // Assert
        expect(retrievedUser, isNull);
      });

      test('deve preservar todos os campos opcionais', () async {
        // Arrange
        final originalUser = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          nomePreferido: null, // Campo opcional
          ultimoLogin: null, // Campo opcional
        );

        await UserStorageService.saveUser(originalUser, rememberMe: true);

        // Act
        final retrievedUser = await UserStorageService.getUser();

        // Assert
        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.nomePreferido, isNull);
        expect(retrievedUser.ultimoLogin, isNull);
      });
    });

    group('hasUserData', () {
      test('deve retornar true quando há dados e rememberMe = true', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');
        await UserStorageService.saveUser(user, rememberMe: true);

        // Act
        final hasData = await UserStorageService.hasUserData();

        // Assert
        expect(hasData, isTrue);
      });

      test(
        'deve retornar false quando há dados mas rememberMe = false',
        () async {
          // Arrange
          final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');
          await UserStorageService.saveUser(user, rememberMe: false);

          // Act
          final hasData = await UserStorageService.hasUserData();

          // Assert
          expect(hasData, isFalse);
        },
      );

      test('deve retornar false quando não há dados', () async {
        // Act
        final hasData = await UserStorageService.hasUserData();

        // Assert
        expect(hasData, isFalse);
      });
    });

    group('updateLastLogin', () {
      test('deve atualizar último login quando há usuário salvo', () async {
        // Arrange
        final user = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          ultimoLogin: DateTime(2024, 1, 1),
        );
        await UserStorageService.saveUser(user, rememberMe: true);

        // Act
        final result = await UserStorageService.updateLastLogin();

        // Assert
        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.ultimoLogin, isNotNull);
        expect(updatedUser.ultimoLogin!.isAfter(DateTime(2024, 1, 1)), isTrue);
      });

      test('deve retornar false quando não há usuário salvo', () async {
        // Act
        final result = await UserStorageService.updateLastLogin();

        // Assert
        expect(result, isFalse);
      });
    });

    group('updatePreferredName', () {
      test('deve atualizar nome preferido quando há usuário salvo', () async {
        // Arrange
        final user = User(
          cnpj: '12.345.678/0001-90',
          senha: 'teste123',
          nomePreferido: 'João',
        );
        await UserStorageService.saveUser(user, rememberMe: true);

        // Act
        final result = await UserStorageService.updatePreferredName(
          'João Paulo',
        );

        // Assert
        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.nomePreferido, equals('João Paulo'));
        expect(
          updatedUser.cnpj,
          equals('12.345.678/0001-90'),
        ); // Outros campos preservados
      });

      test('deve retornar false quando não há usuário salvo', () async {
        // Act
        final result = await UserStorageService.updatePreferredName('João');

        // Assert
        expect(result, isFalse);
      });
    });

    group('clearUserData', () {
      test('deve remover todos os dados do usuário', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');
        await UserStorageService.saveUser(user, rememberMe: true);

        // Act
        final result = await UserStorageService.clearUserData();

        // Assert
        expect(result, isTrue);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('user_data'), isFalse);
        expect(prefs.containsKey('remember_me'), isFalse);

        final retrievedUser = await UserStorageService.getUser();
        expect(retrievedUser, isNull);
      });

      test(
        'deve retornar true mesmo quando não há dados para remover',
        () async {
          // Act
          final result = await UserStorageService.clearUserData();

          // Assert
          expect(result, isTrue);
        },
      );
    });

    group('isRememberMeEnabled', () {
      test('deve retornar true quando rememberMe está ativado', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');
        await UserStorageService.saveUser(user, rememberMe: true);

        // Act
        final isEnabled = await UserStorageService.isRememberMeEnabled();

        // Assert
        expect(isEnabled, isTrue);
      });

      test('deve retornar false quando rememberMe está desativado', () async {
        // Arrange
        final user = User(cnpj: '12.345.678/0001-90', senha: 'teste123');
        await UserStorageService.saveUser(user, rememberMe: false);

        // Act
        final isEnabled = await UserStorageService.isRememberMeEnabled();

        // Assert
        expect(isEnabled, isFalse);
      });

      test('deve retornar false quando não há configuração salva', () async {
        // Act
        final isEnabled = await UserStorageService.isRememberMeEnabled();

        // Assert
        expect(isEnabled, isFalse);
      });
    });
  });

  group('User Model Tests', () {
    test('deve converter para JSON corretamente', () {
      // Arrange
      final user = User(
        cnpj: '12.345.678/0001-90',
        senha: 'teste123',
        nomePreferido: 'João',
        ultimoLogin: DateTime(2024, 1, 1, 10, 30),
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['cnpj'], equals('12.345.678/0001-90'));
      expect(json['senha'], equals('teste123'));
      expect(json['nomePreferido'], equals('João'));
      expect(json['ultimoLogin'], equals('2024-01-01T10:30:00.000'));
    });

    test('deve converter de JSON corretamente', () {
      // Arrange
      final json = {
        'cnpj': '12.345.678/0001-90',
        'senha': 'teste123',
        'nomePreferido': 'João',
        'ultimoLogin': '2024-01-01T10:30:00.000',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.cnpj, equals('12.345.678/0001-90'));
      expect(user.senha, equals('teste123'));
      expect(user.nomePreferido, equals('João'));
      expect(user.ultimoLogin, equals(DateTime(2024, 1, 1, 10, 30)));
    });

    test('deve lidar com campos opcionais nulos no JSON', () {
      // Arrange
      final json = {
        'cnpj': '12.345.678/0001-90',
        'senha': 'teste123',
        'nomePreferido': null,
        'ultimoLogin': null,
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.cnpj, equals('12.345.678/0001-90'));
      expect(user.senha, equals('teste123'));
      expect(user.nomePreferido, isNull);
      expect(user.ultimoLogin, isNull);
    });

    test('copyWith deve preservar campos não alterados', () {
      // Arrange
      final original = User(
        cnpj: '12.345.678/0001-90',
        senha: 'teste123',
        nomePreferido: 'João',
        ultimoLogin: DateTime(2024, 1, 1),
      );

      // Act
      final updated = original.copyWith(nomePreferido: 'João Paulo');

      // Assert
      expect(updated.cnpj, equals(original.cnpj));
      expect(updated.senha, equals(original.senha));
      expect(updated.nomePreferido, equals('João Paulo'));
      expect(updated.ultimoLogin, equals(original.ultimoLogin));
    });

    test('toString não deve incluir senha por segurança', () {
      // Arrange
      final user = User(
        cnpj: '12.345.678/0001-90',
        senha: 'senhasecreta',
        nomePreferido: 'João',
      );

      // Act
      final userString = user.toString();

      // Assert
      expect(userString, contains('12.345.678/0001-90'));
      expect(userString, contains('João'));
      expect(userString, isNot(contains('senhasecreta')));
    });

    test('operador == deve comparar todos os campos', () {
      // Arrange
      final user1 = User(
        cnpj: '12.345.678/0001-90',
        senha: 'teste123',
        nomePreferido: 'João',
        ultimoLogin: DateTime(2024, 1, 1),
      );

      final user2 = User(
        cnpj: '12.345.678/0001-90',
        senha: 'teste123',
        nomePreferido: 'João',
        ultimoLogin: DateTime(2024, 1, 1),
      );

      final user3 = User(
        cnpj: '12.345.678/0001-90',
        senha: 'diferente',
        nomePreferido: 'João',
        ultimoLogin: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(user1 == user2, isTrue);
      expect(user1 == user3, isFalse);
      expect(user1.hashCode == user2.hashCode, isTrue);
    });
  });
}
