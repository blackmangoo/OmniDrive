import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';

// ── Color Tokens ──────────────────────────────────────────────────────────────
const Color kBg      = AppColors.background;
const Color kSurface = AppColors.surface;
const Color kCard    = AppColors.card;
const Color kBorder  = AppColors.border;
const Color kBorder2 = AppColors.border;

// Role accents
const Color kCyan    = AppColors.cyan;
const Color kVendor  = AppColors.vendor;
const Color kRider   = AppColors.rider;
const Color kAdmin   = AppColors.admin;

// Legacy alias (used by pre-refactor screens)
const Color kAccent  = kCyan;

// Status colours
const Color kSuccess = AppColors.success;
const Color kError   = AppColors.error;
const Color kWarning = AppColors.warning;
const Color kInfo    = AppColors.info;

// Text shades
const Color kTextPrimary   = AppColors.textPrimary;
const Color kTextSecondary = AppColors.textSecondary;
const Color kTextMuted     = AppColors.textMuted;

// ── Typography ────────────────────────────────────────────────────────────────
TextStyle kHeadline(double size, {Color color = kTextPrimary, FontWeight fw = FontWeight.bold}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color, letterSpacing: -0.5);

TextStyle kBody(double size, {Color color = kTextSecondary, FontWeight fw = FontWeight.normal}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color);

TextStyle kLabel(double size, {Color color = kTextMuted, FontWeight fw = FontWeight.w500}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: fw, color: color, letterSpacing: 0.3);

// ── Gradients ─────────────────────────────────────────────────────────────────
const LinearGradient kCyanGradient = AppGradients.customer;
const LinearGradient kVendorGradient = AppGradients.vendor;
const LinearGradient kRiderGradient = AppGradients.rider;
const LinearGradient kBgGradient = LinearGradient(
  colors: [AppColors.surface, AppColors.background],
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
);

// ── Card decoration ───────────────────────────────────────────────────────────
BoxDecoration kCardDeco({Color? accent, double radius = 16}) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: accent?.withValues(alpha: 0.3) ?? kBorder, width: 1),
);

BoxDecoration kGlassDeco({double radius = 16}) => BoxDecoration(
  color: kSurface.withValues(alpha: 0.85),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: kBorder, width: 1),
  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
);

BoxDecoration kGlowDeco(Color accent, {double radius = 16}) => BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 16, spreadRadius: 0)],
);

// ── Legacy decorator aliases ─────────────────────────────────────────────────
/// Backwards-compat alias for kGlowDeco used by older screens.
BoxDecoration kGlowCard(Color accent, {double radius = 14}) =>
    kGlowDeco(accent, radius: radius);

// ── Shared helpers ────────────────────────────────────────────────────────────
Widget kStatusPill(String label, Color color, {double fontSize = 11}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: color.withValues(alpha: 0.4)),
  ),
  child: Text(label, style: GoogleFonts.inter(fontSize: fontSize, color: color, fontWeight: FontWeight.w600)),
);

Widget kSectionHeader(String title, {Widget? trailing}) => Row(
  children: [
    Container(width: 3, height: 18, decoration: BoxDecoration(
      gradient: kCyanGradient, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Expanded(child: Text(title, style: GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary))),
    trailing ?? const SizedBox.shrink(),
  ],
);

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':    return kWarning;
    case 'confirmed':  return kCyan;
    case 'preparing':  return const Color(0xFF60A5FA);
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
