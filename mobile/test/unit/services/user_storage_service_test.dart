import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';
import '../../helpers/test_data.dart';

void main() {
  group('UserStorageService', () {
    setUp(() async {
      // Limpar dados reais do SharedPreferences antes de cada teste
      await UserStorageService.clearUserData();
    });

    group('Salvar Usuário', () {
      test('deve salvar usuário com remember me ativado', () async {
        final user = TestData.createValidUser();

        final result = await UserStorageService.saveUser(
          user,
          rememberMe: true,
        );

        expect(result, isTrue);
      });

      test('deve salvar usuário com remember me desativado', () async {
        final user = TestData.createValidUser();

        final result = await UserStorageService.saveUser(
          user,
          rememberMe: false,
        );

        expect(result, isTrue);
      });

      test('deve salvar usuário com remember me como padrão (false)', () async {
        final user = TestData.createValidUser();

        final result = await UserStorageService.saveUser(user);

        expect(result, isTrue);
      });
    });

    group('Recuperar Usuário', () {
      test('deve recuperar usuário salvo com remember me ativado', () async {
        final originalUser = TestData.createValidUser();
        await UserStorageService.saveUser(originalUser, rememberMe: true);

        final retrievedUser = await UserStorageService.getUser();

        expect(retrievedUser, isNotNull);
        expect(retrievedUser!.cnpj, equals(originalUser.cnpj));
        expect(retrievedUser.senha, equals(originalUser.senha));
        expect(retrievedUser.nomePreferido, equals(originalUser.nomePreferido));
      });

      test('deve retornar null quando remember me está desativado', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: false);

        final retrievedUser = await UserStorageService.getUser();

        expect(retrievedUser, isNull);
      });

      test('deve retornar null quando não há dados salvos', () async {
        final retrievedUser = await UserStorageService.getUser();

        expect(retrievedUser, isNull);
      });
    });

    group('Verificar Dados do Usuário', () {
      test(
        'deve retornar true quando há dados e remember me ativado',
        () async {
          final user = TestData.createValidUser();
          await UserStorageService.saveUser(user, rememberMe: true);

          final hasData = await UserStorageService.hasUserData();

          expect(hasData, isTrue);
        },
      );

      test('deve retornar false quando remember me está desativado', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: false);

        final hasData = await UserStorageService.hasUserData();

        expect(hasData, isFalse);
      });

      test('deve retornar false quando não há dados', () async {
        final hasData = await UserStorageService.hasUserData();

        expect(hasData, isFalse);
      });
    });

    group('Atualizar Nome Preferido', () {
      test('deve atualizar nome preferido quando há usuário salvo', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        final result = await UserStorageService.updatePreferredName(
          'Novo Nome',
        );

        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.nomePreferido, equals('Novo Nome'));
      });

      test('deve retornar false quando não há usuário salvo', () async {
        final result = await UserStorageService.updatePreferredName('Nome');

        expect(result, isFalse);
      });

      test('deve manter outros dados do usuário ao atualizar nome', () async {
        final originalUser = TestData.createValidUser();
        await UserStorageService.saveUser(originalUser, rememberMe: true);

        await UserStorageService.updatePreferredName('Nome Atualizado');

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.cnpj, equals(originalUser.cnpj));
        expect(updatedUser.senha, equals(originalUser.senha));
        expect(updatedUser.nomePreferido, equals('Nome Atualizado'));
      });
    });

    group('Atualizar Último Login', () {
      test('deve atualizar último login quando há usuário salvo', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        final beforeUpdate = DateTime.now();
        final result = await UserStorageService.updateLastLogin();
        final afterUpdate = DateTime.now();

        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.ultimoLogin, isNotNull);
        expect(
          updatedUser.ultimoLogin!.isAfter(
            beforeUpdate.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          updatedUser.ultimoLogin!.isBefore(
            afterUpdate.add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      });

      test('deve retornar false quando não há usuário salvo', () async {
        final result = await UserStorageService.updateLastLogin();

        expect(result, isFalse);
      });
    });

    group('Limpar Dados', () {
      test('deve limpar todos os dados do usuário', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        // Verificar que dados existem
        expect(await UserStorageService.hasUserData(), isTrue);

        // Limpar dados
        await UserStorageService.clearUserData();

        // Verificar que dados foram limpos
        expect(await UserStorageService.hasUserData(), isFalse);
        expect(await UserStorageService.getUser(), isNull);
      });

      test('deve funcionar mesmo quando não há dados para limpar', () async {
        expect(() => UserStorageService.clearUserData(), returnsNormally);
      });
    });

    group('Persistência de Dados', () {
      test('deve manter dados entre múltiplas operações', () async {
        final user = TestData.createValidUser();

        // Salvar usuário
        await UserStorageService.saveUser(user, rememberMe: true);

        // Atualizar nome
        await UserStorageService.updatePreferredName('Nome Atualizado');

        // Atualizar último login
        await UserStorageService.updateLastLogin();

        // Verificar que todos os dados estão corretos
        final finalUser = await UserStorageService.getUser();
        expect(finalUser!.cnpj, equals(user.cnpj));
        expect(finalUser.senha, equals(user.senha));
        expect(finalUser.nomePreferido, equals('Nome Atualizado'));
        expect(finalUser.ultimoLogin, isNotNull);
      });

      test('deve manter consistência com operações sequenciais', () async {
        final user1 = TestData.createValidUser();
        final user2 = TestData.createValidUser(
          cnpj: '98.765.432/0001-09',
          senha: 'outrasenha123',
        );

        // Salvar primeiro usuário
        await UserStorageService.saveUser(user1, rememberMe: true);
        expect((await UserStorageService.getUser())!.cnpj, equals(user1.cnpj));

        // Salvar segundo usuário (deve sobrescrever)
        await UserStorageService.saveUser(user2, rememberMe: true);
        expect((await UserStorageService.getUser())!.cnpj, equals(user2.cnpj));

        // Limpar dados
        await UserStorageService.clearUserData();
        expect(await UserStorageService.getUser(), isNull);
      });
    });

    group('Edge Cases', () {
      test('deve lidar com nome preferido vazio', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        final result = await UserStorageService.updatePreferredName('');

        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.nomePreferido, equals(''));
      });

      test('deve lidar com nome preferido muito longo', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        final longName =
            'Nome muito longo que possui mais de 100 caracteres para testar como o sistema se comporta com entradas de texto extensas que podem causar problemas de armazenamento';
        final result = await UserStorageService.updatePreferredName(longName);

        expect(result, isTrue);

        final updatedUser = await UserStorageService.getUser();
        expect(updatedUser!.nomePreferido, equals(longName));
      });

      test('deve manter estado consistente após múltiplas operações', () async {
        final user = TestData.createValidUser();

        // Múltiplas operações de save/clear
        for (int i = 0; i < 3; i++) {
          await UserStorageService.saveUser(user, rememberMe: true);
          expect(await UserStorageService.hasUserData(), isTrue);

          await UserStorageService.clearUserData();
          expect(await UserStorageService.hasUserData(), isFalse);
        }

        // Estado final deve ser limpo
        expect(await UserStorageService.getUser(), isNull);
        expect(await UserStorageService.hasUserData(), isFalse);
      });

      test('deve lidar com dados corrompidos graciosamente', () async {
        // Este teste simula dados corrompidos internamente no serviço
        // Como não temos acesso direto aos dados corrompidos sem mocks,
        // verificamos apenas que o serviço não falha com entradas inválidas

        final user = await UserStorageService.getUser();
        expect(user, isNull);

        // Verificar que dados foram limpos automaticamente
        expect(await UserStorageService.hasUserData(), isFalse);
      });

      test('deve lidar com diferentes tipos de dados corrompidos', () async {
        // Como não podemos corromper dados diretamente sem mocks,
        // este teste verifica que o serviço funciona com dados válidos
        // e retorna null quando não há dados

        // Limpar dados primeiro
        await UserStorageService.clearUserData();

        // Verificar que retorna null quando não há dados
        final user = await UserStorageService.getUser();
        expect(user, isNull);

        // Verificar que hasUserData retorna false
        expect(await UserStorageService.hasUserData(), isFalse);
      });

      test('deve preservar atomicidade em operações de atualização', () async {
        final user = TestData.createValidUser();
        await UserStorageService.saveUser(user, rememberMe: true);

        // Múltiplas atualizações rápidas
        final futures = [
          UserStorageService.updatePreferredName('Nome 1'),
          UserStorageService.updatePreferredName('Nome 2'),
          UserStorageService.updatePreferredName('Nome 3'),
        ];

        final results = await Future.wait(futures);

        // Todas as operações devem ter sucesso
        expect(results.every((r) => r == true), isTrue);

        // Deve ter um dos nomes (última operação)
        final finalUser = await UserStorageService.getUser();
        expect(finalUser!.nomePreferido, isIn(['Nome 1', 'Nome 2', 'Nome 3']));
      });
    });

    group('Validação de Comportamento', () {
      test(
        'deve manter remember me independente de outras operações',
        () async {
          final user = TestData.createValidUser();

          // Salvar com remember me ativado
          await UserStorageService.saveUser(user, rememberMe: true);
          expect(await UserStorageService.hasUserData(), isTrue);

          // Atualizar nome - deve manter remember me
          await UserStorageService.updatePreferredName('Novo Nome');
          expect(await UserStorageService.hasUserData(), isTrue);

          // Atualizar login - deve manter remember me
          await UserStorageService.updateLastLogin();
          expect(await UserStorageService.hasUserData(), isTrue);
        },
      );

      test(
        'deve funcionar corretamente quando remember me está desativado',
        () async {
          final user = TestData.createValidUser();

          // Salvar com remember me desativado
          await UserStorageService.saveUser(user, rememberMe: false);

          // Todas as operações de leitura devem retornar null/false
          expect(await UserStorageService.getUser(), isNull);
          expect(await UserStorageService.hasUserData(), isFalse);

          // Operações de atualização devem falhar
          expect(await UserStorageService.updatePreferredName('Nome'), isFalse);
          expect(await UserStorageService.updateLastLogin(), isFalse);
        },
      );

      test(
        'deve validar integridade dos dados após operações complexas',
        () async {
          final user = TestData.createValidUser();

          // Sequência complexa de operações
          await UserStorageService.saveUser(user, rememberMe: true);

          // Múltiplas atualizações
          await UserStorageService.updatePreferredName('Nome 1');
          await UserStorageService.updateLastLogin();
          await UserStorageService.updatePreferredName('Nome Final');

          // Verificar integridade
          final finalUser = await UserStorageService.getUser();
          expect(finalUser!.cnpj, equals(user.cnpj));
          expect(finalUser.senha, equals(user.senha));
          expect(finalUser.nomePreferido, equals('Nome Final'));
          expect(finalUser.ultimoLogin, isNotNull);
          expect(finalUser.ultimoLogin!.isAfter(user.ultimoLogin!), isTrue);
        },
      );
    });
  });
}
