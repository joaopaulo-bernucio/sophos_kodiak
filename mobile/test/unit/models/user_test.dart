import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/models/user.dart';

void main() {
  group('User Model Tests', () {
    group('Constructor and Properties', () {
      test('should create user with required fields', () {
        // Arrange & Act
        const user = User(cnpj: '12345678000100', senha: 'password123');

        // Assert
        expect(user.cnpj, equals('12345678000100'));
        expect(user.senha, equals('password123'));
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });

      test('should create user with all fields', () {
        // Arrange
        final loginTime = DateTime.now();

        // Act
        final user = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: loginTime,
        );

        // Assert
        expect(user.cnpj, equals('12345678000100'));
        expect(user.senha, equals('password123'));
        expect(user.nomePreferido, equals('João Silva'));
        expect(user.ultimoLogin, equals(loginTime));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        final user = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['cnpj'], equals('12345678000100'));
        expect(json['senha'], equals('password123'));
        expect(json['nomePreferido'], equals('João Silva'));
        expect(json['ultimoLogin'], equals('2024-01-15T10:30:00.000Z'));
      });

      test('should serialize to JSON with null fields', () {
        // Arrange
        const user = User(cnpj: '12345678000100', senha: 'password123');

        // Act
        final json = user.toJson();

        // Assert
        expect(json['cnpj'], equals('12345678000100'));
        expect(json['senha'], equals('password123'));
        expect(json['nomePreferido'], isNull);
        expect(json['ultimoLogin'], isNull);
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'cnpj': '12345678000100',
          'senha': 'password123',
          'nomePreferido': 'João Silva',
          'ultimoLogin': '2024-01-15T10:30:00Z',
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.cnpj, equals('12345678000100'));
        expect(user.senha, equals('password123'));
        expect(user.nomePreferido, equals('João Silva'));
        expect(
          user.ultimoLogin,
          equals(DateTime.parse('2024-01-15T10:30:00Z')),
        );
      });

      test('should deserialize from JSON with null fields', () {
        // Arrange
        final json = {
          'cnpj': '12345678000100',
          'senha': 'password123',
          'nomePreferido': null,
          'ultimoLogin': null,
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.cnpj, equals('12345678000100'));
        expect(user.senha, equals('password123'));
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final json = {'cnpj': '12345678000100', 'senha': 'password123'};

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.cnpj, equals('12345678000100'));
        expect(user.senha, equals('password123'));
        expect(user.nomePreferido, isNull);
        expect(user.ultimoLogin, isNull);
      });
    });

    group('copyWith Method', () {
      test('should copy user with updated fields', () {
        // Arrange
        const originalUser = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
        );

        // Act
        final updatedUser = originalUser.copyWith(
          nomePreferido: 'João Santos',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        // Assert
        expect(updatedUser.cnpj, equals('12345678000100'));
        expect(updatedUser.senha, equals('password123'));
        expect(updatedUser.nomePreferido, equals('João Santos'));
        expect(
          updatedUser.ultimoLogin,
          equals(DateTime.parse('2024-01-15T10:30:00Z')),
        );
      });

      test('should copy user without changes when no parameters provided', () {
        // Arrange
        final originalUser = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        // Act
        final copiedUser = originalUser.copyWith();

        // Assert
        expect(copiedUser.cnpj, equals(originalUser.cnpj));
        expect(copiedUser.senha, equals(originalUser.senha));
        expect(copiedUser.nomePreferido, equals(originalUser.nomePreferido));
        expect(copiedUser.ultimoLogin, equals(originalUser.ultimoLogin));
      });
    });

    group('toString Method', () {
      test('should return formatted string representation', () {
        // Arrange
        final user = User(
          cnpj: '12345678000100',
          senha: 'password123',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.parse('2024-01-15T10:30:00Z'),
        );

        // Act
        final userString = user.toString();

        // Assert
        expect(userString, contains('12345678000100'));
        expect(userString, contains('João Silva'));
        expect(userString, contains('2024-01-15'));
        expect(
          userString,
          isNot(contains('password123')),
        ); // Não deve mostrar senha
      });

      test('should handle null fields in toString', () {
        // Arrange
        const user = User(cnpj: '12345678000100', senha: 'password123');

        // Act
        final userString = user.toString();

        // Assert
        expect(userString, contains('12345678000100'));
        expect(userString, contains('null'));
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all fields are the same', () {
        // Arrange
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

        // Act & Assert
        expect(user1 == user2, isTrue);
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
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

        // Act & Assert
        expect(user1 == user2, isFalse);
        expect(user1.hashCode, isNot(equals(user2.hashCode)));
      });
    });
  });
}
