import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF6790F);
  static const Color primaryDark = Color(0xFF3B1D00);

  static const Color background = Color(0xFF171717);
  static const Color elementsBackground = Color(0xFF2E2E2E);

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFCECECE);
  static const Color textPlaceholder = Color(0xFFA1A1A1);

  static const Color sendButtonBackground = Color(0xFFE6E6E6);
  static const Color sendButtonIcon = Color(0xFF2E2E2E);

  static const Color error = Color(0xFFFF3333);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
}

class AppTextStyles {
  static const TextStyle logoTitle = TextStyle(
    fontFamily: 'AntonSC',
    color: Colors.white,
    fontSize: 48,
    letterSpacing: 0.5,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.primary,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle primaryText = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputPlaceholder = TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    color: AppColors.textPlaceholder,
    fontSize: 18,
  );

  static const TextStyle largeText = TextStyle(
    fontFamily: 'Roboto',
    color: AppColors.textPrimary,
    fontSize: 22,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDark,
    letterSpacing: 0.5,
  );
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadius = 24.0;
  static const double loginBorderRadius = 12.0;
}
