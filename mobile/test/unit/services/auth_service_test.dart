import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/services/auth_service.dart';
import 'package:sophos_kodiak/models/user.dart';
import '../../helpers/test_data.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
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
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(400));
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
    });

    group('Logout', () {
      test('deve fazer logout sem erros', () async {
        expect(() => authService.logout(), returnsNormally);
      });

      test('deve permitir múltiplos logouts sem erros', () async {
        await authService.logout();
        await authService.logout();
        await authService.logout();

        expect(true, isTrue); // Se chegou aqui, não houve exceção
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
        // Login válido
        await authService.login(TestData.validCnpj, TestData.validPassword);

        // Logout
        await authService.logout();

        // Verificar estado
        final isLoggedIn = await authService.estaLogado();
        expect(isLoggedIn, isFalse);

        // Tentar login novamente
        final user = await authService.login(
          TestData.validCnpj,
          TestData.validPassword,
        );
        expect(user.cnpj, equals(TestData.validCnpj));
      });
    });
  });
}
