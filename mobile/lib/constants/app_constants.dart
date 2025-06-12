import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF6790F);
  static const Color primaryDark = Color(0xFF3B1D00);

  static const Color background = Color(0xFF171717);
  static const Color surface = Color(0xFF171717);
  static const Color surfaceLight = Color(0xFF454545);

  static const Color textPrimary = Color(0xFFE6E6E6);
  static const Color textSecondary = Color(0xFFA1A1A1);
  static const Color textHint = Color(0xFFB8B8B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color buttonSendBackground = Color(0xFFE6E6E6);
  static const Color buttonSendIcon = Color(0xFF2E2E2E);
  static const Color buttonSendDisabled = Color(0xFF5C5C5C);
  static const Color buttonAttachBackground = Color(0xFF5C5C5C);
  static const Color buttonAttachIcon = Color(0xFFCECECE);
  static const Color suggestionCardBackground = Color(0xFF2E2E2E);

  static const Color error = Color(0xFFFF5722);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color destructive = Color(0xFFFF3333);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontFamily: 'AntonSC',
    color: Colors.white,
    fontSize: 48,
    letterSpacing: 0.5,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.primary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle description = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
    fontSize: 20,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle inputText = TextStyle(color: Colors.white);

  static const TextStyle inputHint = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    fontSize: 18,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDark,
    letterSpacing: 0.5,
  );

  static const TextStyle link = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    color: AppColors.textPrimary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textPrimary,
  );
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 10.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 35.0;

  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double logoHeight = 250.0;
}
