import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/api_service.dart';
import '../services/user_storage_service.dart';
import '../services/auth_service.dart';
import '../services/chat_history_service.dart';
import '../models/chat_message.dart';
import 'chat_history_page.dart';

class ChatbotPage extends StatefulWidget {
  final String? userName;

  const ChatbotPage({super.key, this.userName});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late final ApiService _apiService;

  bool _isDropdownVisible = false;
  bool _isWaitingResponse = false;
  String? _currentUserName;

  final List<Map<String, String>> _suggestions = [
    {'title': 'Quantos funcionários', 'subtitle': 'a empresa possui?'},
    {'title': 'Liste todos os clientes', 'subtitle': 'com e-mails e telefones'},
    {'title': 'Qual é o valor total', 'subtitle': 'de vendas realizadas?'},
    {'title': 'Quantos projetos estão', 'subtitle': 'em andamento?'},
    {'title': 'Contratos de marketing', 'subtitle': 'ativos na empresa'},
    {
      'title': 'Média salarial dos',
      'subtitle': 'funcionários por departamento',
    },
    {'title': 'Vendas realizadas no', 'subtitle': 'último mês'},
    {'title': 'Receita de contratos', 'subtitle': 'por cliente'},
    {'title': 'Status dos projetos', 'subtitle': 'na empresa'},
    {'title': 'Funcionários por', 'subtitle': 'departamento'},
  ];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _currentUserName = widget.userName;
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUserName();
    _loadCurrentSessionMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    _apiService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadCurrentUserName();
    }
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final user = await UserStorageService.getUser();
      final newUserName = user?.nomePreferido ?? widget.userName;
      if (newUserName != _currentUserName) {
        setState(() {
          _currentUserName = newUserName;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar nome do usuário: $e');
    }
  }

  /// Carrega mensagens da sessão atual (do dia) ou adiciona mensagem de boas-vindas.
  Future<void> _loadCurrentSessionMessages() async {
    // Primeiro adiciona mensagem de boas-vindas
    _addWelcomeMessage();

    // Depois tenta carregar mensagens do histórico
    try {
      final List<ChatMessage> currentMessages =
          await ChatHistoryService.getCurrentSessionMessages();

      if (currentMessages.isNotEmpty) {
        // Remove mensagem de boas-vindas se houver mensagens anteriores
        setState(() {
          _messages.clear();
          _messages.addAll(currentMessages);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar mensagens da sessão atual: $e');
      // Mantém apenas a mensagem de boas-vindas se houver erro
    }
  }

  void _addWelcomeMessage() {
    final userName = _currentUserName;
    final welcomeMessage = userName != null
        ? 'Olá, $userName! Como posso ajudá-lo hoje?'
        : 'Olá! Como posso ajudá-lo hoje?';

    final welcomeMsg = ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
      isAnimating: false,
    );

    _messages.add(welcomeMsg);

    // Salva mensagem de boas-vindas no histórico
    _saveMessageToHistory(welcomeMsg);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownVisible = false);
      _scrollToBottom();
    }
  }

  Future<String> _getResponseFromApi(String message) async {
    final response = await _apiService.enviarPergunta(message);

    if (response.sucesso) {
      return response.resposta;
    } else {
      throw ApiException.serverError(
        response.erro ?? 'Erro desconhecido na resposta da API',
        500,
      );
    }
  }

  void _sendMessage([String? suggestionText]) async {
    final text = suggestionText ?? _messageController.text.trim();
    if (text.isEmpty || _isWaitingResponse) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      isAnimating: false,
    );

    setState(() {
      _messages.add(userMessage);
      _isWaitingResponse = true;
      _messageController.clear();
    });

    // Salva a mensagem do usuário no histórico
    _saveMessageToHistory(userMessage);

    _scrollToBottom();

    try {
      final response = await _getResponseFromApi(text);
      if (mounted) {
        final botMessage = ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          isAnimating: true,
        );

        setState(() {
          _messages.add(botMessage);
          _isWaitingResponse = false;
        });

        // Salva a resposta do bot no histórico
        _saveMessageToHistory(botMessage);
        _scrollToBottom();
      }
    } on ApiException catch (apiError) {
      if (mounted) {
        final errorMessage = ChatMessage(
          text: '', // Texto vazio pois será renderizado como widget de erro
          isUser: false,
          timestamp: DateTime.now(),
          isAnimating: false,
          isError: true,
          apiError: apiError,
        );

        setState(() {
          _messages.add(errorMessage);
          _isWaitingResponse = false;
        });

        // Nota: Mensagens de erro não são salvas no histórico para manter simplicidade
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = ChatMessage(
          text: '', // Texto vazio pois será renderizado como widget de erro
          isUser: false,
          timestamp: DateTime.now(),
          isAnimating: false,
          isError: true,
          apiError: ApiException.unknown(e.toString()),
        );

        setState(() {
          _messages.add(errorMessage);
          _isWaitingResponse = false;
        });

        // Nota: Mensagens de erro não são salvas no histórico para manter simplicidade
        _scrollToBottom();
      }
    }
  }

  /// Salva uma mensagem no histórico local.
  Future<void> _saveMessageToHistory(ChatMessage message) async {
    try {
      await ChatHistoryService.saveMessage(message);
    } catch (e) {
      debugPrint('Erro ao salvar mensagem no histórico: $e');
      // Não interfere na experiência do usuário se houver erro no salvamento
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
      backgroundColor: AppColors.background,
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
                      color: AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.borderRadius),
                        topRight: Radius.circular(AppDimensions.borderRadius),
                      ),
                    ),
                    child: _buildInputArea(),
                  ),
                ],
              ),
              if (_isDropdownVisible) _buildFloatingDropdownMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = _currentUserName ?? 'Usuário';

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
              cacheWidth: 64,
              cacheHeight: 64,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: 'Olá, ', style: AppTextStyles.primaryText),
                      TextSpan(
                        text: _currentUserName != null ? userName : 'Sophos IA',
                        style: AppTextStyles.primaryText.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currentUserName != null ? 'Sophos IA' : '',
                  style: AppTextStyles.inputPlaceholder.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _isDropdownVisible = !_isDropdownVisible),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.elementsBackground,
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

  Widget _buildFloatingDropdownMenu() {
    return Positioned(
      top: 53,
      right: AppDimensions.paddingMedium,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        color: AppColors.elementsBackground,
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
                      'userName': _currentUserName ?? 'Usuário',
                    },
                  ).then((_) {
                    // Recarrega o nome do usuário quando volta da página de configurações
                    _loadCurrentUserName();
                  });
                },
              ),
              _buildDropdownItem(
                icon: Icons.history,
                text: 'Histórico',
                onTap: () {
                  setState(() => _isDropdownVisible = false);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatHistoryPage(),
                    ),
                  );
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
              const Divider(color: Color(0xFF8A8A8A), height: 1),
              _buildDropdownItem(
                icon: Icons.logout,
                text: 'Sair',
                textColor: AppColors.error,
                onTap: () async {
                  setState(() => _isDropdownVisible = false);
                  await _performLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              style: AppTextStyles.primaryText.copyWith(
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          SizedBox(
            width: 35,
            height: 35,
            child: Image.asset(
              'assets/images/sophos_kodiak_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: AppColors.elementsBackground,
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

          return Container(
            margin: const EdgeInsets.only(right: AppDimensions.paddingSmall),
            child: Material(
              elevation: 2,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppDimensions.borderRadius),
              ),
              color: AppColors.elementsBackground,
              child: InkWell(
                onTap: () => _sendMessage(
                  '${suggestion['title']} ${suggestion['subtitle']}',
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppDimensions.borderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingMedium,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion['title']!,
                        style: AppTextStyles.largeText.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        suggestion['subtitle']!,
                        style: AppTextStyles.largeText.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
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
              color: AppColors.elementsBackground,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: AppTextStyles.primaryText,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte qualquer coisa',
                      hintStyle: AppTextStyles.inputPlaceholder,
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.multiline,
                    onChanged: (value) => setState(() {}),
                    onTap: _scrollToBottom,
                    onSubmitted: (_) =>
                        _messageController.text.trim().isNotEmpty
                        ? _sendMessage()
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.sendButtonBackground
                        : AppColors.elementsBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: hasText ? _sendMessage : null,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: hasText
                            ? AppColors.sendButtonIcon
                            : AppColors.textSecondary,
                        size: 28,
                      ),
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
    // Se for uma mensagem de erro, renderiza o widget de erro customizado
    if (message.isError && message.apiError != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _buildErrorMessage(context, message.apiError!),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : AppColors.elementsBackground,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: message.isAnimating
            ? TypewriterText(
                text: message.text,
                style: AppTextStyles.primaryText.copyWith(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              )
            : Text(
                message.text,
                style: AppTextStyles.primaryText.copyWith(
                  color: message.isUser
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
      ),
    );
  }

  /// Cria uma mensagem de erro amigável baseada no tipo de erro da API
  Widget _buildErrorMessage(BuildContext context, ApiException error) {
    IconData icon;
    Color iconColor;
    String title;

    switch (error.type) {
      case ApiErrorType.connectionError:
        icon = Icons.wifi_off;
        iconColor = AppColors.warning;
        title = 'Problema de Conexão';
        break;
      case ApiErrorType.timeout:
        icon = Icons.access_time;
        iconColor = AppColors.warning;
        title = 'Timeout';
        break;
      case ApiErrorType.serverError:
        icon = Icons.error_outline;
        iconColor = AppColors.error;
        title = 'Erro do Servidor';
        break;
      case ApiErrorType.invalidData:
        icon = Icons.warning_amber;
        iconColor = AppColors.warning;
        title = 'Dados Inválidos';
        break;
      default:
        icon = Icons.help_outline;
        iconColor = AppColors.error;
        title = 'Erro Inesperado';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.elementsBackground,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.primaryText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error.userFriendlyMessage,
            style: AppTextStyles.primaryText.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
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
    this.style = AppTextStyles.largeText,
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
          style: AppTextStyles.primaryText.copyWith(
            color: AppColors.textSecondary,
          ),
        );
      },
    );
  }
}
