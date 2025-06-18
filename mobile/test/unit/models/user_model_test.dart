import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/models/user.dart';
import '../../helpers/test_data.dart';

void main() {
  group('User Model', () {
    group('Constructor', () {
      test('deve criar usuário com dados válidos', () {
        final user = TestData.createValidUser();

        expect(user.cnpj, equals(TestData.validCnpj));
        expect(user.senha, equals(TestData.validPassword));
        expect(user.nomePreferido, equals(TestData.validUserName));
        expect(user.ultimoLogin, isNotNull);
      });

      test('deve criar usuário sem nome preferido', () {
        final user = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
        );

        expect(user.cnpj, equals(TestData.validCnpj));
        expect(user.senha, equals(TestData.validPassword));
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });
    });

    group('JSON Serialization', () {
      test('deve converter User para JSON corretamente', () {
        final now = DateTime.now();
        final user = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
          nomePreferido: TestData.validUserName,
          ultimoLogin: now,
        );

        final json = user.toJson();

        expect(json['cnpj'], equals(TestData.validCnpj));
        expect(json['senha'], equals(TestData.validPassword));
        expect(json['nomePreferido'], equals(TestData.validUserName));
        expect(json['ultimoLogin'], equals(now.toIso8601String()));
      });

      test('deve converter JSON para User corretamente', () {
        final now = DateTime.now();
        final json = {
          'cnpj': TestData.validCnpj,
          'senha': TestData.validPassword,
          'nomePreferido': TestData.validUserName,
          'ultimoLogin': now.toIso8601String(),
        };

        final user = User.fromJson(json);

        expect(user.cnpj, equals(TestData.validCnpj));
        expect(user.senha, equals(TestData.validPassword));
        expect(user.nomePreferido, equals(TestData.validUserName));
        expect(user.ultimoLogin, equals(now));
      });

      test('deve lidar com campos opcionais nulos no JSON', () {
        final json = {
          'cnpj': TestData.validCnpj,
          'senha': TestData.validPassword,
        };

        final user = User.fromJson(json);

        expect(user.cnpj, equals(TestData.validCnpj));
        expect(user.senha, equals(TestData.validPassword));
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });

      test('deve manter consistência na conversão JSON -> User -> JSON', () {
        final originalJson = {
          'cnpj': TestData.validCnpj,
          'senha': TestData.validPassword,
          'nomePreferido': TestData.validUserName,
          'ultimoLogin': DateTime.now().toIso8601String(),
        };

        final user = User.fromJson(originalJson);
        final convertedJson = user.toJson();

        expect(convertedJson, equals(originalJson));
      });
    });

    group('CopyWith', () {
      test('deve criar cópia com novos valores', () {
        final originalUser = TestData.createValidUser();
        final newCnpj = '98.765.432/0001-09';
        final newNome = 'Maria Silva';

        final updatedUser = originalUser.copyWith(
          cnpj: newCnpj,
          nomePreferido: newNome,
        );

        expect(updatedUser.cnpj, equals(newCnpj));
        expect(
          updatedUser.senha,
          equals(originalUser.senha),
        ); // Deve manter original
        expect(updatedUser.nomePreferido, equals(newNome));
        expect(
          updatedUser.ultimoLogin,
          equals(originalUser.ultimoLogin),
        ); // Deve manter original
      });

      test('deve manter valores originais quando não especificado', () {
        final originalUser = TestData.createValidUser();

        final copiedUser = originalUser.copyWith();

        expect(copiedUser.cnpj, equals(originalUser.cnpj));
        expect(copiedUser.senha, equals(originalUser.senha));
        expect(copiedUser.nomePreferido, equals(originalUser.nomePreferido));
        expect(copiedUser.ultimoLogin, equals(originalUser.ultimoLogin));
      });
    });

    group('Equality', () {
      test('deve considerar iguais usuários com mesmos dados', () {
        final now = DateTime.now();
        final user1 = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
          nomePreferido: TestData.validUserName,
          ultimoLogin: now,
        );
        final user2 = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
          nomePreferido: TestData.validUserName,
          ultimoLogin: now,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('deve considerar diferentes usuários com dados diferentes', () {
        final user1 = TestData.createValidUser();
        final user2 = TestData.createValidUser(cnpj: '98.765.432/0001-09');

        expect(user1, isNot(equals(user2)));
        expect(user1.hashCode, isNot(equals(user2.hashCode)));
      });

      test('deve considerar diferentes usuários com senhas diferentes', () {
        final user1 = TestData.createValidUser();
        final user2 = TestData.createValidUser(senha: 'different123');

        expect(user1, isNot(equals(user2)));
      });
    });

    group('ToString', () {
      test('deve gerar string representativa do usuário', () {
        final user = TestData.createValidUser();
        final userString = user.toString();

        expect(userString, contains('User('));
        expect(userString, contains('cnpj: ${TestData.validCnpj}'));
        expect(
          userString,
          contains('nomePreferido: ${TestData.validUserName}'),
        );
        expect(userString, contains('ultimoLogin:'));
      });

      test('deve lidar com campos nulos na string', () {
        final user = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
        );
        final userString = user.toString();

        expect(userString, contains('nomePreferido: null'));
        expect(userString, contains('ultimoLogin: null'));
      });
    });
  });
}
