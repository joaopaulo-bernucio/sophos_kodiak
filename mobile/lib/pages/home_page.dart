import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'chatbot_page.dart';

class HomePage extends StatelessWidget {
  final String? userName;

  const HomePage({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final String? userNameFromArgs =
        ModalRoute.of(context)?.settings.arguments as String?;
    final String? finalUserName = userName ?? userNameFromArgs;

    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Página Principal', style: AppTextStyles.title),
        centerTitle: true,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: canPop,
      ),
      body: _MenuContent(userName: finalUserName),
    );
  }
}

class _MenuContent extends StatelessWidget {
  final String? userName;

  const _MenuContent({this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _WelcomeSection(),
            const SizedBox(height: AppDimensions.paddingLarge),
            Expanded(child: _MenuGrid(userName: userName)),
          ],
        ),
      ),
    );
  }
}

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
          style: AppTextStyles.title.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        const Text(
          'Escolha uma das opções abaixo para continuar',
          style: AppTextStyles.largeText,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final String? userName;

  const _MenuGrid({this.userName});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.paddingMedium,
      mainAxisSpacing: AppDimensions.paddingMedium,
      childAspectRatio: 1.1,
      children: [
        _MenuCard(
          icon: Icons.smart_toy,
          title: 'Chatbot IA',
          subtitle: 'Assistente inteligente',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatbotPage(userName: userName),
            ),
          ),
        ),
        _MenuCard(
          icon: Icons.bar_chart,
          title: 'Relatórios',
          subtitle: 'Gráficos e análises',
          onTap: () => Navigator.pushNamed(context, '/charts'),
        ),
        _MenuCard(
          icon: Icons.network_check,
          title: 'Teste Rede',
          subtitle: 'Diagnosticar conexão',
          onTap: () => Navigator.pushNamed(context, '/network-test'),
        ),
        _MenuCard(
          icon: Icons.settings,
          title: 'Configurações',
          subtitle: 'Ajustes do sistema',
          onTap: () => _showFeatureDialog(context, 'Configurações'),
        ),
      ],
    );
  }

  void _showFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(feature, style: AppTextStyles.title.copyWith(fontSize: 24)),
        content: const Text(
          'Esta funcionalidade está em desenvolvimento e será disponibilizada em breve.',
          style: AppTextStyles.largeText,
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
      color: AppColors.elementsBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
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
                    color: AppColors.textSecondary,
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
