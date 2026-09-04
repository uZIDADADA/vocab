import 'package:flutter/material.dart';

abstract final class VocabColors {
  static const ink = Color(0xFF171715);
  static const canvas = Color(0xFFFAF8F3);
  static const surface = Color(0xFFFFFEFA);
  static const softSurface = Color(0xFFF4F2ED);
  static const lime = Color(0xFFD8FA3F);
  static const limeSoft = Color(0xFFF1FFC0);
  static const coral = Color(0xFFFF7A5C);
  static const coralSoft = Color(0xFFFFE9DF);
  static const cyan = Color(0xFF59C9F3);
  static const cyanSoft = Color(0xFFE4F6FD);
  static const green = Color(0xFF42B84A);
  static const muted = Color(0xFF72726B);
  static const line = Color(0xFFE5E3DC);
}

abstract final class VocabTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: VocabColors.ink,
      onPrimary: Colors.white,
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
