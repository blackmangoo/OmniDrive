import 'package:flutter/material.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';

class AppGradients {
  static LinearGradient get primary => LinearGradient(
        colors: [AppColors.cyan, AppColors.cyanDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondary => LinearGradient(
        colors: [AppColors.violet, AppColors.violetDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get customer => LinearGradient(
        colors: [AppColors.customer, AppColors.customerDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get vendor => LinearGradient(
        colors: [AppColors.vendor, AppColors.vendorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get rider => LinearGradient(
        colors: [AppColors.rider, AppColors.riderDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get admin => LinearGradient(
        colors: [AppColors.admin, AppColors.adminDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get mesh => const LinearGradient(
        colors: [
          Color(0x0A8B5CF6), // Subtle violet tint
          Color(0x053B82F6), // Subtle blue tint
          Color(0x00000000), 
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
}
