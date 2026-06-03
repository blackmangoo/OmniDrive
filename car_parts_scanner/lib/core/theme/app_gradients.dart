import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const primary = LinearGradient(
    colors: [AppColors.cyan, AppColors.cyanDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondary = LinearGradient(
    colors: [AppColors.violet, AppColors.violetDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Role Gradients
  static const customer = LinearGradient(
    colors: [AppColors.customer, AppColors.customerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const vendor = LinearGradient(
    colors: [AppColors.vendor, AppColors.vendorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const rider = LinearGradient(
    colors: [AppColors.rider, AppColors.riderDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const admin = LinearGradient(
    colors: [AppColors.admin, AppColors.adminDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mesh = RadialGradient(
    center: Alignment(-0.5, -0.6),
    radius: 1.2,
    colors: [
      Color(0x1F22D3EE), // Cyan glow
      Color(0x0A8B5CF6), // Violet glow
      Color(0x00000000),
    ],
  );
}
