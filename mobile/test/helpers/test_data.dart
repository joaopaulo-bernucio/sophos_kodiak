import 'package:sophos_kodiak/models/user.dart';
import 'package:sophos_kodiak/models/chat_message.dart';

/// Classe para fornecer dados de teste válidos
class TestData {
  // Dados de usuário válidos
  static const String validCnpj = '12.345.678/0001-90';
  static const String validPassword = 'password123';
  static const String validUserName = 'João Silva';

  // Dados de usuário inválidos
  static const String invalidCnpj = '11.111.111/1111-11';
  static const String invalidPassword = '123';
  static const String shortPassword = '1234567';
  static const String emptyCnpj = '';
  static const String emptyPassword = '';

  // CNPJ sem formatação
  static const String unformattedCnpj = '12345678000190';

  // Dados de chat
  static const String sampleQuestion = 'Qual é o total de vendas do mês?';
  static const String sampleResponse =
      'O total de vendas do mês é R\$ 150.000,00';
  static const String longQuestion =
      'Esta é uma pergunta muito longa que possui mais de 100 caracteres para testar como o sistema se comporta com entradas extensas e verificar se há limitações no processamento de texto.';

  /// Cria um usuário válido para testes
  static User createValidUser({
    String? cnpj,
    String? senha,
    String? nomePreferido,
    DateTime? ultimoLogin,
  }) {
    return User(
      cnpj: cnpj ?? validCnpj,
      senha: senha ?? validPassword,
      nomePreferido: nomePreferido ?? validUserName,
      ultimoLogin: ultimoLogin ?? DateTime.now(),
    );
  }

  /// Cria uma mensagem de chat do usuário para testes
  static ChatMessage createUserMessage({
    String? text,
    DateTime? timestamp,
    bool? isAnimating,
  }) {
    return ChatMessage(
      text: text ?? sampleQuestion,
      isUser: true,
      timestamp: timestamp ?? DateTime.now(),
      isAnimating: isAnimating ?? false,
    );
  }

  /// Cria uma mensagem de chat do sistema para testes
  static ChatMessage createSystemMessage({
    String? text,
    DateTime? timestamp,
    bool? isAnimating,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? sampleResponse,
      isUser: false,
      timestamp: timestamp ?? DateTime.now(),
      isAnimating: isAnimating ?? false,
      isError: isError ?? false,
    );
  }

  /// Cria uma lista de mensagens de chat para testes
  static List<ChatMessage> createChatHistory() {
    final now = DateTime.now();
    return [
      createUserMessage(
        text: 'Olá!',
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      createSystemMessage(
        text: 'Olá! Como posso ajudá-lo hoje?',
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
      createUserMessage(
        text: sampleQuestion,
        timestamp: now.subtract(const Duration(minutes: 3)),
      ),
      createSystemMessage(
        text: sampleResponse,
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  /// Dados para testes de formatação de CNPJ
  static Map<String, String> cnpjFormattingTests = {
    '12345678000190': '12.345.678/0001-90',
    '1234567800019': '12.345.678/0001-9',
    '123456780001': '12.345.678/0001',
    '12345678': '12.345.678',
    '12345': '12.345',
    '12': '12',
    '': '',
  };

  /// Lista de CNPJs inválidos para testes
  static List<String> invalidCnpjs = [
    '11.111.111/1111-11',
    '22.222.222/2222-22',
    '12.345.678/0001',
    '12.345.678/0001-9',
    'invalid-cnpj',
    '12345678000',
    '',
  ];

  /// Lista de senhas inválidas para testes
  static List<String> invalidPasswords = ['', '123', '1234567', '       '];
}
