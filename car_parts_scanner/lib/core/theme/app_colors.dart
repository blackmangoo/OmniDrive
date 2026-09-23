import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Semantic colour tokens for OmniDrive.
///
/// Every foreground/background pair below is verified against WCAG 2.1 AA
/// (4.5:1 for text, 3:1 for meaningful UI boundaries). Status colours come in
/// two variants because in dark mode a single hue cannot simultaneously carry
/// white text as a fill *and* remain legible as text on a dark surface:
///   - `success` / `warning` / `error` / `info` are **foreground** colours.
///   - `successFill` / ... are **solid fills** that carry [onStatus].
///
/// [isDark] must agree with the brightness of the active [ThemeData]. The app
/// registers both themes with `themeMode: ThemeMode.system`, so it tracks
/// [PlatformDispatcher.platformBrightness].
class AppColors {
  AppColors._();

  static bool get isDark {
    try {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    } catch (_) {
      return true;
    }
  }

  static bool get _isDark => isDark;

  // ── Surfaces ─────────────────────────────────────────────────────────────
  // Three elevation steps. [field] is deliberately recessed so an input reads
  // as an input without relying on its border alone.
  static Color get background =>
      _isDark ? const Color(0xFF0F0F12) : const Color(0xFFF6F6F7);
  static Color get surface =>
      _isDark ? const Color(0xFF17171B) : const Color(0xFFFFFFFF);

  /// Cards and panels are surfaces. Kept as an explicit name because the two
  /// are used interchangeably across screens; they are the same elevation.
  static Color get card => surface;

  /// Recessed fill for text inputs and search fields.
  static Color get field =>
      _isDark ? const Color(0xFF121216) : const Color(0xFFF1F1F3);

  /// Hairline separator. Decorative only — never the sole boundary of a
  /// meaningful control.
  static Color get border =>
      _isDark ? const Color(0xFF26262C) : const Color(0xFFE2E2E6);

  /// Boundary for controls that need to be identifiable without fill, e.g.
  /// the idle outline of a text field.
  static Color get borderStrong =>
      _isDark ? const Color(0xFF4C4C56) : const Color(0xFF8E8E9C);

  // ── Brand ────────────────────────────────────────────────────────────────
  // One accent for the whole product. Roles are distinguished by content and
  // layout, not by re-skinning the palette.
  //
  // [accent] is the fill (white text on it is >= 4.5:1 in both modes);
  // [accentText] is the legible foreground variant for links and icons.
  static Color get accent =>
      _isDark ? const Color(0xFF6C63E8) : const Color(0xFF4B44C4);
  static Color get accentPressed =>
      _isDark ? const Color(0xFF5A51D6) : const Color(0xFF3E38AB);
  static Color get accentText =>
      _isDark ? const Color(0xFFA9A1F7) : const Color(0xFF4B44C4);
  static Color get onAccent => const Color(0xFFFFFFFF);

  /// Tinted background for selected rows, chips and badges.
  static Color get accentSoft => accent.withValues(alpha: 0.14);

  // ── Role accents ──────────────────────────────────────────────────────────
  static const customer = Color(0xFF5A4ED1);
  static const customerDark = Color(0xFF4338CA);
  static const vendor = Color(0xFFD97706);
  static const vendorDark = Color(0xFFB45309);
  static const rider = Color(0xFF7C3AED);
  static const riderDark = Color(0xFF5B21B6);
  static const admin = Color(0xFFDC2626);
  static const adminDark = Color(0xFF991B1B);
  static Color get cyan => accent;

  // ── Status: foreground ───────────────────────────────────────────────────
  static Color get success =>
      _isDark ? const Color(0xFF5AD3A0) : const Color(0xFF0F6E4F);
  static Color get warning =>
      _isDark ? const Color(0xFFE7B84F) : const Color(0xFF7A5200);
  static Color get error =>
      _isDark ? const Color(0xFFFF6B70) : const Color(0xFFB3252A);
  static Color get info =>
      _isDark ? const Color(0xFF6FB4F7) : const Color(0xFF1A63AB);

  // ── Status: solid fills (pair with [onStatus]) ───────────────────────────
  static Color get successFill =>
      _isDark ? const Color(0xFF17845A) : const Color(0xFF12805C);
  static Color get warningFill =>
      _isDark ? const Color(0xFF8F6410) : const Color(0xFF8A5D00);
  static Color get errorFill => const Color(0xFFC62A2F);
  static Color get infoFill => const Color(0xFF1D6FBF);

  static Color get onStatus => const Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────────────────
  // All three clear 4.5:1 on background, surface and field.
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF2F2F4) : const Color(0xFF16161A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFB4B4BC) : const Color(0xFF4A4A52);
  static Color get textMuted =>
      _isDark ? const Color(0xFF8B8B95) : const Color(0xFF6B6B74);

  /// Foreground for content drawn on photography or video. Always light,
  /// because it is paired with a scrim rather than with a surface token.
  static Color get onMedia => const Color(0xFFFFFFFF);

  /// Scrim behind controls that sit on a camera preview.
  static Color get mediaScrim => const Color(0x99000000);
}
