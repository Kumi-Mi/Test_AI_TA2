import 'package:flutter/material.dart';

/// Hallmark · pre-emit critique: P5 H4 E4 S5 R4 V4
/// Hallmark · genre: playful · macrostructure: Workbench · theme: Hum
/// enrichment: Tier A Flutter-painted character · nav: N7-inspired slab
abstract final class AppColors {
  static const paper = Color(0xFFFFF8E7);
  static const paperDeep = Color(0xFFF3ECD9);
  static const ink = Color(0xFF25262F);
  static const inkMuted = Color(0xFF5B5D66);
  static const rule = Color(0xFFD8D0BB);
  static const pear = Color(0xFFD8ED63);
  static const pearDeep = Color(0xFF9DAF32);
  static const cyan = Color(0xFF77D9E4);
  static const coral = Color(0xFFFF8175);
  static const lavender = Color(0xFFBBAAF5);
  static const mint = Color(0xFF8DD5AA);
  static const danger = Color(0xFFC5423C);
}

abstract final class AppSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
  static const xxl = 64.0;
}

abstract final class AppRadii {
  static const input = 12.0;
  static const card = 20.0;
  static const pill = 999.0;
}

ThemeData buildAppTheme() {
  final textTheme = ThemeData.light().textTheme
      .apply(
        fontFamily: 'Plus Jakarta Sans',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      )
      .copyWith(
        displaySmall: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 36,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          color: AppColors.ink,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 25,
          height: 1.16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          height: 1.55,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w400,
          color: AppColors.inkMuted,
        ),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.pearDeep,
      brightness: Brightness.light,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: const TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        backgroundColor: const WidgetStatePropertyAll(AppColors.ink),
        foregroundColor: const WidgetStatePropertyAll(AppColors.paper),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 52)),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.ink, width: 1.5),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.all(AppSpace.md),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      helperStyle: textTheme.bodyMedium,
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.ink),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.ink,
      inactiveTrackColor: AppColors.rule,
      thumbColor: AppColors.coral,
      overlayColor: Color(0x22FF8175),
    ),
  );
}
