import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale for OmniDrive.
///
/// Seven steps, no more. Screens were previously overriding [fontSize] inline
/// 29 times, producing a 14-step scale where a 5-step one was defined; those
/// overrides are the reason headings looked inconsistent between sibling
/// screens. Compose with `copyWith(color:)` / `copyWith(fontWeight:)` freely,
/// but do not override [fontSize] or [letterSpacing] — pick the right step.
///
/// Tracking is negative only on the two display steps, where Inter's default
/// spacing is genuinely too loose. Everything else is 0: decorative
/// letter-spacing on labels and pills was a consistent tell across the app.
class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.6,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.4,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
        letterSpacing: -0.2,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  /// 13px is the floor for any text a user is expected to read. The 9-11px
  /// labels previously used for badges, stock counts and status pills were
  /// both illegible and under-contrast.
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  /// Large numeric readouts: prices, KPI values, telemetry.
  ///
  /// Tabular figures stop digits from reflowing horizontally while a value
  /// changes, which is what made animated counters visibly jitter.
  static TextStyle get metric => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Smaller numeric readouts inside dense rows and result cards.
  static TextStyle get metricSmall => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Timestamps and elapsed-time readouts, where a fixed digit width keeps the
  /// line from shifting every second.
  static TextStyle get mono => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
