import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/user_storage_service.dart';
import '../services/auth_service.dart';

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

  late final ApiService _apiService;

  bool _isDropdownVisible = false;
  bool _isVoiceInputActive = false;
  bool _isWaitingResponse = false;

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
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final userName = widget.userName;
    final welcomeMessage = userName != null
        ? 'Olá, $userName! Como posso ajudá-lo hoje?'
        : 'Olá! Como posso ajudá-lo hoje?';

    _messages.add(
      ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isAnimating: false,
      ),
    );
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownVisible = false);
      _scrollToBottom();
    }
  }

  Future<String> _getResponseFromApi(String message) async {
    try {
      final response = await _apiService.enviarPergunta(message);

      if (response.sucesso) {
        return response.resposta;
      } else {
        return response.erro ?? 'Erro desconheido na resposta da API';
      }
    } on ApiException catch (e) {
      debugPrint('Erro na API: ${e.message}');
      return 'Erro: ${e.message}';
    } catch (e) {
      debugPrint('Erro de conexão: $e');
      return 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    }
  }

  void _sendMessage([String? suggestionText]) async {
    final text = suggestionText ?? _messageController.text.trim();
    if (text.isEmpty || _isWaitingResponse) return;

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
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
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
  }

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

  Future<void> _performLogout() async {
    try {
      await UserStorageService.clearUserData();

      final authService = AuthService();
      await authService.logout();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao fazer logout, mas você foi desconectado'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          if (_isDropdownVisible) {
            setState(() => _isDropdownVisible = false);
          }
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(child: _buildMessagesList()),
                        _buildSuggestionsCarousel(),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: 8,
                      left: AppDimensions.paddingMedium,
                      right: AppDimensions.paddingMedium,
                      bottom: AppDimensions.paddingSmall,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.borderRadius),
                        topRight: Radius.circular(AppDimensions.borderRadius),
                      ),
                    ),
                    child: _buildInputArea(),
                  ),
                ],
              ),

              // Menu dropdown sobreposto quando visível
              if (_isDropdownVisible) _buildFloatingDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = widget.userName ?? 'Usuário';

    return Container(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingMedium,
        right: AppDimensions.paddingMedium,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Ícone do tigre (logo)
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              'assets/images/sophos_kodiak_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Erro ao carregar logo: $error');
                return const Icon(
                  Icons.smart_toy,
                  color: AppColors.primaryDark,
                  size: 24,
                );
              },
              cacheWidth: 64, // Cacheamento otimizado
              cacheHeight: 64,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          // Saudação personalizada ou padrão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Olá, ',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: widget.userName != null ? userName : 'Sophos IA',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.userName != null ? 'Sophos IA' : '',
                  style: AppTextStyles.inputHint.copyWith(fontSize: 14),
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
    // Posicionamento relativo ao Stack dentro do Expanded
    return Positioned(
      top: 65, // Posição logo abaixo do header
      right: AppDimensions.paddingMedium,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
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
                onTap: () async {
                  setState(() => _isDropdownVisible = false);

                  // Limpa os dados do usuário antes de sair
                  await _performLogout();
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
              style: AppTextStyles.inputText.copyWith(
                color: textColor ?? AppColors.textPrimary,
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
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }

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
          const borderRadius = BorderRadius.all(Radius.circular(20));

          return Container(
            margin: const EdgeInsets.only(right: AppDimensions.paddingSmall),
            child: Material(
              elevation: 2,
              borderRadius: borderRadius,
              color: AppColors.suggestionCardBackground,
              child: InkWell(
                onTap: () => _sendMessage(
                  '${suggestion['title']} ${suggestion['subtitle']}',
                ),
                borderRadius: borderRadius,
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
                        style: AppTextStyles.description.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        suggestion['subtitle']!,
                        style: AppTextStyles.description.copyWith(
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

  Widget _buildInputArea() {
    final hasText = _messageController.text.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              // Mantém uma borda fixa mesmo quando transparente para evitar o deslocamento
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            // Padding fixo para garantir consistência visual quando o estado muda
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                // Campo de texto expansível
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte qualquer coisa',
                      hintStyle: AppTextStyles.inputHint,
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 6,
                    textAlignVertical: TextAlignVertical
                        .center, // Centraliza o texto verticalmente
                    keyboardType: TextInputType
                        .multiline, // Garante que o teclado permita múltiplas linhas
                    onChanged: (value) => setState(() {}),
                    onTap:
                        _scrollToBottom, // Rola para o final quando o campo é tocado
                    onSubmitted: (_) =>
                        _messageController.text.trim().isNotEmpty
                        ? _sendMessage()
                        : null,
                  ),
                ),
                // Espaço para evitar colisão do texto com os botões
                const SizedBox(width: 4),
                // Ícone de voz
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() => _isVoiceInputActive = !_isVoiceInputActive);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Funcionalidade de voz em desenvolvimento',
                        ),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      _isVoiceInputActive ? Icons.mic : Icons.mic_none,
                      color: _isVoiceInputActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
                // Espaço entre ícones
                const SizedBox(width: 4),
                // Botão de envio dentro de uma esfera
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
                      Icons.arrow_upward_rounded,
                      color: hasText
                          ? AppColors.buttonSendIcon
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
                style: AppTextStyles.inputText.copyWith(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              )
            : Text(
                message.text,
                style: AppTextStyles.inputText.copyWith(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;

  const TypewriterText({
    super.key,
    required this.text,
    this.style = AppTextStyles.description,
    this.speed = const Duration(milliseconds: 30),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late String _displayText;
  Timer? _timer;

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
        if (mounted) {
          // Verifica se o widget ainda está montado
          setState(() => _displayText += widget.text[index++]);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}

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
          style: AppTextStyles.description.copyWith(
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }
}

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
