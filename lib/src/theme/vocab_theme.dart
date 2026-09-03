import 'package:flutter/material.dart';

abstract final class VocabColors {
  static const ink = Color(0xFF171715);
  static const canvas = Color(0xFFF7F3EC);
  static const surface = Color(0xFFFFFCF7);
  static const cream = Color(0xFFF5EFE3);
  static const coral = Color(0xFFFF7358);
  static const muted = Color(0xFF74746C);
  static const line = Color(0xFFE7E5DD);
}

abstract final class VocabTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: VocabColors.coral,
          brightness: Brightness.light,
          surface: VocabColors.surface,
        ).copyWith(
          primary: VocabColors.ink,
          onPrimary: Colors.white,
          secondary: VocabColors.coral,
          onSecondary: Colors.white,
          surface: VocabColors.surface,
          onSurface: VocabColors.ink,
          outline: VocabColors.line,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: VocabColors.canvas,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: VocabColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: VocabColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: VocabColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: VocabColors.muted,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: VocabColors.surface,
        indicatorColor: VocabColors.cream,
        elevation: 0,
        height: 70,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
