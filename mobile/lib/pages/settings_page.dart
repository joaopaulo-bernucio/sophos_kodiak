import 'package:flutter/material.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import 'package:sophos_kodiak/services/auth_service.dart';

/// Tela de configurações do usuário
///
/// Esta tela permite ao usuário visualizar e editar suas informações pessoais,
/// configurações do aplicativo e fazer logout.
class SettingsPage extends StatefulWidget {
  /// CNPJ do usuário (não editável)
  final String cnpj;

  /// Senha do usuário (pode ser visualizada/ocultada)
  final String password;

  /// Nome do usuário (editável)
  final String userName;

  const SettingsPage({
    required this.cnpj,
    required this.password,
    required this.userName,
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Controla se a senha está visível ou oculta
  bool _isPasswordVisible = false;

  /// Nome atual do usuário (pode ser alterado)
  late String _currentUserName;

  /// Instância do serviço de autenticação
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Inicializa o nome do usuário com o valor recebido
    _currentUserName = widget.userName;
  }

  /// Alterna entre mostrar e ocultar a senha
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  /// Exibe um diálogo para editar o nome do usuário
  Future<void> _showEditNameDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(currentName: _currentUserName),
    );

    // Se o usuário confirmou e digitou um nome, atualiza o estado e persiste
    if (newName != null && newName.trim().isNotEmpty) {
      try {
        // Atualiza o nome no serviço de autenticação
        await _authService.atualizarNomePreferido(newName.trim());

        // Atualiza o estado local
        if (mounted) {
          setState(() {
            _currentUserName = newName.trim();
          });
        }
      } catch (e) {
        // Em caso de erro, mostra uma mensagem para o usuário
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar nome. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Exibe um diálogo de confirmação antes de fazer logout
  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutConfirmationDialog(),
    );

    if (shouldLogout == true && mounted) {
      _performLogout();
    }
  }

  /// Realiza o logout navegando para a tela de login
  void _performLogout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SettingsColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Constrói a AppBar personalizada
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Conta',
        style: TextStyle(
          color: _SettingsColors.titleText,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: _SettingsColors.background,
      iconTheme: const IconThemeData(color: _SettingsColors.iconDefault),
      elevation: 0, // Remove a sombra da AppBar
    );
  }

  /// Constrói o corpo da tela com todas as opções
  Widget _buildBody() {
    return Container(
      color: _SettingsColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Seção de informações do usuário
          _buildUserSection(),

          const SizedBox(height: 8.0),

          // Seção de preferências do aplicativo
          _buildPreferencesSection(),

          const SizedBox(height: 8.0),

          // Divisor visual
          _buildDivider(),

          const SizedBox(height: 8.0),

          // Seção de ações (logout)
          _buildActionsSection(),
        ],
      ),
    );
  }

  /// Constrói a seção com informações do usuário
  Widget _buildUserSection() {
    return Column(
      children: [
        // CNPJ (somente leitura)
        _SettingsListTile(
          icon: Icons.business_rounded,
          title: 'CNPJ',
          subtitle: widget.cnpj,
          iconColor: _SettingsColors.iconDefault,
        ),

        // Senha (com opção de mostrar/ocultar)
        _SettingsListTile(
          icon: Icons.vpn_key_rounded,
          title: 'Senha',
          subtitle: _isPasswordVisible ? widget.password : '••••••••',
          iconColor: _SettingsColors.iconDefault,
          onTap: _togglePasswordVisibility,
        ),

        // Nome (editável)
        _SettingsListTile(
          icon: Icons.person_rounded,
          title: 'Nome',
          subtitle: _currentUserName,
          iconColor: _SettingsColors.iconDefault,
          onTap: _showEditNameDialog,
        ),
      ],
    );
  }

  /// Constrói a seção com preferências do aplicativo
  Widget _buildPreferencesSection() {
    return Column(
      children: [
        // Esquema de cores
        _SettingsListTile(
          icon: Icons.color_lens_rounded,
          title: 'Esquema de cores',
          subtitle: 'Sistema (Padrão)',
          iconColor: _SettingsColors.iconDefault,
        ),

        // Idioma
        _SettingsListTile(
          icon: Icons.language_rounded,
          title: 'Idioma',
          subtitle: 'Padrão do sistema',
          iconColor: _SettingsColors.iconDefault,
        ),

        // Idioma de entrada
        _SettingsListTile(
          icon: Icons.mic_rounded,
          title: 'Idioma de entrada',
          subtitle: 'Autodetectar',
          iconColor: _SettingsColors.iconDefault,
        ),
      ],
    );
  }

  /// Constrói um divisor visual
  Widget _buildDivider() {
    return const Divider(
      color: _SettingsColors.divider,
      height: 1.0,
      thickness: 1.0,
    );
  }

  /// Constrói a seção de ações (logout)
  Widget _buildActionsSection() {
    return Column(
      children: [
        // Botão de sair
        _SettingsListTile(
          icon: Icons.logout_rounded,
          title: 'Sair',
          iconColor: _SettingsColors.logoutIcon,
          titleColor: _SettingsColors.logoutText,
          onTap: _showLogoutConfirmation,
        ),
      ],
    );
  }
}

