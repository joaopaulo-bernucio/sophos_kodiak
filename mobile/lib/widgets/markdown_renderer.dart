import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../constants/app_constants.dart';

class MarkdownRenderer extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool selectable;

  const MarkdownRenderer({
    super.key,
    required this.text,
    this.isUser = false,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isUser ? AppColors.primaryDark : AppColors.textPrimary;

    Widget markdownWidget = GptMarkdown(
      text,
      style: AppTextStyles.primaryText.copyWith(color: textColor, height: 1.5),
    );

    if (selectable && !isUser) {
      markdownWidget = SelectionArea(child: markdownWidget);
    }

    return Theme(
      data: _buildCustomTheme(context, textColor),
      child: Container(padding: const EdgeInsets.all(4), child: markdownWidget),
    );
  }

  ThemeData _buildCustomTheme(BuildContext context, Color textColor) {
    return Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.copyWith(
        headlineLarge: AppTextStyles.title.copyWith(
          color: isUser ? AppColors.primaryDark : AppColors.primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: AppTextStyles.title.copyWith(
          color: isUser ? AppColors.primaryDark : AppColors.primary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: AppTextStyles.title.copyWith(
          color: isUser ? AppColors.primaryDark : AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 14,
        ),
        bodySmall: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          fontFamily: 'monospace',
          color: textColor,
          fontSize: 14,
          backgroundColor: isUser
              ? AppColors.primaryDark.withValues(alpha: 0.1)
              : AppColors.background.withValues(alpha: 0.5),
        ),
      ),
      dividerColor: textColor.withValues(alpha: 0.3),
      cardColor: isUser
          ? AppColors.primaryDark.withValues(alpha: 0.1)
          : AppColors.background.withValues(alpha: 0.5),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          isUser
              ? AppColors.primaryDark.withValues(alpha: 0.1)
              : AppColors.background,
        ),
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        headingTextStyle: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: AppTextStyles.primaryText.copyWith(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: isUser ? AppColors.primaryDark : AppColors.primary,
        secondary: isUser ? AppColors.primaryDark : AppColors.primary,
        surface: isUser
            ? AppColors.primaryDark.withValues(alpha: 0.1)
            : AppColors.background,
        onSurface: textColor,
        surfaceContainerHighest: isUser
            ? AppColors.primaryDark.withValues(alpha: 0.1)
            : AppColors.background,
        onSurfaceVariant: textColor,
      ),
    );
  }
}

class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String? language;
  final bool isUser;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isUser
        ? AppColors.primaryDark.withValues(alpha: 0.1)
        : AppColors.background.withValues(alpha: 0.8);

    final textColor = isUser ? AppColors.primaryDark : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 1),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null && language!.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                language!.toUpperCase(),
                style: AppTextStyles.primaryText.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SelectionArea(
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                color: textColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TableWidget extends StatelessWidget {
  final List<List<String>> rows;
  final bool isUser;

  const TableWidget({super.key, required this.rows, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final textColor = isUser ? AppColors.primaryDark : AppColors.textPrimary;
    final borderColor = textColor.withValues(alpha: 0.3);
    // Força sempre o fundo escuro do app para cabeçalhos de tabela em mensagens do bot
    final headerColor = isUser
        ? AppColors.primaryDark.withValues(alpha: 0.1)
        : AppColors.background;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isHeader = entry.key == 0;
          final row = entry.value;

          return Container(
            decoration: BoxDecoration(
              color: isHeader ? headerColor : null,
              border: entry.key > 0
                  ? Border(top: BorderSide(color: borderColor))
                  : null,
            ),
            child: Row(
              children: row.asMap().entries.map((cellEntry) {
                final cell = cellEntry.value;

                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: cellEntry.key > 0
                        ? BoxDecoration(
                            border: Border(
                              left: BorderSide(color: borderColor),
                            ),
                          )
                        : null,
                    child: Text(
                      cell,
                      style: AppTextStyles.primaryText.copyWith(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isHeader
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
