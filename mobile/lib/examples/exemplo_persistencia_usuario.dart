/// EXEMPLO DE USO - Sistema de Persistência de Usuário
///
/// Este arquivo demonstra como usar o modelo User e o UserStorageService
/// para persistir dados do usuário no aplicativo Sophos Kodiak.
///
/// ⚠️ Este arquivo é apenas para fins educativos e de documentação.
/// Não deve ser incluído no build final do aplicativo.

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_storage_service.dart';

/// Exemplo prático de como usar o sistema de persistência
class ExemploPersistenciaUsuario {
  /// EXEMPLO 1: Salvando um usuário após login bem-sucedido
  static Future<void> exemploSalvarUsuario() async {
    // Criar um objeto User
    final usuario = User(
      cnpj: '12.345.678/0001-90',
      senha: 'minhasenha123',
      nomePreferido: 'João',
      ultimoLogin: DateTime.now(),
    );

    // Salvar com "lembrar-me" ativado
    final sucesso = await UserStorageService.saveUser(
      usuario,
      rememberMe: true,
    );

    if (sucesso) {
      print('✅ Usuário salvo com sucesso!');
    } else {
      print('❌ Erro ao salvar usuário');
    }
  }

  /// EXEMPLO 2: Recuperando dados do usuário ao iniciar o app
  static Future<void> exemploRecuperarUsuario() async {
    final usuario = await UserStorageService.getUser();

    if (usuario != null) {
      print('✅ Usuário encontrado:');
      print('   CNPJ: ${usuario.cnpj}');
      print('   Nome: ${usuario.nomePreferido ?? "Não informado"}');
      print('   Último login: ${usuario.ultimoLogin}');

      // Preencher campos automaticamente
      // _cnpjController.text = usuario.cnpj;
      // _passwordController.text = usuario.senha;
    } else {
      print('ℹ️ Nenhum usuário salvo encontrado');
    }
  }

  /// EXEMPLO 3: Verificando se há dados salvos
  static Future<void> exemploVerificarDados() async {
    final temDados = await UserStorageService.hasUserData();

    if (temDados) {
      print('✅ Há dados de usuário salvos');
      // Mostrar opção de login automático
    } else {
      print('ℹ️ Nenhum dado salvo encontrado');
      // Mostrar tela de login normal
    }
  }

  /// EXEMPLO 4: Atualizando apenas o último login
  static Future<void> exemploAtualizarLogin() async {
    final sucesso = await UserStorageService.updateLastLogin();

    if (sucesso) {
      print('✅ Último login atualizado');
    } else {
      print('❌ Erro ao atualizar último login');
    }
  }

  /// EXEMPLO 5: Atualizando nome preferido
  static Future<void> exemploAtualizarNome() async {
    final sucesso = await UserStorageService.updatePreferredName('João Paulo');

    if (sucesso) {
      print('✅ Nome preferido atualizado');
    } else {
      print('❌ Erro ao atualizar nome');
    }
  }

  /// EXEMPLO 6: Fazendo logout (removendo dados)
  static Future<void> exemploLogout() async {
    final sucesso = await UserStorageService.clearUserData();

    if (sucesso) {
      print('✅ Logout realizado - dados removidos');
    } else {
      print('❌ Erro ao fazer logout');
    }
  }

  /// EXEMPLO 7: Usando o objeto User com copyWith
  static void exemploCopyWith() {
    // Usuário original
    final usuarioOriginal = User(
      cnpj: '12.345.678/0001-90',
      senha: 'senha123',
      nomePreferido: 'João',
    );

    // Criando uma cópia com apenas o nome alterado
    final usuarioAtualizado = usuarioOriginal.copyWith(
      nomePreferido: 'João Paulo',
      ultimoLogin: DateTime.now(),
    );

    print('Original: ${usuarioOriginal.nomePreferido}');
    print('Atualizado: ${usuarioAtualizado.nomePreferido}');
    // CNPJ e senha permanecem iguais
  }

  /// EXEMPLO 8: Convertendo User para/de JSON
  static void exemploJson() {
    // Criar usuário
    final usuario = User(
      cnpj: '12.345.678/0001-90',
      senha: 'senha123',
      nomePreferido: 'João',
      ultimoLogin: DateTime.now(),
    );

    // Converter para JSON (Map)
    final json = usuario.toJson();
    print('JSON: $json');

    // Converter de volta para User
    final usuarioRecuperado = User.fromJson(json);
    print('Usuário recuperado: $usuarioRecuperado');
  }
}

/// Widget de exemplo que demonstra o uso na prática
class ExemploWidget extends StatefulWidget {
  const ExemploWidget({super.key});

  @override
  State<ExemploWidget> createState() => _ExemploWidgetState();
}

class _ExemploWidgetState extends State<ExemploWidget> {
  User? _usuarioAtual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioSalvo();
  }

  /// Carrega usuário salvo ao iniciar o widget
  Future<void> _carregarUsuarioSalvo() async {
    setState(() => _isLoading = true);

    final usuario = await UserStorageService.getUser();

    setState(() {
      _usuarioAtual = usuario;
      _isLoading = false;
    });
  }

  /// Simula um login e salva o usuário
  Future<void> _fazerLogin() async {
    final novoUsuario = User(
      cnpj: '12.345.678/0001-90',
      senha: 'senha123',
      nomePreferido: 'João Paulo',
      ultimoLogin: DateTime.now(),
    );

    final sucesso = await UserStorageService.saveUser(
      novoUsuario,
      rememberMe: true,
    );

    if (sucesso) {
      setState(() => _usuarioAtual = novoUsuario);

      // Mostrar feedback para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado e dados salvos!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Faz logout removendo dados salvos
  Future<void> _fazerLogout() async {
    final sucesso = await UserStorageService.clearUserData();

    if (sucesso) {
      setState(() => _usuarioAtual = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout realizado!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplo Persistência')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_usuarioAtual != null) ...[
              const Text(
                'Usuário Logado:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('CNPJ: ${_usuarioAtual!.cnpj}'),
              Text('Nome: ${_usuarioAtual!.nomePreferido ?? "Não informado"}'),
              Text('Último login: ${_usuarioAtual!.ultimoLogin ?? "Nunca"}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fazerLogout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Fazer Logout'),
              ),
            ] else ...[
              const Text(
                'Nenhum usuário logado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fazerLogin,
                child: const Text('Fazer Login (Simulado)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// RESUMO DO SISTEMA:
///
/// 1. MODEL (User):
///    - Representa a estrutura dos dados do usuário
///    - Métodos para conversão JSON (toJson/fromJson)
///    - Método copyWith para atualizações
///    - Implementa toString, == e hashCode
///
/// 2. SERVICE (UserStorageService):
///    - Gerencia a persistência usando SharedPreferences
///    - Métodos para salvar, recuperar e remover dados
///    - Suporte a "lembrar-me"
///    - Métodos para atualizar campos específicos
///
/// 3. INTEGRAÇÃO NA UI:
///    - LoginPage modificada para usar o serviço
///    - Checkbox "Lembrar-me" adicionado
///    - Carregamento automático de dados salvos
///    - Feedback visual para o usuário
///
/// BENEFÍCIOS:
/// ✅ Usuário não precisa digitar CNPJ/senha toda vez
/// ✅ Experiência mais fluida
/// ✅ Dados persistem entre sessões do app
/// ✅ Fácil de manter e estender
/// ✅ Código bem documentado e testável
