import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static final cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static final cyanGlow = [
    BoxShadow(
      color: AppColors.cyan.withValues(alpha: 0.25),
      blurRadius: 12,
      spreadRadius: 2,
      offset: Offset.zero,
    ),
  ];

  static final violetGlow = [
    BoxShadow(
      color: AppColors.violet.withValues(alpha: 0.25),
      blurRadius: 12,
      spreadRadius: 2,
      offset: Offset.zero,
    ),
  ];

  static List<BoxShadow> roleGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 10,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ];
}
