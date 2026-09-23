import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material theme for OmniDrive.
///
/// Both brightnesses are registered and [MaterialApp.themeMode] is
/// `ThemeMode.system`, so [AppColors.isDark] — which reads the platform
/// brightness — always agrees with the active [ThemeData]. Previously only the
/// dark theme was registered while [AppColors] still switched on platform
/// brightness, so a phone set to Light rendered light-coloured inputs on a
/// light background (1.07:1) inside a dark theme: the fields had no visible
/// boundary at all.
///
/// Inputs fill with [AppColors.field], a recessed step below [AppColors.surface],
/// and outline with [AppColors.borderStrong]. Colour is never the only signal —
/// focus and error states change the border weight as well.
class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme => TextTheme(
        displayLarge: AppTypography.display,
        displayMedium: AppTypography.h1,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h2,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        labelLarge: AppTypography.label,
        labelMedium: AppTypography.label,
        bodySmall: AppTypography.caption,
        labelSmall: AppTypography.caption,
      );

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF6C63E8) : const Color(0xFF4B44C4),
      brightness: brightness,
    ).copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentSoft,
      onPrimaryContainer: AppColors.accentText,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      error: AppColors.errorFill,
      onError: AppColors.onStatus,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.field,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: _textTheme,
      splashFactory: InkRipple.splashFactory,

      // M3 tints surfaces with the primary colour when content scrolls under
      // them, which reads as an unexplained purple wash. Opt out globally.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: AppTypography.title,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // A visible indicator colour is what tells the user which tab is active.
      // The label style change alone was doing all the work before.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accentSoft,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleInter.label(
            color: selected ? AppColors.accentText : AppColors.textMuted,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentText : AppColors.textMuted,
            size: 22,
          );
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.38),
          disabledForegroundColor: AppColors.onAccent.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: const Size(0, AppSpacing.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: GoogleInter.label(
            color: AppColors.onAccent,
            weight: FontWeight.w600,
            size: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
          ),
        ),
      ),

      // Outlined and text buttons were previously hand-rolled as
      // `Container` + `GestureDetector` in every screen, which is why none of
      // them had a focus ring, an ink response, a disabled state or a
      // `Semantics(button: true)` node.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(0, AppSpacing.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: GoogleInter.label(
            color: AppColors.textPrimary,
            weight: FontWeight.w600,
            size: 15,
          ),
          side: BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentText,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(0, AppSpacing.hitTargetCompact),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          textStyle: GoogleInter.label(
            color: AppColors.accentText,
            weight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rMd),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(
            AppSpacing.hitTargetCompact,
            AppSpacing.hitTargetCompact,
          ),
        ),
      ),

      inputDecorationTheme: _inputDecorationTheme(),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rLg),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.field,
        selectedColor: AppColors.accentSoft,
        disabledColor: AppColors.field,
        labelStyle: GoogleInter.label(color: AppColors.textSecondary),
        secondaryLabelStyle: GoogleInter.label(color: AppColors.accentText),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF232329)
            : const Color(0xFF26262C),
        contentTextStyle: GoogleInter.body(color: Colors.white),
        actionTextColor: AppColors.accentText,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: isDark ? 0.7 : 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.rXl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rXl),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accentText,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleInter.label(
          color: AppColors.accentText,
          weight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleInter.label(color: AppColors.textMuted),
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.border,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.field,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: AppColors.surface,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.field,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.borderStrong),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A31) : const Color(0xFF26262C),
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
        ),
        textStyle: GoogleInter.caption(color: Colors.white),
        waitDuration: const Duration(milliseconds: 400),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTypography.title,
        subtitleTextStyle: AppTypography.caption,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
      ),

      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static InputDecorationTheme _inputDecorationTheme() {
    final radius = BorderRadius.circular(AppSpacing.rMd);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      hintStyle: GoogleInter.body(color: AppColors.textMuted),
      labelStyle: GoogleInter.label(color: AppColors.textSecondary),
      floatingLabelStyle: GoogleInter.label(
        color: AppColors.accentText,
        weight: FontWeight.w600,
      ),
      helperStyle: GoogleInter.caption(color: AppColors.textMuted),
      errorStyle: GoogleInter.caption(color: AppColors.error),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      isDense: true,
      border: border(AppColors.borderStrong),
      enabledBorder: border(AppColors.borderStrong),
      focusedBorder: border(AppColors.accent, 1.5),
      errorBorder: border(AppColors.errorFill),
      focusedErrorBorder: border(AppColors.errorFill, 1.5),
      disabledBorder: border(AppColors.border),
    );
  }
}

/// Inter text styles for theme-level use, where a full [AppTypography] step
/// would be too opinionated about colour.
class GoogleInter {
  GoogleInter._();

  static TextStyle label({
    Color? color,
    FontWeight weight = FontWeight.w500,
    double size = 13,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );
}
