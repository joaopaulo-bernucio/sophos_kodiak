import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/models/user.dart';
import '../../helpers/test_data.dart';

void main() {
  group('User Model', () {
    group('Constructor', () {
      test('deve criar usuário com dados válidos', () {
        final user = TestData.createValidUser();

        expect(user.cnpj, TestData.validCnpj);
        expect(user.senha, TestData.validPassword);
        expect(user.nomePreferido, TestData.validUserName);
        expect(user.ultimoLogin, isNotNull);
      });

      test('deve criar usuário sem nome preferido', () {
        final user = User(
          cnpj: TestData.validCnpj,
          senha: TestData.validPassword,
        );

        expect(user.cnpj, TestData.validCnpj);
        expect(user.senha, TestData.validPassword);
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

        expect(json['cnpj'], TestData.validCnpj);
        expect(json['senha'], TestData.validPassword);
        expect(json['nomePreferido'], TestData.validUserName);
        expect(json['ultimoLogin'], now.toIso8601String());
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

        expect(user.cnpj, TestData.validCnpj);
        expect(user.senha, TestData.validPassword);
        expect(user.nomePreferido, TestData.validUserName);
        expect(user.ultimoLogin, now);
      });

      test('deve lidar com campos opcionais nulos no JSON', () {
        final json = {
          'cnpj': TestData.validCnpj,
          'senha': TestData.validPassword,
        };

        final user = User.fromJson(json);

        expect(user.cnpj, TestData.validCnpj);
        expect(user.senha, TestData.validPassword);
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

      test('deve serializar com campos nulos', () {
        const user = User(cnpj: '12345678000100', senha: 'password123');

        final json = user.toJson();

        expect(json['cnpj'], '12345678000100');
        expect(json['senha'], 'password123');
        expect(json['nomePreferido'], isNull);
        expect(json['ultimoLogin'], isNull);
      });

      test('deve deserializar com campos nulos', () {
        final json = {
          'cnpj': '12345678000100',
          'senha': 'password123',
          'nomePreferido': null,
          'ultimoLogin': null,
        };

        final user = User.fromJson(json);

        expect(user.cnpj, '12345678000100');
        expect(user.senha, 'password123');
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });

      test('deve lidar com campos opcionais ausentes no JSON', () {
        final json = {'cnpj': '12345678000100', 'senha': 'password123'};

        final user = User.fromJson(json);

        expect(user.cnpj, '12345678000100');
        expect(user.senha, 'password123');
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
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

        expect(updatedUser.cnpj, newCnpj);
        expect(updatedUser.senha, originalUser.senha); // Deve manter original
        expect(updatedUser.nomePreferido, newNome);
        expect(
          updatedUser.ultimoLogin,
          originalUser.ultimoLogin,
        ); // Deve manter original
      });

      test('deve manter valores originais quando não especificado', () {
        final originalUser = TestData.createValidUser();

        final copiedUser = originalUser.copyWith();

        expect(copiedUser.cnpj, originalUser.cnpj);
        expect(copiedUser.senha, originalUser.senha);
        expect(copiedUser.nomePreferido, originalUser.nomePreferido);
        expect(copiedUser.ultimoLogin, originalUser.ultimoLogin);
      });

      test('deve copiar usuário com campos atualizados', () {
        const originalUser = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
        );

        final updatedUser = originalUser.copyWith(
          nomePreferido: 'João Santos',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        expect(updatedUser.cnpj, '12345678000100');
        expect(updatedUser.senha, 'password123');
        expect(updatedUser.nomePreferido, 'João Santos');
        expect(updatedUser.ultimoLogin, DateTime.parse('2024-01-15T10:30:00Z'));
      });

      test(
        'deve copiar usuário sem mudanças quando nenhum parâmetro fornecido',
        () {
          final originalUser = User(
            cnpj: '12345678000100',
            senha: 'password123',
            nomePreferido: 'João Silva',
            ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
          );

          final copiedUser = originalUser.copyWith();

          expect(copiedUser.cnpj, originalUser.cnpj);
          expect(copiedUser.senha, originalUser.senha);
          expect(copiedUser.nomePreferido, originalUser.nomePreferido);
          expect(copiedUser.ultimoLogin, originalUser.ultimoLogin);
        },
      );
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

        expect(user1 == user2, isTrue);
        expect(user1.hashCode, user2.hashCode);
      });

      test('deve considerar diferentes usuários com dados diferentes', () {
        final user1 = TestData.createValidUser();
        final user2 = TestData.createValidUser(cnpj: '98.765.432/0001-09');

        expect(user1 == user2, isFalse);
        expect(user1.hashCode, isNot(user2.hashCode));
      });

      test('deve considerar diferentes usuários com senhas diferentes', () {
        final user1 = TestData.createValidUser();
        final user2 = TestData.createValidUser(senha: 'different123');

        expect(user1 == user2, isFalse);
      });

      test('deve ser igual quando todos os campos são iguais', () {
        final user1 = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        final user2 = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        expect(user1 == user2, isTrue);
        expect(user1.hashCode, user2.hashCode);
      });

      test('não deve ser igual quando campos diferem', () {
        const user1 = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
        );

        const user2 = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'Maria Silva',
        );

        expect(user1 == user2, isFalse);
        expect(user1.hashCode, isNot(user2.hashCode));
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

      test('deve retornar representação string formatada', () {
        final user = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        final userString = user.toString();

        expect(userString, contains('12345678000100'));
        expect(userString, contains('João Silva'));
        expect(userString, contains('2024-01-15'));
        expect(
          userString,
          isNot(contains('password123')),
        ); // Não deve mostrar senha
      });

      test('deve lidar com campos nulos no toString', () {
        const user = User(cnpj: '12345678000100', senha: 'password123');

        final userString = user.toString();

        expect(userString, contains('12345678000100'));
        expect(userString, contains('null'));
      });
    });
  });
}
