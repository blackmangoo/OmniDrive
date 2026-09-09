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

  // ── Core Backgrounds (warm neutral, not cold blue) ──────────────────────
  static Color get background => _isDark ? const Color(0xFF111113) : const Color(0xFFF7F7F5);
  static Color get surface => _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get card => _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  static Color get border => _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E3);

  // ── Primary Accent (warm indigo instead of cold cyan) ───────────────────
  static Color get cyan => _isDark ? const Color(0xFF7C6EF6) : const Color(0xFF5A4ED1);
  static Color get cyanDark => const Color(0xFF4338CA);
  static Color get violet => _isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  static Color get violetDark => const Color(0xFF5B21B6);

  // ── Accent highlights (muted, natural) ─────────────────────────────────
  static const lime = Color(0xFF10B981);
  static const magenta = Color(0xFFF472B6);

  // ── Role accents (warm, distinct) ──────────────────────────────────────
  static const customer = Color(0xFF5A4ED1);
  static const customerDark = Color(0xFF4338CA);
  static const vendor = Color(0xFFD97706);
  static const vendorDark = Color(0xFFB45309);
  static const rider = Color(0xFF7C3AED);
  static const riderDark = Color(0xFF5B21B6);
  static const admin = Color(0xFFDC2626);
  static const adminDark = Color(0xFF991B1B);

  // ── Status colors ─────────────────────────────────────────────────────
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);

  // ── Text colors (high contrast, warm tone) ─────────────────────────────
  static Color get textPrimary => _isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917);
  static Color get textSecondary => _isDark ? const Color(0xFFA8A29E) : const Color(0xFF57534E);
  static Color get textMuted => _isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E);
}
