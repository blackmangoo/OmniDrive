import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Elevation.
///
/// The previous tokens here were `cyanGlow`, `violetGlow` and `roleGlow`:
/// chromatic shadows with `spreadRadius > 0` at `Offset.zero`. A coloured halo
/// around a button is the single most recognisable machine-generated styling
/// choice in Flutter, and it was applied to every primary CTA, every selected
/// tab and every hero circle in the auth flow. All three are gone.
///
/// Elevation is now neutral and directional (offset downward, no spread), and
/// in dark mode cards carry no shadow at all — dark surfaces are separated by
/// tone and a hairline border, because a black shadow on a near-black
/// background renders as nothing.
class AppShadows {
  AppShadows._();

  /// Cards and static panels.
  static List<BoxShadow> get card => AppColors.isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF16161A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];

  /// Sticky bars, FABs and anything floating above scrolling content.
  static List<BoxShadow> get raised => AppColors.isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF16161A).withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];

  /// Bottom sheets, dialogs and menus.
  static List<BoxShadow> get overlay => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.6 : 0.18),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  /// Border to pair with [card] in dark mode, where the shadow is absent.
  static BorderSide get cardBorder => BorderSide(color: AppColors.border);
}
