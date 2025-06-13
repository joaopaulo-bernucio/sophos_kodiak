import 'package:flutter/material.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';
import 'package:sophos_kodiak/pages/login_page.dart';
import 'package:sophos_kodiak/services/user_storage_service.dart';

class SettingsPage extends StatefulWidget {
  final String cnpj;
  final String password;
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
  bool _isPasswordVisible = false;

  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _showEditNameDialog() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(currentName: _currentUserName),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        final success = await UserStorageService.updatePreferredName(
          newName.trim(),
        );

        if (success && mounted) {
          setState(() {
            _currentUserName = newName.trim();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nome atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar nome. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
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

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutConfirmationDialog(),
    );

    if (shouldLogout == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      await UserStorageService.clearUserData();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Erro ao fazer logout: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Conta',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: AppColors.background,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildUserSection(),
          const SizedBox(height: 8.0),
          _buildPreferencesSection(),
          const SizedBox(height: 8.0),
          _buildDivider(),
          const SizedBox(height: 8.0),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    return Column(
      children: [
        _SettingsListTile(
          icon: Icons.business_rounded,
          title: 'CNPJ',
          subtitle: widget.cnpj,
          iconColor: AppColors.textPrimary,
        ),
        _SettingsListTile(
          icon: Icons.vpn_key_rounded,
          title: 'Senha',
          subtitle: _isPasswordVisible ? widget.password : '••••••••',
          iconColor: AppColors.textPrimary,
          onTap: _togglePasswordVisibility,
        ),
        _SettingsListTile(
          icon: Icons.person_rounded,
          title: 'Nome',
          subtitle: _currentUserName,
          iconColor: AppColors.textPrimary,
          onTap: _showEditNameDialog,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        _SettingsListTile(
          icon: Icons.color_lens_rounded,
          title: 'Esquema de cores',
          subtitle: 'Sistema (Padrão)',
          iconColor: AppColors.textPrimary,
        ),
        _SettingsListTile(
          icon: Icons.language_rounded,
          title: 'Idioma',
          subtitle: 'Padrão do sistema',
          iconColor: AppColors.textPrimary,
        ),
        _SettingsListTile(
          icon: Icons.mic_rounded,
          title: 'Idioma de entrada',
          subtitle: 'Autodetectar',
          iconColor: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFF8A8A8A), height: 1.0, thickness: 1.0);
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        _SettingsListTile(
          icon: Icons.logout_rounded,
          title: 'Sair',
          iconColor: AppColors.error,
          titleColor: AppColors.error,
          onTap: _showLogoutConfirmation,
        ),
      ],
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color titleColor;
  final VoidCallback? onTap;

  const _SettingsListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.iconColor,
    this.titleColor = AppColors.textWhite,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24.0),
      title: _buildTitleContent(),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      hoverColor: Colors.white.withValues(alpha: 0.05),
      splashColor: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildTitleContent() {
    if (subtitle == null || subtitle!.isEmpty) {
      return Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
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
              color: AppColors.textPrimary,
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }
  }
}

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
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Modificar Nome',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: nameController,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 16.0),
        decoration: InputDecoration(
          hintText: 'Digite seu nome preferido',
          hintStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2.0),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.textPrimary, width: 1.0),
          ),
        ),
        autofocus: true,
        maxLength: 50,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16.0),
          ),
        ),
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

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Confirmar Saída',
        style: TextStyle(
          color: AppColors.textWhite,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: const Text(
        'Tem certeza de que deseja sair da sua conta?',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16.0),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16.0),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Sair',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
