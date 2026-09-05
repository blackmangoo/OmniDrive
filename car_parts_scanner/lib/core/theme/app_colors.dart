import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppColors {
  static bool get _isDark {
    try {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (_) {
      return true; // Fallback
    }
  }

  static Color get background => _isDark ? const Color(0xFF12121A) : const Color(0xFFF9FAFB);
  static Color get surface => _isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
  static Color get card => _isDark ? const Color(0xFF1E1E2C) : const Color(0xFFFFFFFF);
  static Color get border => _isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE5E7EB);

  // Elegant Core Colors (Replacing Neon)
  static Color get cyan => _isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB); 
  static Color get cyanDark => const Color(0xFF1D4ED8);
  static Color get violet => _isDark ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1);
  static Color get violetDark => const Color(0xFF4F46E5);

  // POP highlights
  static const lime = Color(0xFF10B981); 
  static const magenta = Color(0xFFEC4899); 

  // Role accents
  static const customer = Color(0xFF3B82F6);
  static const customerDark = Color(0xFF2563EB);
  static const vendor = Color(0xFFF59E0B);
  static const vendorDark = Color(0xFFD97706);
  static const rider = Color(0xFF8B5CF6);
  static const riderDark = Color(0xFF7C3AED);
  static const admin = Color(0xFFEF4444);
  static const adminDark = Color(0xFFDC2626);

  // Status colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Text colors
  static Color get textPrimary => _isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
  static Color get textSecondary => _isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
  static Color get textMuted => _isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
}
