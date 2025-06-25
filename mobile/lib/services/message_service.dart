import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum MessageType { success, error, warning, info }

class MessageService {
  /// Exibe uma mensagem customizada no contexto atual
  static void showMessage(
    BuildContext context, {
    required String message,
    required MessageType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomMessage(message: message, type: type, title: title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  /// Mensagem de sucesso
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showMessage(
      context,
      message: message,
      type: MessageType.success,
      title: title ?? 'Sucesso',
      duration: duration,
    );
  }

  /// Mensagem de erro
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showMessage(
      context,
      message: message,
      type: MessageType.error,
      title: title ?? 'Erro',
      duration: duration,
    );
  }

  /// Mensagem de aviso/alerta
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showMessage(
      context,
      message: message,
      type: MessageType.warning,
      title: title ?? 'Atenção',
      duration: duration,
    );
  }

  /// Mensagem informativa
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showMessage(
      context,
      message: message,
      type: MessageType.info,
      title: title ?? 'Informação',
      duration: duration,
    );
  }
}

class CustomMessage extends StatelessWidget {
  final String message;
  final MessageType type;
  final String? title;

  const CustomMessage({
    super.key,
    required this.message,
    required this.type,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getMessageConfig(type);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.messagePadding),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.messageRadius),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: config.borderColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: config.iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              config.icon,
              color: config.iconColor,
              size: AppDimensions.messageIconSize,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTextStyles.messageTitle.copyWith(
                      color: config.iconColor,
                    ),
                  ),
                if (title != null) const SizedBox(height: 4),
                Text(message, style: AppTextStyles.messageContent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MessageConfig _getMessageConfig(MessageType type) {
    switch (type) {
      case MessageType.success:
        return _MessageConfig(
          backgroundColor: AppColors.successBackground,
          borderColor: AppColors.successBorder,
          iconColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case MessageType.error:
        return _MessageConfig(
          backgroundColor: AppColors.errorBackground,
          borderColor: AppColors.errorBorder,
          iconColor: AppColors.error,
          icon: Icons.error_outline,
        );
      case MessageType.warning:
        return _MessageConfig(
          backgroundColor: AppColors.warningBackground,
          borderColor: AppColors.warningBorder,
          iconColor: AppColors.warning,
          icon: Icons.warning_outlined,
        );
      case MessageType.info:
        return _MessageConfig(
          backgroundColor: AppColors.infoBackground,
          borderColor: AppColors.infoBorder,
          iconColor: AppColors.info,
          icon: Icons.info_outline,
        );
    }
  }
}

class _MessageConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;

  _MessageConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
  });
}
