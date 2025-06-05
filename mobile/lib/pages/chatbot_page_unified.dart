import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../constants/app_constants.dart';

/// Página do Chatbot com IA integrada ao Google Gemini
///
/// Esta página oferece uma interface de chat para interação com o
/// assistente inteligente do sistema Kodiak ERP, seguindo o design
/// do Figma com sugestões, animações e integração real com a API.
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // Sugestões de perguntas
  final List<Map<String, String>> _suggestions = [
    {
      'title': 'Preveja quais clientes estão',
      'subtitle': 'mais propensos a cancelar o serviço',
    },
    {'title': 'Quais produtos têm a', 'subtitle': 'maior margem de lucro?'},
    {
      'title': 'Qual é a previsão de vendas',
      'subtitle': 'para os próximos três meses?',
    },
  ];

  bool _isDropdownVisible = false;
  bool _isVoiceInputActive = false;
  bool _isWaitingResponse = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Adiciona mensagem de boas-vindas inicial
  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?',
        isUser: false,
        timestamp: DateTime.now(),
        isAnimating: false,
      ),
    );
  }

  /// Controla a visibilidade do dropdown quando o campo ganha foco
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownVisible = false);
    }
  }

  /// Faz requisição para a API Flask
  Future<String> _getResponseFromApi(String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/pergunta'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pergunta': message}),
      );

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedResponse);
        return _formatResponse(data['resposta'] as String);
      }
      return 'Erro na comunicação com o servidor. Tente novamente.';
    } catch (e) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    }
  }

  /// Formata a resposta da API para melhor legibilidade
  String _formatResponse(String response) {
    return response
        .replaceAllMapped(RegExp(r'(.{60,}\s)'), (m) => '${m.group(0)}\n')
        .trim();
  }

  /// Envia uma nova mensagem
  void _sendMessage([String? suggestionText]) async {
    final text = suggestionText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
          isAnimating: false,
        ),
      );
      _isWaitingResponse = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await _getResponseFromApi(text);
      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            isAnimating: true,
          ),
        );
        _isWaitingResponse = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Desculpe, ocorreu um erro. Tente novamente.',
            isUser: false,
            timestamp: DateTime.now(),
            isAnimating: false,
          ),
        );
        _isWaitingResponse = false;
      });
      _scrollToBottom();
    }
  }

  /// Rola para o final da conversa
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () => setState(() => _isDropdownVisible = false),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: AppDimensions.paddingSmall,
                  ),
                  itemCount: _messages.length + (_isWaitingResponse ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length && _isWaitingResponse) {
                      return _buildTypingIndicator();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
              _buildSuggestionsCarousel(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o header da página
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          const Text(
            'Sophos IA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                setState(() => _isDropdownVisible = !_isDropdownVisible),
            child: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o indicador de "digitando"
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingMedium,
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusLarge,
              ),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }

  /// Constrói o carrossel de sugestões
  Widget _buildSuggestionsCarousel() {
    if (_messages.length > 1) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
        ),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: AppDimensions.paddingSmall),
            child: Card(
              color: AppColors.surfaceLight,
              child: InkWell(
                onTap: () => _sendMessage(
                  '${suggestion['title']} ${suggestion['subtitle']}',
                ),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusLarge,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        suggestion['title']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        suggestion['subtitle']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói a área de entrada de mensagem
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // TODO: Implementar anexo de arquivos
            },
            icon: const Icon(
              Icons.attach_file,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Mensagem',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMedium,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isVoiceInputActive ? Icons.mic : Icons.mic_none,
                      color: _isVoiceInputActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(
                        () => _isVoiceInputActive = !_isVoiceInputActive,
                      );
                      // TODO: Implementar entrada de voz
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para uma bolha de mensagem individual
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: message.isAnimating
            ? TypewriterText(
                text: message.text,
                style: TextStyle(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  fontSize: 16,
                ),
              )
            : Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

/// Widget para animação de texto máquina de escrever
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    this.style = const TextStyle(color: AppColors.textPrimary),
    this.speed = const Duration(milliseconds: 30),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late String _displayText;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _displayText = '';
    _startTyping();
  }

  void _startTyping() {
    int index = 0;
    _timer = Timer.periodic(widget.speed, (timer) {
      if (index < widget.text.length) {
        setState(() => _displayText += widget.text[index++]);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}

/// Widget para indicação de "digitando"
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text(
          'Digitando${''.padRight((3 * _controller.value).ceil(), '.')}',
          style: const TextStyle(color: AppColors.textSecondary),
        );
      },
    );
  }
}

/// Modelo de dados para mensagens do chat
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnimating;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isAnimating,
  });
}
