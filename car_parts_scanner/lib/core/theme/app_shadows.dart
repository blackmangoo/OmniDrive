import 'package:flutter/material.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';

class AppShadows {
  // Soft elegant shadows for Light Mode, subtle ambient for Dark Mode
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.background.computeLuminance() > 0.5 ? 0.06 : 0.4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cyanGlow => [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: AppColors.background.computeLuminance() > 0.5 ? 0.15 : 0.25),
          blurRadius: 12,
          spreadRadius: 2,
          offset: Offset.zero,
        ),
      ];

  static List<BoxShadow> get violetGlow => [
        BoxShadow(
          color: AppColors.violet.withValues(alpha: AppColors.background.computeLuminance() > 0.5 ? 0.15 : 0.25),
          blurRadius: 12,
          spreadRadius: 2,
          offset: Offset.zero,
        ),
      ];

  static List<BoxShadow> roleGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: AppColors.background.computeLuminance() > 0.5 ? 0.12 : 0.2),
          blurRadius: 10,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ];
}
