/// Spacing and corner-radius scale.
///
/// Screens previously used 30+ distinct padding values and 16 distinct radii
/// (including off-scale 7, 13, 15 and 18), which is why identical cards looked
/// subtly different from one screen to the next. Snap to this scale.
class AppSpacing {
  AppSpacing._();

  // ── Margins / paddings ───────────────────────────────────────────────────
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// Standard horizontal page margin. Every scrollable screen uses this so
  /// content lines up across the app.
  static const double pageMargin = 20.0;

  // ── Radii ────────────────────────────────────────────────────────────────
  static const double rSm = 4.0;
  static const double rMd = 8.0;
  static const double rLg = 12.0;
  static const double rXl = 16.0;
  static const double rXxl = 24.0;

  /// For pills and circular controls.
  static const double rFull = 999.0;

  // ── Hit targets ──────────────────────────────────────────────────────────
  /// Platform minimum for an interactive control. Several controls in the app
  /// were 18-34px (chat copy button, image-remove, quantity steppers, back
  /// arrows); wrap those in a target of at least this size.
  static const double hitTarget = 48.0;

  /// Dense-list exception, matching Material's compact guidance. Only for
  /// secondary controls in a row that is itself >= [hitTarget] tall.
  static const double hitTargetCompact = 40.0;

  /// Height of a primary, full-width call to action.
  static const double controlHeight = 50.0;

  /// Height of a secondary or inline control.
  static const double controlHeightSm = 40.0;
}
