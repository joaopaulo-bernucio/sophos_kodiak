// Testes para as constantes da aplicação Sophos Kodiak
//
// Este arquivo testa todas as constantes de cores, estilos de texto e dimensões
// para garantir consistência no design system.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sophos_kodiak/constants/app_constants.dart';

void main() {
  group('AppColors Tests', () {
    test('Deve ter cores primárias definidas corretamente', () {
      // Assert - Verificar cores primárias
      expect(AppColors.primary, equals(const Color(0xFFF6790F)));
      expect(AppColors.primaryDark, equals(const Color(0xFF3B1D00)));
    });

    test('Deve ter cores de fundo definidas corretamente', () {
      // Assert - Verificar cores de fundo
      expect(AppColors.background, equals(const Color(0xFF000000)));
      expect(AppColors.elementsBackground, equals(const Color(0xFF2E2E2E)));
    });

    test('Deve ter cores de texto definidas corretamente', () {
      // Assert - Verificar cores de texto
      expect(AppColors.textPrimary, equals(const Color(0xFFE6E6E6)));
      expect(AppColors.textSecondary, equals(const Color(0xFFA1A1A1)));
      expect(AppColors.textHint, equals(const Color(0xFFB8B8B8)));
    });

    test('Deve ter cores de feedback definidas corretamente', () {
      // Assert - Verificar cores de feedback
      expect(AppColors.error, equals(const Color(0xFFFF5722)));
      expect(AppColors.success, equals(const Color(0xFF4CAF50)));
      expect(AppColors.warning, equals(const Color(0xFFFF9800)));
    });

    test('Deve ter contraste adequado entre cores', () {
      // Assert - Verificar se cores de texto têm contraste com fundo
      expect(
        AppColors.textPrimary.computeLuminance(),
        greaterThan(AppColors.background.computeLuminance()),
      );
      expect(
        AppColors.textSecondary.computeLuminance(),
        greaterThan(AppColors.background.computeLuminance()),
      );
      expect(
        AppColors.primary.computeLuminance(),
        greaterThan(AppColors.background.computeLuminance()),
      );
    });
  });

  group('AppTextStyles Tests', () {
    test('Deve ter estilo de título definido corretamente', () {
      // Assert - Verificar estilo do título
      expect(AppTextStyles.title.fontFamily, equals('AntonSC'));
      expect(AppTextStyles.title.color, equals(Colors.white));
      expect(AppTextStyles.title.fontSize, equals(48));
      expect(AppTextStyles.title.letterSpacing, equals(0.5));
    });

    test('Deve ter estilo de subtítulo definido corretamente', () {
      // Assert - Verificar estilo do subtítulo
      expect(AppTextStyles.subtitle.fontFamily, equals('Roboto'));
      expect(AppTextStyles.subtitle.color, equals(AppColors.primary));
      expect(AppTextStyles.subtitle.fontSize, equals(32));
      expect(AppTextStyles.subtitle.fontWeight, equals(FontWeight.w700));
    });

    test('Deve ter estilo de descrição definido corretamente', () {
      // Assert - Verificar estilo da descrição
      expect(AppTextStyles.description.fontFamily, equals('Roboto'));
      expect(AppTextStyles.description.color, equals(AppColors.textPrimary));
      expect(AppTextStyles.description.fontSize, equals(20));
    });

    test('Deve ter estilo de label definido corretamente', () {
      // Assert - Verificar estilo do label
      expect(AppTextStyles.label.fontFamily, equals('Roboto'));
      expect(AppTextStyles.label.color, equals(AppColors.textPrimary));
      expect(AppTextStyles.label.fontSize, equals(24));
      expect(AppTextStyles.label.fontWeight, equals(FontWeight.w700));
    });

    test('Deve ter estilos de entrada definidos corretamente', () {
      // Assert - Verificar estilos de entrada
      expect(AppTextStyles.inputText.color, equals(Colors.white));
      expect(AppTextStyles.inputHint.fontFamily, equals('Roboto'));
      expect(AppTextStyles.inputHint.color, equals(AppColors.textHint));
      expect(AppTextStyles.inputHint.fontSize, equals(18));
    });

    test('Deve ter estilos de botão definidos corretamente', () {
      // Assert - Verificar estilos de botão
      expect(AppTextStyles.button.fontFamily, equals('Roboto'));
      expect(AppTextStyles.button.fontSize, equals(22));
      expect(AppTextStyles.button.fontWeight, equals(FontWeight.w800));
      expect(AppTextStyles.button.color, equals(AppColors.primaryDark));
    });

    test('Deve ter estilo de link definido corretamente', () {
      // Assert - Verificar estilo do link
      expect(AppTextStyles.link.fontFamily, equals('Roboto'));
      expect(AppTextStyles.link.fontSize, equals(18));
      expect(AppTextStyles.link.color, equals(AppColors.textPrimary));
      expect(AppTextStyles.link.decoration, equals(TextDecoration.underline));
    });
  });

  group('AppDimensions Tests', () {
    test('Deve ter padding e margin definidos corretamente', () {
      // Assert - Verificar dimensões de padding
      expect(AppDimensions.paddingSmall, equals(8.0));
      expect(AppDimensions.paddingMedium, equals(16.0));
      expect(AppDimensions.paddingLarge, equals(24.0));
    });

    test('Deve ter border radius definidos corretamente', () {
      // Assert - Verificar border radius
      expect(AppDimensions.borderRadius, equals(12.0));
    });

    test('Deve ter progressão lógica de tamanhos', () {
      // Assert - Verificar se os tamanhos seguem uma progressão lógica
      expect(AppDimensions.paddingSmall, lessThan(AppDimensions.paddingMedium));
      expect(AppDimensions.paddingMedium, lessThan(AppDimensions.paddingLarge));

      expect(AppDimensions.borderRadius, equals(12.0));
    });
  });

  group('Design System Consistency Tests', () {
    test('Deve usar cores consistentes entre estilos de texto', () {
      // Assert - Verificar consistência de cores
      expect(AppTextStyles.subtitle.color, equals(AppColors.primary));
      expect(AppTextStyles.description.color, equals(AppColors.textPrimary));
      expect(AppTextStyles.label.color, equals(AppColors.textPrimary));
      expect(AppTextStyles.inputHint.color, equals(AppColors.textHint));
    });

    test('Deve usar fonte Roboto consistentemente', () {
      // Assert - Verificar uso consistente da fonte Roboto
      const robotoStyles = [
        AppTextStyles.subtitle,
        AppTextStyles.description,
        AppTextStyles.label,
        AppTextStyles.inputHint,
        AppTextStyles.button,
        AppTextStyles.link,
      ];

      for (final style in robotoStyles) {
        expect(style.fontFamily, equals('Roboto'));
      }
    });

    test('Deve ter tamanhos de fonte em escala adequada', () {
      // Assert - Verificar escala de tamanhos de fonte
      expect(
        AppTextStyles.title.fontSize ?? 14.0,
        greaterThan(AppTextStyles.subtitle.fontSize ?? 12.0),
      );
      expect(
        AppTextStyles.subtitle.fontSize ?? 12.0,
        greaterThan(AppTextStyles.label.fontSize ?? 10.0),
      );
      expect(
        AppTextStyles.label.fontSize ?? 10.0,
        greaterThan(AppTextStyles.description.fontSize ?? 8.0),
      );
    });
  });

  group('Theme Integration Tests', () {
    testWidgets('Deve integrar corretamente com tema Flutter', (
      WidgetTester tester,
    ) async {
      // Arrange
      final theme = ThemeData(
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.background,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Container(
            color: AppColors.background,
            child: const Text('Test', style: AppTextStyles.title),
          ),
        ),
      );

      // Assert - Verificar se não há erros de renderização
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Deve funcionar com diferentes tamanhos de tela', (
      WidgetTester tester,
    ) async {
      // Arrange - Testar com tamanho de tablet
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Text('Título', style: AppTextStyles.title),
                Text('Subtítulo', style: AppTextStyles.subtitle),
                Text('Descrição', style: AppTextStyles.description),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Subtítulo'), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);

      // Restaurar tamanho padrão
      await tester.binding.setSurfaceSize(null);
    });
  });
}
