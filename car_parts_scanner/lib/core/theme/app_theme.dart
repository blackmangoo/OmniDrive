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

  static final _textTheme = TextTheme(
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
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        primary: const Color(0xFF2563EB),
        secondary: const Color(0xFF6366F1),
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      cardTheme: _cardTheme,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF111827)),
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF2563EB));
          }
          return const IconThemeData(color: Color(0xFF9CA3AF));
        }),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(const Color(0xFF2563EB), Colors.white),
      inputDecorationTheme: _inputDecorationTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E2C),
        primary: const Color(0xFF3B82F6),
        secondary: const Color(0xFF8B5CF6),
        error: const Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: const Color(0xFF12121A),
      cardTheme: _cardTheme,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2A3C), thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF9FAFB),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E2C),
        indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF3B82F6));
          }
          return const IconThemeData(color: Color(0xFF6B7280));
        }),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(const Color(0xFF3B82F6), Colors.white),
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
    final fillColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF3F4F6);
    final borderColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE5E7EB);
    final focusColor = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
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
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
