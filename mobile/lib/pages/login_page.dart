import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../services/user_storage_service.dart';

/// Tela de login do aplicativo Sophos Kodiak
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers para os campos de entrada
  final _cnpjController = TextEditingController();
  final _passwordController = TextEditingController();

  // Estado para visibilidade da senha
  bool _isPasswordVisible = false;

  // Estado para "Lembrar-me"
  bool _rememberMe = false;

  /// Formata o CNPJ enquanto o usuário digita
  String _formatCnpj(String value) {
    // Remove todos os caracteres não numéricos
    value = value.replaceAll(RegExp(r'\D'), '');

    // Limita a 14 dígitos
    if (value.length > 14) value = value.substring(0, 14);

    // Aplica a formatação progressiva
    if (value.length > 12) {
      return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/${value.substring(8, 12)}-${value.substring(12)}';
    } else if (value.length > 8) {
      return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/${value.substring(8)}';
    } else if (value.length > 5) {
      return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5)}';
    } else if (value.length > 2) {
      return '${value.substring(0, 2)}.${value.substring(2)}';
    }

    return value;
  }

  /// Valida se o CNPJ está no formato correto
  bool _isValidCnpj(String cnpj) {
    final regex = RegExp(r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$');
    return regex.hasMatch(cnpj);
  }

  /// Valida se a senha atende aos critérios mínimos
  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Carrega dados salvos do usuário quando a tela é iniciada
  Future<void> _loadSavedUserData() async {
    final savedUser = await UserStorageService.getUser();

    if (savedUser != null) {
      setState(() {
        _cnpjController.text = savedUser.cnpj;
        _passwordController.text = savedUser.senha;
        _rememberMe = true;
      });
    }
  }

  /// Gerencia o processo de login
  Future<void> _handleLogin() async {
    final cnpj = _cnpjController.text;
    final password = _passwordController.text;

    // Valida os campos
    if (!_isValidCnpj(cnpj)) {
      _showErrorDialog('CNPJ inválido');
      return;
    }

    if (!_isValidPassword(password)) {
      _showErrorDialog('Senha deve ter no mínimo 8 caracteres');
      return;
    }

    // Credenciais temporárias para desenvolvimento
    if (cnpj == '12.345.678/0001-90' && password == 'password123') {
      // Cria o objeto User
      final user = User(
        cnpj: cnpj,
        senha: password,
        ultimoLogin: DateTime.now(),
      );

      // Salva os dados se o usuário escolheu "lembrar-me"
      if (_rememberMe) {
        await UserStorageService.saveUser(user, rememberMe: true);
      }

      _askPreferredName(user);
    } else {
      _showErrorDialog('CNPJ ou senha incorretos');
    }
  }

  /// Exibe diálogo para nome preferido
  void _askPreferredName(User user) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _PreferredNameDialog(
        nameController: nameController,
        onConfirm: () async {
          Navigator.of(context).pop();

          // Atualiza o nome preferido do usuário
          final userName = nameController.text.trim();
          if (userName.isNotEmpty && _rememberMe) {
            await UserStorageService.updatePreferredName(userName);
          }

          _goToMainScreen(userName);
        },
      ),
    );
  }

  /// Navega para a tela principal
  void _goToMainScreen(String userName) {
    // Navega para a tela principal usando rota nomeada e passando o nome do usuário
    Navigator.of(context).pushReplacementNamed('/home', arguments: userName);
  }

  /// Exibe diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => _ErrorDialog(message: message),
    );
  }

  @override
  void initState() {
    super.initState();
    // Carrega dados salvos quando a tela é criada
    _loadSavedUserData();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Container de fundo com border radius
            _BackgroundContainer(screenHeight: screenHeight),

            // Conteúdo principal com scroll
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLarge,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Header com logo e título
                    const _HeaderSection(),

                    const SizedBox(height: 30),

                    // Campos de entrada
                    _InputSection(
                      cnpjController: _cnpjController,
                      passwordController: _passwordController,
                      isPasswordVisible: _isPasswordVisible,
                      rememberMe: _rememberMe,
                      onCnpjChanged: _onCnpjChanged,
                      onPasswordVisibilityToggle: _togglePasswordVisibility,
                      onRememberMeChanged: _toggleRememberMe,
                    ),

                    const SizedBox(height: 10),

                    // Botão de login e link de recuperação
                    _ActionSection(onLogin: _handleLogin),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gerencia a formatação do CNPJ ao digitar
  void _onCnpjChanged(String value) {
    final formatted = _formatCnpj(value);
    if (formatted != value) {
      _cnpjController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  /// Alterna a visibilidade da senha
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  /// Alterna o estado do checkbox "Lembrar-me"
  void _toggleRememberMe(bool? value) {
    setState(() {
      _rememberMe = value ?? false;
    });
  }

  @override
  void dispose() {
    _cnpjController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// MARK: - Widgets Auxiliares

/// Container de fundo com formato arredondado
class _BackgroundContainer extends StatelessWidget {
  const _BackgroundContainer({required this.screenHeight});

  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return SizedBox(
      height: screenHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: screenHeight / 1.7 + mediaQuery.padding.bottom,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.borderRadiusExtraLarge),
              topRight: Radius.circular(AppDimensions.borderRadiusExtraLarge),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seção do cabeçalho com logo e títulos
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('SOPHOS KODIAK', style: AppTextStyles.title),
        Image.asset(
          'assets/images/sophos_kodiak_logo.png',
          height: AppDimensions.logoHeight,
        ),
        const SizedBox(height: 20),
        const Text('Bem-vindo de volta!', style: AppTextStyles.subtitle),
        const SizedBox(height: 10),
        const Text('Acesse sua conta', style: AppTextStyles.description),
      ],
    );
  }
}

/// Seção com os campos de entrada (CNPJ e Senha)
class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.cnpjController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.rememberMe,
    required this.onCnpjChanged,
    required this.onPasswordVisibilityToggle,
    required this.onRememberMeChanged,
  });

  final TextEditingController cnpjController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool rememberMe;
  final ValueChanged<String> onCnpjChanged;
  final VoidCallback onPasswordVisibilityToggle;
  final ValueChanged<bool?> onRememberMeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo CNPJ
        _CustomTextField(
          label: 'CNPJ',
          controller: cnpjController,
          hintText: 'Digite o seu CNPJ',
          keyboardType: TextInputType.number,
          onChanged: onCnpjChanged,
        ),

        const SizedBox(height: 30),

        // Campo Senha
        _CustomTextField(
          label: 'Senha',
          controller: passwordController,
          hintText: 'Digite a sua senha',
          obscureText: !isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
            ),
            onPressed: onPasswordVisibilityToggle,
          ),
        ),

        const SizedBox(height: 10),

        // Checkbox "Lembrar-me"
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: onRememberMeChanged,
              activeColor: AppColors.primary,
            ),
            const Text(
              'Continuar conectado',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

/// Campo de texto customizado
class _CustomTextField extends StatelessWidget {
  const _CustomTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Text(label, style: AppTextStyles.label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: controller,
            style: AppTextStyles.inputText,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.inputHint,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: 12,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// Seção com botão de login e "Esqueci minha senha"
class _ActionSection extends StatelessWidget {
  const _ActionSection({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão de login
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                ),
              ),
              child: const Text('ENTRAR', style: AppTextStyles.button),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Link "Esqueci minha senha"
        TextButton(
          onPressed: () {
            // TODO: Implementar navegação para recuperação de senha
          },
          child: const Text('Esqueci minha senha', style: AppTextStyles.link),
        ),
      ],
    );
  }
}

/// Diálogo para inserir nome preferido
class _PreferredNameDialog extends StatelessWidget {
  const _PreferredNameDialog({
    required this.nameController,
    required this.onConfirm,
  });

  final TextEditingController nameController;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      title: const Text(
        'Nome Preferido',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: nameController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Digite seu nome preferido',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onConfirm,
          child: const Text('OK', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}

/// Diálogo de erro
class _ErrorDialog extends StatelessWidget {
  const _ErrorDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      title: const Text('Erro', style: TextStyle(color: AppColors.textPrimary)),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
