import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/services/auth_service.dart';
import '../../helpers/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late AuthService authService;
    setUp(() async {
      authService = AuthService();
      await authService.limparDados();
    });
    tearDown(() async {
      await authService.limparDados();
    });

    group('Login', () {
      test('deve fazer login com credenciais válidas', () async {
        final user = await authService.login(
          TestData.validCnpj,
          TestData.validPassword,
        );
        expect(user.cnpj, equals(TestData.validCnpj));
        expect(user.senha, equals(TestData.validPassword));
        expect(user.ultimoLogin, isNotNull);
        expect(
          user.ultimoLogin!.isBefore(
            DateTime.now().add(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      });

      test('deve rejeitar login com CNPJ vazio', () async {
        expect(
          () => authService.login('', TestData.validPassword),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'CNPJ é obrigatório',
            ),
          ),
        );
      });

      test('deve rejeitar login com senha vazia', () async {
        expect(
          () => authService.login(TestData.validCnpj, ''),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Senha é obrigatória',
            ),
          ),
        );
      });

      test('deve rejeitar login com CNPJ inválido', () async {
        expect(
          () => authService.login(TestData.invalidCnpj, TestData.validPassword),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'CNPJ ou senha incorretos',
            ),
          ),
        );
      });

      test('deve rejeitar login com senha inválida', () async {
        expect(
          () => authService.login(TestData.validCnpj, TestData.invalidPassword),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'CNPJ ou senha incorretos',
            ),
          ),
        );
      });

      test('deve rejeitar login com CNPJ e senha inválidos', () async {
        expect(
          () =>
              authService.login(TestData.invalidCnpj, TestData.invalidPassword),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'CNPJ ou senha incorretos',
            ),
          ),
        );
      });

      test('deve lidar com espaços em branco nas credenciais', () async {
        expect(
          () => authService.login('   ', '   '),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'CNPJ é obrigatório',
            ),
          ),
        );
      });

      test('deve simular delay realista no login', () async {
        final stopwatch = Stopwatch()..start();
        await authService.login(TestData.validCnpj, TestData.validPassword);
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Validação CNPJ', () {
      test('deve validar CNPJ com formato correto', () {
        expect(authService.validarFormatoCnpj(TestData.validCnpj), isTrue);
      });

      test('deve invalidar CNPJs com formato incorreto', () {
        for (final cnpj in TestData.invalidCnpjs) {
          expect(
            authService.validarFormatoCnpj(cnpj),
            isFalse,
            reason: 'CNPJ "$cnpj" deveria ser inválido',
          );
        }
      });

      test('deve validar variações de CNPJ válido', () {
        final validFormats = [
          '12.345.678/0001-90',
          '98.765.432/0001-12',
          '11.222.333/0001-45',
        ];
        for (final cnpj in validFormats) {
          expect(
            authService.validarFormatoCnpj(cnpj),
            isTrue,
            reason: 'CNPJ "$cnpj" deveria ser válido',
          );
        }
      });
    });

    group('Validação Senha', () {
      test('deve validar senha com 8 ou mais caracteres', () {
        expect(authService.validarSenha(TestData.validPassword), isTrue);
        expect(authService.validarSenha('12345678'), isTrue);
        expect(authService.validarSenha('senha_muito_longa_123'), isTrue);
      });

      test('deve invalidar senhas com menos de 8 caracteres', () {
        for (final senha in TestData.invalidPasswords) {
          expect(
            authService.validarSenha(senha),
            isFalse,
            reason: 'Senha "$senha" deveria ser inválida',
          );
        }
      });

      test('deve validar senhas exatamente com 8 caracteres', () {
        expect(authService.validarSenha('abcdefgh'), isTrue);
        expect(authService.validarSenha('12345678'), isTrue);
        expect(authService.validarSenha('A1b2C3d4'), isTrue);
      });
    });

    group('Estado de Autenticação', () {
      test(
        'deve retornar false para usuário não logado inicialmente',
        () async {
          final isLoggedIn = await authService.estaLogado();
          expect(isLoggedIn, isFalse);
        },
      );

      test('deve retornar null para usuário atual quando não logado', () async {
        final currentUser = await authService.obterUsuarioAtual();
        expect(currentUser, isNull);
      });

      test('deve persistir estado de login após login bem-sucedido', () async {
        await authService.login(TestData.validCnpj, TestData.validPassword);
        expect(await authService.estaLogado(), isTrue);
        final currentUser = await authService.obterUsuarioAtual();
        expect(currentUser, isNotNull);
        expect(currentUser!.cnpj, equals(TestData.validCnpj));
      });

      test(
        'deve manter dados do usuário entre instâncias do serviço',
        () async {
          await authService.login(TestData.validCnpj, TestData.validPassword);
          final novoAuthService = AuthService();
          expect(await novoAuthService.estaLogado(), isTrue);
          final usuario = await novoAuthService.obterUsuarioAtual();
          expect(usuario!.cnpj, equals(TestData.validCnpj));
        },
      );
    });

    group('Logout', () {
      test('deve fazer logout sem erros', () async {
        expect(() => authService.logout(), returnsNormally);
      });

      test('deve permitir múltiplos logouts sem erros', () async {
        await authService.logout();
        await authService.logout();
        await authService.logout();

        expect(true, isTrue);
      });

      test('deve limpar estado após logout', () async {
        await authService.login(TestData.validCnpj, TestData.validPassword);
        expect(await authService.estaLogado(), isTrue);
        await authService.logout();
        expect(await authService.estaLogado(), isFalse);
        expect(await authService.obterUsuarioAtual(), isNull);
      });
    });

    group('Gerenciamento de Nome Preferido', () {
      test(
        'deve lançar exceção ao atualizar nome sem usuário logado',
        () async {
          expect(
            () => authService.atualizarNomePreferido('Novo Nome'),
            throwsA(
              isA<AuthException>().having(
                (e) => e.message,
                'message',
                'Nenhum usuário logado',
              ),
            ),
          );
        },
      );

      test('deve atualizar nome preferido com usuário logado', () async {
        await authService.login(TestData.validCnpj, TestData.validPassword);
        const novoNome = 'João Atualizado';
        await authService.atualizarNomePreferido(novoNome);
        final usuario = await authService.obterUsuarioAtual();
        expect(usuario!.nomePreferido, equals(novoNome));
      });

      test('deve manter outros dados ao atualizar nome preferido', () async {
        final usuarioOriginal = await authService.login(
          TestData.validCnpj,
          TestData.validPassword,
        );
        await authService.atualizarNomePreferido('Nome Atualizado');
        final usuarioAtualizado = await authService.obterUsuarioAtual();
        expect(usuarioAtualizado!.cnpj, equals(usuarioOriginal.cnpj));
        expect(usuarioAtualizado.senha, equals(usuarioOriginal.senha));
        expect(usuarioAtualizado.nomePreferido, equals('Nome Atualizado'));
      });
    });

    group('Operações de Usuário', () {
      test('deve salvar usuário sem erros', () async {
        final user = TestData.createValidUser();

        expect(() => authService.salvarUsuario(user), returnsNormally);
      });

      test('deve limpar dados sem erros', () async {
        expect(() => authService.limparDados(), returnsNormally);
      });
    });

    group('Último Login', () {
      test(
        'deve retornar null para último login quando não há usuário',
        () async {
          final ultimoLogin = await authService.obterUltimoLogin();
          expect(ultimoLogin, isNull);
        },
      );

      test('deve registrar último login após login bem-sucedido', () async {
        final antesLogin = DateTime.now();
        await authService.login(TestData.validCnpj, TestData.validPassword);
        final aposLogin = DateTime.now();
        final ultimoLogin = await authService.obterUltimoLogin();
        expect(ultimoLogin, isNotNull);
        expect(
          ultimoLogin!.isAfter(antesLogin.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          ultimoLogin.isBefore(aposLogin.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('AuthException', () {
      test('deve criar AuthException corretamente', () {
        const exception = AuthException('Teste de erro');
        expect(exception.message, equals('Teste de erro'));
        expect(exception.toString(), equals('AuthException: Teste de erro'));
      });

      test('deve ser uma Exception', () {
        const exception = AuthException('Teste');
        expect(exception, isA<Exception>());
      });
    });

    group('Edge Cases', () {
      test('deve lidar com CNPJ com espaços extras', () async {
        final cnpjComEspacos = '  ${TestData.validCnpj}  ';
        expect(
          () => authService.login(cnpjComEspacos, TestData.validPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('deve lidar com senha com espaços extras', () async {
        final senhaComEspacos = '  ${TestData.validPassword}  ';
        expect(
          () => authService.login(TestData.validCnpj, senhaComEspacos),
          throwsA(isA<AuthException>()),
        );
      });

      test('deve manter consistência em múltiplas operações', () async {
        await authService.login(TestData.validCnpj, TestData.validPassword);
        expect(await authService.estaLogado(), isTrue);

        await authService.logout();
        expect(await authService.estaLogado(), isFalse);

        await authService.login(TestData.validCnpj, TestData.validPassword);
        expect(await authService.estaLogado(), isTrue);
      });

      test('deve validar credenciais com caracteres especiais', () async {
        expect(
          () => authService.login('12.345.678/0001-9@', TestData.validPassword),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('Integração com UserStorageService', () {
      test('deve salvar usuário com remember me ativado após login', () async {
        await authService.login(TestData.validCnpj, TestData.validPassword);
        expect(await authService.estaLogado(), isTrue);
        final usuario = await authService.obterUsuarioAtual();
        expect(usuario, isNotNull);
        expect(usuario!.cnpj, equals(TestData.validCnpj));
      });

      test('deve preservar nome preferido existente ao fazer login', () async {
        final usuarioExistente = TestData.createValidUser(
          nomePreferido: 'Nome Existente',
        );
        await authService.salvarUsuario(usuarioExistente);
        final usuarioLogado = await authService.login(
          TestData.validCnpj,
          TestData.validPassword,
        );
        expect(usuarioLogado.nomePreferido, equals('Nome Existente'));
      });

      test(
        'deve manter consistência entre operações de auth e storage',
        () async {
          await authService.login(TestData.validCnpj, TestData.validPassword);
          await authService.atualizarNomePreferido('Nome Via Auth');
          final usuario = await authService.obterUsuarioAtual();
          expect(usuario!.nomePreferido, equals('Nome Via Auth'));
          await authService.logout();
          expect(await authService.estaLogado(), isFalse);
        },
      );
    });
  });
}
