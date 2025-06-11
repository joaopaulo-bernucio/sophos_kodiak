import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/api_service.dart';

class ChatbotPage extends StatefulWidget {
  final String? userName;

  const ChatbotPage({super.key, this.userName});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // Instância do serviço de API
  late final ApiService _apiService;

  // Estado da UI
  bool _isDropdownVisible = false;
  bool _isVoiceInputActive = false;
  bool _isWaitingResponse = false;

  // Sugestões de perguntas predefinidas
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
    {
      'title': 'Identifique oportunidades',
      'subtitle': 'de cross-selling e upselling',
    },
    {'title': 'Analise o desempenho', 'subtitle': 'da equipe de vendas'},
    {'title': 'Mostre as tendências', 'subtitle': 'do mercado atual'},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _addWelcomeMessage();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  /// Adiciona mensagem de boas-vindas personalizada
  void _addWelcomeMessage() {
    final userName = widget.userName;
    final welcomeMessage = userName != null
        ? 'Olá, $userName! Como posso ajudá-lo hoje?'
        : 'Olá! Sou o Sophos, assistente inteligente do Kodiak ERP. Como posso ajudá-lo hoje?';

    _messages.add(
      ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isAnimating: false,
      ),
    );
  }

  /// Controla a visibilidade do dropdown quando o campo ganha/perde foco
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownVisible = false);
    }
  }

  /// Faz requisição para a API usando o ApiService
  Future<String> _getResponseFromApi(String message) async {
    try {
      final response = await _apiService.enviarPergunta(message);
      return _formatResponse(response.resposta);
    } on ApiException catch (e) {
      return 'Erro: ${e.message}';
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
          child: Stack(
            children: [
              // Interface principal
              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMessagesList()),
                  _buildSuggestionsCarousel(),
                  _buildInputArea(),
                ],
              ),
              // Menu dropdown flutuante
              if (_isDropdownVisible) _buildFloatingDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho da página com menu dropdown
  Widget _buildHeader() {
    final userName = widget.userName ?? 'Conttrotech';

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
          // Seta de volta
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFE6E6E6),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Ícone do tigre (logo)
          Container(
            width: 40,
            height: 40,
            child: Image.asset(
              'assets/images/sophos_kodiak_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.smart_toy,
                  color: AppColors.primaryDark,
                  size: 24,
                );
              },
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Saudação personalizada ou padrão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName != null ? 'Olá, $userName' : 'Sophos IA',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.userName != null ? 'Sophos IA' : '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Ícone do usuário com dropdown
          GestureDetector(
            onTap: () =>
                setState(() => _isDropdownVisible = !_isDropdownVisible),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o menu dropdown flutuante do usuário
  Widget _buildFloatingDropdownMenu() {
    return Positioned(
      top: 65, // Posição logo abaixo do header
      right: AppDimensions.paddingMedium,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        color: AppColors.surfaceLight,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdownItem(
                icon: Icons.person,
                text: 'Conta',
                onTap: () {
                  setState(() => _isDropdownVisible = false);
                  Navigator.pushNamed(
                    context,
                    '/settings',
                    arguments: {
                      'cnpj': '12.345.678/0001-90',
                      'password': 'password123',
                      'userName': widget.userName ?? 'Usuário',
                    },
                  );
                },
              ),
              _buildDropdownItem(
                icon: Icons.history,
                text: 'Histórico',
                onTap: () {
                  setState(() => _isDropdownVisible = false);
                  // TODO: Implementar histórico
                },
              ),
              _buildDropdownItem(
                icon: Icons.notifications,
                text: 'Notificações',
                onTap: () {
                  setState(() => _isDropdownVisible = false);
                  // TODO: Implementar notificações
                },
              ),
              const Divider(color: AppColors.surface, height: 1),
              _buildDropdownItem(
                icon: Icons.logout,
                text: 'Sair',
                textColor: AppColors.error,
                onTap: () {
                  setState(() => _isDropdownVisible = false);
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item individual do menu dropdown
  Widget _buildDropdownItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de mensagens do chat
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
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
      height: 50,
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
            margin: const EdgeInsets.only(right: AppDimensions.paddingSmall),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(20),
              color: AppColors.suggestionCardBackground,
              child: InkWell(
                onTap: () => _sendMessage(
                  '${suggestion['title']} ${suggestion['subtitle']}',
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion['title']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        suggestion['subtitle']!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
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

  /// Área de entrada de mensagem
  Widget _buildInputArea() {
    final hasText = _messageController.text.trim().isNotEmpty;

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
          // Botão de anexar arquivo em círculo
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.buttonAttachBackground,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implementar anexo de arquivos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade de anexo em desenvolvimento'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              icon: const Icon(
                Icons.attach_file,
                color: AppColors.buttonAttachIcon,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Campo de texto expandido
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
                          vertical: 12,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (value) =>
                          setState(() {}), // Atualiza o estado para o botão
                      onSubmitted: (_) => hasText ? _sendMessage() : null,
                    ),
                  ),
                  // Botão de voz
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidade de voz em desenvolvimento',
                          ),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Botão de enviar com estado dinâmico
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasText
                  ? AppColors.buttonSendBackground
                  : AppColors.buttonSendDisabled,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: hasText ? _sendMessage : null,
              icon: Icon(
                Icons.arrow_upward,
                color: hasText
                    ? AppColors.buttonSendIcon
                    : AppColors.textSecondary,
                size: 20,
              ),
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
    this.isAnimating = false,
  });
}
