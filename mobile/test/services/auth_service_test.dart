// Testes para o serviço de autenticação do Sophos Kodiak
//
// Este arquivo testa todas as funcionalidades do AuthService,
// incluindo login, logout, gerenciamento de usuário e validações.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sophos_kodiak/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      // Limpar shared preferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
    });

    group('Usuario Model Tests', () {
      test('Deve criar Usuario a partir de JSON válido', () {
        // Arrange
        final json = {
          'cnpj': '12.345.678/0001-90',
          'nomePreferido': 'João Silva',
          'ultimoLogin': '2024-01-15T10:30:00.000Z',
        };

        // Act
        final usuario = Usuario.fromJson(json);

        // Assert
        expect(usuario.cnpj, equals('12.345.678/0001-90'));
        expect(usuario.nomePreferido, equals('João Silva'));
        expect(usuario.ultimoLogin.year, equals(2024));
        expect(usuario.ultimoLogin.month, equals(1));
        expect(usuario.ultimoLogin.day, equals(15));
      });

      test('Deve converter Usuario para JSON', () {
        // Arrange
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'Maria Santos',
          ultimoLogin: DateTime(2024, 1, 15, 10, 30),
        );

        // Act
        final json = usuario.toJson();

        // Assert
        expect(json['cnpj'], equals('12.345.678/0001-90'));
        expect(json['nomePreferido'], equals('Maria Santos'));
        expect(json['ultimoLogin'], isA<String>());
      });

      test('Deve criar Usuario com valores padrão quando campos ausentes', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final usuario = Usuario.fromJson(json);

        // Assert
        expect(usuario.cnpj, equals(''));
        expect(usuario.nomePreferido, equals(''));
        expect(usuario.ultimoLogin, isA<DateTime>());
      });
    });

    group('AuthException Tests', () {
      test('Deve criar AuthException com mensagem', () {
        // Arrange & Act
        const exception = AuthException('Erro de autenticação');

        // Assert
        expect(exception.message, equals('Erro de autenticação'));
        expect(
          exception.toString(),
          equals('AuthException: Erro de autenticação'),
        );
      });
    });

    group('login Tests', () {
      test('Deve fazer login com credenciais válidas', () async {
        // Arrange
        const cnpj = '12.345.678/0001-90';
        const senha = 'password123';

        // Act
        final usuario = await authService.login(cnpj, senha);

        // Assert
        expect(usuario.cnpj, equals(cnpj));
        expect(usuario.nomePreferido, equals(''));
        expect(usuario.ultimoLogin, isA<DateTime>());

        // Verificar se o login foi recente (últimos 5 segundos)
        final agora = DateTime.now();
        final diferenca = agora.difference(usuario.ultimoLogin).inSeconds;
        expect(diferenca, lessThan(5));
      });

      test('Deve falhar com CNPJ vazio', () async {
        // Act & Assert
        expect(
          () => authService.login('', 'password123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('CNPJ é obrigatório'),
            ),
          ),
        );

        expect(
          () => authService.login('   ', 'password123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('CNPJ é obrigatório'),
            ),
          ),
        );
      });

      test('Deve falhar com senha vazia', () async {
        // Act & Assert
        expect(
          () => authService.login('12.345.678/0001-90', ''),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('Senha é obrigatória'),
            ),
          ),
        );

        expect(
          () => authService.login('12.345.678/0001-90', '   '),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('Senha é obrigatória'),
            ),
          ),
        );
      });

      test('Deve falhar com CNPJ incorreto', () async {
        // Act & Assert
        expect(
          () => authService.login('11.111.111/0001-11', 'password123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('CNPJ ou senha incorretos'),
            ),
          ),
        );
      });

      test('Deve falhar com senha incorreta', () async {
        // Act & Assert
        expect(
          () => authService.login('12.345.678/0001-90', 'senhaerrada'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('CNPJ ou senha incorretos'),
            ),
          ),
        );
      });

      test('Deve ter delay simulado no login', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await authService.login('12.345.678/0001-90', 'password123');

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          greaterThan(400),
        ); // Pelo menos 400ms
      });
    });

    group('salvarUsuario Tests', () {
      test('Deve salvar usuário no SharedPreferences', () async {
        // Arrange
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.now(),
        );

        // Act
        await authService.salvarUsuario(usuario);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('usuario_atual'), isNotNull);
        expect(prefs.getBool('usuario_logado'), isTrue);
      });
    });

    group('obterUsuarioAtual Tests', () {
      test('Deve retornar usuário salvo', () async {
        // Arrange
        final usuarioOriginal = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime(2024, 1, 15, 10, 30),
        );
        await authService.salvarUsuario(usuarioOriginal);

        // Act
        final usuario = await authService.obterUsuarioAtual();

        // Assert
        expect(usuario, isNotNull);
        expect(usuario!.cnpj, equals('12.345.678/0001-90'));
        expect(usuario.nomePreferido, equals('João Silva'));
      });

      test('Deve retornar null quando nenhum usuário salvo', () async {
        // Act
        final usuario = await authService.obterUsuarioAtual();

        // Assert
        expect(usuario, isNull);
      });

      test('Deve limpar dados corrompidos e retornar null', () async {
        // Arrange - Salvar JSON inválido
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario_atual', 'json_invalido');

        // Act
        final usuario = await authService.obterUsuarioAtual();

        // Assert
        expect(usuario, isNull);
        expect(prefs.getString('usuario_atual'), isNull);
        expect(prefs.getBool('usuario_logado'), isNull);
      });
    });

    group('estaLogado Tests', () {
      test('Deve retornar true quando usuário está logado', () async {
        // Arrange
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.now(),
        );
        await authService.salvarUsuario(usuario);

        // Act
        final logado = await authService.estaLogado();

        // Assert
        expect(logado, isTrue);
      });

      test('Deve retornar false quando usuário não está logado', () async {
        // Act
        final logado = await authService.estaLogado();

        // Assert
        expect(logado, isFalse);
      });
    });

    group('atualizarNomePreferido Tests', () {
      test('Deve atualizar nome preferido do usuário logado', () async {
        // Arrange
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João',
          ultimoLogin: DateTime.now(),
        );
        await authService.salvarUsuario(usuario);

        // Act
        await authService.atualizarNomePreferido('João Silva Santos');

        // Assert
        final usuarioAtualizado = await authService.obterUsuarioAtual();
        expect(usuarioAtualizado!.nomePreferido, equals('João Silva Santos'));
        expect(
          usuarioAtualizado.cnpj,
          equals('12.345.678/0001-90'),
        ); // CNPJ não mudou
      });

      test('Deve falhar quando nenhum usuário está logado', () async {
        // Act & Assert
        expect(
          () => authService.atualizarNomePreferido('Novo Nome'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals('Nenhum usuário logado'),
            ),
          ),
        );
      });
    });

    group('logout Tests', () {
      test('Deve fazer logout e limpar dados', () async {
        // Arrange
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.now(),
        );
        await authService.salvarUsuario(usuario);

        // Act
        await authService.logout();

        // Assert
        final usuarioAtual = await authService.obterUsuarioAtual();
        final logado = await authService.estaLogado();

        expect(usuarioAtual, isNull);
        expect(logado, isFalse);
      });
    });

    group('limparDados Tests', () {
      test('Deve limpar todos os dados do usuário', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario_atual', 'dados_teste');
        await prefs.setBool('usuario_logado', true);

        // Act
        await authService.limparDados();

        // Assert
        expect(prefs.getString('usuario_atual'), isNull);
        expect(prefs.getBool('usuario_logado'), isNull);
      });
    });

    group('validarFormatoCnpj Tests', () {
      test('Deve validar CNPJ com formato correto', () {
        // Arrange & Act & Assert
        expect(authService.validarFormatoCnpj('12.345.678/0001-90'), isTrue);
        expect(authService.validarFormatoCnpj('00.000.000/0001-91'), isTrue);
        expect(authService.validarFormatoCnpj('99.999.999/9999-99'), isTrue);
      });

      test('Deve rejeitar CNPJ com formato incorreto', () {
        // Arrange & Act & Assert
        expect(authService.validarFormatoCnpj('12345678000190'), isFalse);
        expect(authService.validarFormatoCnpj('12.345.678/0001'), isFalse);
        expect(authService.validarFormatoCnpj('12.345.678/0001-9'), isFalse);
        expect(authService.validarFormatoCnpj('12.345.678/0001-900'), isFalse);
        expect(authService.validarFormatoCnpj('123.45.678/0001-90'), isFalse);
        expect(authService.validarFormatoCnpj('12.345.67/0001-90'), isFalse);
        expect(authService.validarFormatoCnpj(''), isFalse);
        expect(authService.validarFormatoCnpj('abc.def.ghi/jklm-no'), isFalse);
      });
    });

    group('validarSenha Tests', () {
      test('Deve validar senha com 8 ou mais caracteres', () {
        // Arrange & Act & Assert
        expect(authService.validarSenha('password123'), isTrue);
        expect(authService.validarSenha('12345678'), isTrue);
        expect(authService.validarSenha('senha_muito_longa_123456'), isTrue);
        expect(authService.validarSenha('MinhaS3nh@'), isTrue);
      });

      test('Deve rejeitar senha com menos de 8 caracteres', () {
        // Arrange & Act & Assert
        expect(authService.validarSenha('1234567'), isFalse);
        expect(authService.validarSenha('abc'), isFalse);
        expect(authService.validarSenha(''), isFalse);
        expect(authService.validarSenha('a'), isFalse);
      });
    });

    group('obterUltimoLogin Tests', () {
      test('Deve retornar último login do usuário', () async {
        // Arrange
        final dataLogin = DateTime(2024, 1, 15, 10, 30);
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: dataLogin,
        );
        await authService.salvarUsuario(usuario);

        // Act
        final ultimoLogin = await authService.obterUltimoLogin();

        // Assert
        expect(ultimoLogin, isNotNull);
        expect(ultimoLogin!.year, equals(2024));
        expect(ultimoLogin.month, equals(1));
        expect(ultimoLogin.day, equals(15));
        expect(ultimoLogin.hour, equals(10));
        expect(ultimoLogin.minute, equals(30));
      });

      test('Deve retornar null quando nenhum usuário logado', () async {
        // Act
        final ultimoLogin = await authService.obterUltimoLogin();

        // Assert
        expect(ultimoLogin, isNull);
      });
    });

    group('Integration Tests', () {
      test('Deve realizar fluxo completo de login e logout', () async {
        // Arrange
        const cnpj = '12.345.678/0001-90';
        const senha = 'password123';
        const nomePreferido = 'João Silva';

        // Act - Login
        final usuario = await authService.login(cnpj, senha);
        await authService.salvarUsuario(usuario);

        // Assert - Verificar login
        expect(await authService.estaLogado(), isTrue);
        final usuarioSalvo = await authService.obterUsuarioAtual();
        expect(usuarioSalvo!.cnpj, equals(cnpj));

        // Act - Atualizar nome
        await authService.atualizarNomePreferido(nomePreferido);

        // Assert - Verificar atualização
        final usuarioAtualizado = await authService.obterUsuarioAtual();
        expect(usuarioAtualizado!.nomePreferido, equals(nomePreferido));

        // Act - Logout
        await authService.logout();

        // Assert - Verificar logout
        expect(await authService.estaLogado(), isFalse);
        expect(await authService.obterUsuarioAtual(), isNull);
      });

      test('Deve manter estado entre reinicializações do serviço', () async {
        // Arrange - Primeiro serviço
        final authService1 = AuthService();
        final usuario = Usuario(
          cnpj: '12.345.678/0001-90',
          nomePreferido: 'João Silva',
          ultimoLogin: DateTime.now(),
        );
        await authService1.salvarUsuario(usuario);

        // Act - Segundo serviço (simula reinicialização do app)
        final authService2 = AuthService();
        final usuarioRecuperado = await authService2.obterUsuarioAtual();
        final logado = await authService2.estaLogado();

        // Assert
        expect(logado, isTrue);
        expect(usuarioRecuperado, isNotNull);
        expect(usuarioRecuperado!.cnpj, equals('12.345.678/0001-90'));
        expect(usuarioRecuperado.nomePreferido, equals('João Silva'));
      });
    });

    group('Performance Tests', () {
      test('Deve fazer login rapidamente', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await authService.login('12.345.678/0001-90', 'password123');

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
        ); // Menos que 2 segundos
      });

      test('Deve validar formato rapidamente', () {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        for (int i = 0; i < 1000; i++) {
          authService.validarFormatoCnpj('12.345.678/0001-90');
          authService.validarSenha('password123');
        }

        // Assert
        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
        ); // Menos que 100ms para 1000 validações
      });
    });
  });
}
