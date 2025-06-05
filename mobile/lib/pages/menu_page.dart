import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Página de menu principal do aplicativo Sophos Kodiak
///
/// Esta página exibe as principais opções de navegação do sistema,
/// mantendo o tema escuro consistente com o resto do aplicativo.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Menu Principal', style: AppTextStyles.subtitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const _MenuContent(),
    );
  }
}

/// Widget que contém o conteúdo principal do menu
class _MenuContent extends StatelessWidget {
  const _MenuContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.borderRadiusExtraLarge,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingExtraLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _WelcomeSection(),
            const SizedBox(height: AppDimensions.paddingExtraLarge),
            Expanded(child: _MenuGrid()),
          ],
        ),
      ),
    );
  }
}

/// Seção de boas-vindas do menu
class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.dashboard, size: 80, color: AppColors.primary),
        const SizedBox(height: AppDimensions.paddingMedium),
        Text(
          'Bem-vindo ao Kodiak',
          style: AppTextStyles.subtitle.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Escolha uma das opções abaixo para continuar',
          style: AppTextStyles.description,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Grid com as opções do menu
class _MenuGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.paddingMedium,
      mainAxisSpacing: AppDimensions.paddingMedium,
      childAspectRatio: 1.1, // Aspect ratio mais adequado para evitar overflow
      children: [
        _MenuCard(
          icon: Icons.smart_toy,
          title: 'Chatbot IA',
          subtitle: 'Assistente inteligente',
          onTap: () => Navigator.pushNamed(context, '/chatbot'),
        ),
        _MenuCard(
          icon: Icons.bar_chart,
          title: 'Relatórios',
          subtitle: 'Gráficos e análises',
          onTap: () => Navigator.pushNamed(context, '/charts'),
        ),
        _MenuCard(
          icon: Icons.settings,
          title: 'Configurações',
          subtitle: 'Ajustes do sistema',
          onTap: () => _showFeatureDialog(context, 'Configurações'),
        ),
        _MenuCard(
          icon: Icons.help,
          title: 'Ajuda',
          subtitle: 'Suporte e documentação',
          onTap: () => _showFeatureDialog(context, 'Ajuda'),
        ),
      ],
    );
  }

  /// Exibe um diálogo informando que a funcionalidade está em desenvolvimento
  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          feature,
          style: AppTextStyles.subtitle.copyWith(fontSize: 24),
        ),
        content: const Text(
          'Esta funcionalidade está em desenvolvimento e será disponibilizada em breve.',
          style: AppTextStyles.description,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Card individual do menu
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingSmall),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Icon(icon, size: 36, color: AppColors.primary)),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