// MARK: - Widgets Auxiliares

/// Widget personalizado para itens da lista de configurações
///
/// Este widget cria uma aparência consistente para todos os itens
/// da lista de configurações, com ícone, título e subtítulo opcionais.
class _SettingsListTile extends StatelessWidget {
  /// Ícone a ser exibido à esquerda
  final IconData icon;

  /// Título principal do item
  final String title;

  /// Subtítulo opcional (informação adicional)
  final String? subtitle;

  /// Cor do ícone
  final Color iconColor;

  /// Cor do título
  final Color titleColor;

  /// Callback executado quando o item é tocado
  final VoidCallback? onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    this.titleColor = _SettingsColors.titleText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Ícone à esquerda
      leading: Icon(icon, color: iconColor, size: 24.0),

      // Conteúdo principal (título e subtítulo)
      title: _buildTitleContent(),

      // Ação ao tocar
      onTap: onTap,

      // Padding interno
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),

      // Visual de foco/hover
      hoverColor: Colors.white.withValues(alpha: 0.05),
      splashColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  /// Constrói o conteúdo do título (com ou sem subtítulo)
  Widget _buildTitleContent() {
    if (subtitle == null || subtitle!.isEmpty) {
      // Apenas título
      return Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      // Título com subtítulo
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            subtitle!,
            style: const TextStyle(
              color: _SettingsColors.subtitleText,
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }
  }
}

/// Diálogo para editar o nome do usuário
class _EditNameDialog extends StatefulWidget {
  final String currentName;

  const _EditNameDialog({required this.currentName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _SettingsColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Modificar Nome',
        style: TextStyle(
          color: _SettingsColors.titleText,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: nameController,
        style: const TextStyle(
          color: _SettingsColors.titleText,
          fontSize: 16.0,
        ),
        decoration: InputDecoration(
          hintText: 'Digite seu nome preferido',
          hintStyle: const TextStyle(
            color: _SettingsColors.subtitleText,
            fontWeight: FontWeight.w400,
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2.0),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: _SettingsColors.subtitleText,
              width: 1.0,
            ),
          ),
        ),
        autofocus: true,
        maxLength: 50, // Limita o tamanho do nome
      ),
      actions: [
        // Botão cancelar
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: _SettingsColors.subtitleText,
              fontSize: 16.0,
            ),
          ),
        ),

        // Botão confirmar
        TextButton(
          onPressed: () {
            final newName = nameController.text.trim();
            if (newName.isNotEmpty) {
              Navigator.of(context).pop(newName);
            }
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Diálogo de confirmação para logout
class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _SettingsColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Confirmar Saída',
        style: TextStyle(
          color: _SettingsColors.titleText,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        'Tem certeza de que deseja sair da sua conta?',
        style: TextStyle(color: _SettingsColors.subtitleText, fontSize: 16.0),
      ),
      actions: [
        // Botão cancelar
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: _SettingsColors.subtitleText,
              fontSize: 16.0,
            ),
          ),
        ),

        // Botão confirmar
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Sair',
            style: TextStyle(
              color: _SettingsColors.logoutText,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// MARK: - Constantes de Cores

/// Classe com as cores específicas da tela de configurações
///
/// Centraliza todas as cores usadas na tela para facilitar manutenção
/// e garantir consistência visual.
class _SettingsColors {
  /// Cor de fundo da tela (#171717)
  static const Color background = Color(0xFF171717);

  /// Cor do texto de títulos (#FFFFFF)
  static const Color titleText = Color(0xFFFFFFFF);

  /// Cor do texto de subtítulos (#E6E6E6)
  static const Color subtitleText = Color(0xFFE6E6E6);

  /// Cor padrão dos ícones (#E6E6E6)
  static const Color iconDefault = Color(0xFFE6E6E6);

  /// Cor do texto e ícone de "Sair" (#FF3333)
  static const Color logoutText = Color(0xFFFF3333);
  static const Color logoutIcon = Color(0xFFFF3333);

  /// Cor do divisor (#454545)
  static const Color divider = Color(0xFF454545);
}
