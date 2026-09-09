import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_gradients.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';


// ── Color Tokens ──────────────────────────────────────────────────────────
Color get kBg      => AppColors.background;
Color get kSurface => AppColors.surface;
Color get kCard    => AppColors.card;
Color get kBorder  => AppColors.border;
Color get kBorder2 => AppColors.border;

// Role accents
Color get kCyan    => AppColors.customer;
Color get kVendor  => AppColors.vendor;
Color get kRider   => AppColors.rider;
Color get kAdmin   => AppColors.admin;

// Legacy alias
Color get kAccent  => kCyan;

// Status colours
Color get kSuccess => AppColors.success;
Color get kError   => AppColors.error;
Color get kWarning => AppColors.warning;
Color get kInfo    => AppColors.info;

// Text shades
Color get kTextPrimary   => AppColors.textPrimary;
Color get kTextSecondary => AppColors.textSecondary;
Color get kTextMuted     => AppColors.textMuted;

// ── Typography ──────────────────────────────────────────────────────────────
TextStyle kHeadline(double size, {Color? color, FontWeight fw = FontWeight.bold}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color ?? kTextPrimary, letterSpacing: -0.5);

TextStyle kBody(double size, {Color? color, FontWeight fw = FontWeight.normal}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color ?? kTextSecondary);

TextStyle kLabel(double size, {Color? color, FontWeight fw = FontWeight.w500}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color ?? kTextMuted, letterSpacing: 0.3);

// ── Gradients ───────────────────────────────────────────────────────────────
LinearGradient get kCyanGradient => AppGradients.customer;
LinearGradient get kVendorGradient => AppGradients.vendor;
LinearGradient get kRiderGradient => AppGradients.rider;
LinearGradient get kBgGradient => LinearGradient(
  colors: [AppColors.surface, AppColors.background],
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
);

// ── Card decoration ─────────────────────────────────────────────────────────
BoxDecoration kCardDeco({Color? accent, double radius = 14}) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: accent != null ? accent.withValues(alpha: 0.25) : kBorder, width: 1),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

BoxDecoration kGlassDeco({double radius = 14}) => BoxDecoration(
  color: kSurface.withValues(alpha: 0.92),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: kBorder, width: 1),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

BoxDecoration kGlowDeco(Color accent, {double radius = 14}) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
  boxShadow: [
    BoxShadow(
      color: accent.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ],
);

// ── Legacy decorator aliases ────────────────────────────────────────────────
BoxDecoration kGlowCard(Color accent, {double radius = 14}) => kGlowDeco(accent, radius: radius);

// ── Shared helpers ──────────────────────────────────────────────────────────
Widget kStatusPill(String label, Color color, {double fontSize = 11}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
  ),
  child: Text(
    label,
    style: GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
  ),
);

Widget kSectionHeader(String title, {Widget? trailing}) => Row(
  children: [
    Container(
      width: 3,
      height: 16,
      decoration: BoxDecoration(
        color: kCyan,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
          letterSpacing: -0.3,
        ),
      ),
    ),
    ?trailing,
  ],
);

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':    return kWarning;
    case 'confirmed':  return kCyan;
    case 'preparing':  return kInfo;
    case 'ready':      return kSuccess;
    case 'dispatched': return kRider;
    case 'delivered':  return kSuccess;
    case 'cancelled':  return kError;
    default:           return kTextMuted;
  }
}

String statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':    return 'Pending';
    case 'confirmed':  return 'Confirmed';
    case 'preparing':  return 'Preparing';
    case 'ready':      return 'Ready';
    case 'dispatched': return 'Dispatched';
    case 'delivered':  return 'Delivered';
    case 'cancelled':  return 'Cancelled';
    default:           return status;
  }
}

String statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':    return '⏳';
    case 'confirmed':  return '✅';
    case 'preparing':  return '🔧';
    case 'ready':      return '📦';
    case 'dispatched': return '🏍️';
    case 'delivered':  return '✔️';
    case 'cancelled':  return '❌';
    default:           return '•';
  }
}
