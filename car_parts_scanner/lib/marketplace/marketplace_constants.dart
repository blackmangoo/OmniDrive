import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';

// ── Colour tokens ───────────────────────────────────────────────────────────
//
// Thin aliases over [AppColors] so marketplace screens read consistently.
// There is one accent. The previous `kCyan` / `kVendor` / `kRider` / `kAdmin`
// set resolved to four hues within about 15 degrees of each other — customer
// and rider measured 1.07:1 apart, so the "role colour coding" was not
// perceptible as coding, it was decoration. `kCyan` was also not cyan; the
// underlying value was indigo. Role is stated in words on every role-specific
// screen, which is how a user actually tells them apart.

Color get kBg => AppColors.background;
Color get kSurface => AppColors.surface;
Color get kCard => AppColors.card;
Color get kField => AppColors.field;
Color get kBorder => AppColors.border;
Color get kBorderStrong => AppColors.borderStrong;

Color get kAccent => AppColors.accent;
Color get kAccentText => AppColors.accentText;
Color get kOnAccent => AppColors.onAccent;

// Status colours are foreground values: safe for text, icons and tinted
// badges. Use the `*Fill` variants for solid fills carrying white text.
Color get kSuccess => AppColors.success;
Color get kError => AppColors.error;
Color get kWarning => AppColors.warning;
Color get kInfo => AppColors.info;
Color get kSuccessFill => AppColors.successFill;
Color get kErrorFill => AppColors.errorFill;
Color get kWarningFill => AppColors.warningFill;
Color get kInfoFill => AppColors.infoFill;
Color get kOnStatus => AppColors.onStatus;

Color get kTextPrimary => AppColors.textPrimary;
Color get kTextSecondary => AppColors.textSecondary;
Color get kTextMuted => AppColors.textMuted;

// ── Typography ──────────────────────────────────────────────────────────────
//
// No decorative letter-spacing. `kHeadline` used -0.5, `kLabel` +0.3,
// `kStatusPill` -0.2 and `kSectionHeader` -0.3 — tracking fiddling baked into
// every text helper, which is why otherwise identical labels rendered
// differently from screen to screen.

TextStyle kHeadline(double size,
        {Color? color, FontWeight fw = FontWeight.w600}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: fw,
      color: color ?? kTextPrimary,
      height: size >= 22 ? 1.25 : 1.35,
    );

TextStyle kBody(double size,
        {Color? color, FontWeight fw = FontWeight.w400}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: fw,
      color: color ?? kTextSecondary,
      height: 1.45,
    );

TextStyle kLabel(double size,
        {Color? color, FontWeight fw = FontWeight.w500}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: fw,
      color: color ?? kTextSecondary,
      height: 1.4,
    );

/// Numeric readouts — prices, totals, stock counts. Tabular figures stop the
/// line from reflowing while a value changes.
TextStyle kNumeric(double size,
        {Color? color, FontWeight fw = FontWeight.w600}) =>
    GoogleFonts.inter(
      fontSize: size,
      fontWeight: fw,
      color: color ?? kTextPrimary,
      height: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

// ── Gradients ───────────────────────────────────────────────────────────────
LinearGradient get kCyanGradient => LinearGradient(
      colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
LinearGradient get kVendorGradient => LinearGradient(
      colors: [AppColors.vendor, AppColors.vendorDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
LinearGradient get kRiderGradient => LinearGradient(
      colors: [AppColors.rider, AppColors.riderDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

// ── Decorations ─────────────────────────────────────────────────────────────
//
// Two decorations, both neutral. Removed from here:
//   kGlowDeco / kGlowCard — an accent-tinted border plus a coloured shadow on
//     every order tile, low-stock row and status hero. Status colour belongs
//     in the status pill, not in the card's own outline.
//   kGlassDeco — named "glass" but there is no BackdropFilter anywhere in the
//     app; it was a 0.92-alpha surface pretending to be translucency.

BoxDecoration kCardDeco({double radius = AppSpacing.rLg}) => BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kBorder),
      boxShadow: AppShadows.card,
    );

/// Recessed fill for search boxes and inline fields sitting on a card.
BoxDecoration kFieldDeco({double radius = AppSpacing.rMd}) => BoxDecoration(
      color: kField,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kBorderStrong),
    );

// ── Shared widgets ──────────────────────────────────────────────────────────

/// A status badge.
///
/// 12px is the default floor. Callers may override [fontSize] when space is constrained.
Widget kStatusPill(String label, Color color, {double fontSize = 12}) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.rSm + 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );

/// Section heading.
///
/// The 3px accent bar was removed: four screens had hand-rolled their own
/// variant at three different heights, and the bar was painted in the customer
/// accent even on vendor screens. Weight and size carry a heading on their own.
Widget kSectionHeader(String title, {Widget? trailing}) => Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
              height: 1.35,
            ),
          ),
        ),
        ?trailing,
      ],
    );

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return kWarning;
    case 'confirmed':
    case 'preparing':
      return kInfo;
    case 'ready':
    case 'delivered':
      return kSuccess;
    case 'dispatched':
      return kAccentText;
    case 'cancelled':
      return kError;
    default:
      return kTextMuted;
  }
}

String statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'confirmed':
      return 'Confirmed';
    case 'preparing':
      return 'Preparing';
    case 'ready':
      return 'Ready';
    case 'dispatched':
      return 'Dispatched';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

/// String emoji representation for backward compatibility.
String statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return '⏳';
    case 'confirmed':
      return '✅';
    case 'preparing':
      return '🔧';
    case 'ready':
      return '📦';
    case 'dispatched':
      return '🏍️';
    case 'delivered':
      return '✔️';
    case 'cancelled':
      return '❌';
    default:
      return '•';
  }
}

/// Real icons for order status.
///
/// Replaces a `statusIcon()` that returned emoji strings
/// ('⏳','✅','🔧','📦','🏍️','✔️','❌') interpolated straight into `Text`.
/// Emoji render differently on every platform, cannot be tinted to match the
/// status colour, ignore the app's text scale, and were shown at 42px as the
/// hero of the order-detail screen.
IconData statusIconData(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'confirmed':
      return Icons.check_rounded;
    case 'preparing':
      return Icons.handyman_rounded;
    case 'ready':
      return Icons.inventory_2_rounded;
    case 'dispatched':
      return Icons.delivery_dining_rounded;
    case 'delivered':
      return Icons.check_circle_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    default:
      return Icons.circle_outlined;
  }
}
