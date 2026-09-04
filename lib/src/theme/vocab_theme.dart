import 'package:flutter/material.dart';

abstract final class VocabColors {
  static const ink = Color(0xFF20221F);
  static const canvas = Color(0xFFF7F8F6);
  static const surface = Color(0xFFFDFEFC);
  static const softSurface = Color(0xFFF0F2EF);
  static const lime = Color(0xFFCBE39D);
  static const limeSoft = Color(0xFFF0F5E7);
  static const coral = Color(0xFFE58A76);
  static const coralSoft = Color(0xFFF8ECE8);
  static const coralInk = Color(0xFF8A4B3E);
  static const cyan = Color(0xFF79B8C8);
  static const cyanSoft = Color(0xFFEAF3F5);
  static const green = Color(0xFF67A773);
  static const muted = Color(0xFF71766F);
  static const line = Color(0xFFE1E5E0);
}

abstract final class VocabTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: VocabColors.ink,
      onPrimary: VocabColors.surface,
      secondary: VocabColors.lime,
      onSecondary: VocabColors.ink,
      tertiary: VocabColors.coral,
      surface: VocabColors.surface,
      onSurface: VocabColors.ink,
      outline: VocabColors.line,
      surfaceContainerHighest: VocabColors.softSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: VocabColors.canvas,
      fontFamilyFallback: const [
        'Noto Sans SC',
        'Noto Sans CJK SC',
        'Roboto',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
          color: VocabColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          height: 1.15,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: VocabColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.25,
          color: VocabColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: VocabColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: VocabColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: VocabColors.muted,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: VocabColors.ink,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: VocabColors.line,
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: VocabColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: VocabColors.line),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: VocabColors.surface,
        indicatorColor: VocabColors.lime,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VocabColors.surface,
        hintStyle: const TextStyle(color: VocabColors.muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: VocabColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: VocabColors.ink, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
