import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  // Common theme properties
  static final _cardTheme = CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.rLg),
      side: const BorderSide(color: Colors.transparent, width: 0),
    ),
  );

  static TextTheme get _textTheme => TextTheme(
    displayLarge: AppTypography.display,
    headlineLarge: AppTypography.h1,
    headlineMedium: AppTypography.h2,
    titleLarge: AppTypography.title,
    bodyLarge: AppTypography.body,
    labelLarge: AppTypography.label,
    bodySmall: AppTypography.caption,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5A4ED1),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        primary: const Color(0xFF5A4ED1),
        secondary: const Color(0xFF7C3AED),
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F5),
      cardTheme: _cardTheme,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E5E3), thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1C1917)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1917),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFF5A4ED1).withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF5A4ED1));
          }
          return const IconThemeData(color: Color(0xFFA8A29E));
        }),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(const Color(0xFF5A4ED1), Colors.white),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C6EF6),
        brightness: Brightness.dark,
        surface: const Color(0xFF1C1C1E),
        primary: const Color(0xFF7C6EF6),
        secondary: const Color(0xFFA78BFA),
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: const Color(0xFF111113),
      cardTheme: _cardTheme,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2E), thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF5F5F4)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF5F5F4),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        indicatorColor: const Color(0xFF7C6EF6).withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF7C6EF6));
          }
          return const IconThemeData(color: Color(0xFF78716C));
        }),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(const Color(0xFF7C6EF6), Colors.white),
      inputDecorationTheme: _inputDecorationTheme(Brightness.dark),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg, Color fg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF7F7F5);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E3);
    final focusColor = isDark ? const Color(0xFF7C6EF6) : const Color(0xFF5A4ED1);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        borderSide: BorderSide(color: focusColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}
