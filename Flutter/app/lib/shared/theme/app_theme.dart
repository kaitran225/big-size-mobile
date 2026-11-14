
import 'package:flutter/material.dart';

/// Shared design tokens for the BIGFIT streetwear storefront.
abstract final class AppColors {
  // Brand: minimalist black and white
  static const Color brand = Color(0xFF111111);
  static const Color brandDark = Color(0xFF000000);
  static const Color brandSoft = Color(0xFFF2F2F2);

  // Accent
  static const Color accent = Color(0xFF111111);
  static const Color accentSoft = Color(0xFFF5F5F5);

  // Text
  static const Color ink = Color(0xFF111111);
  static const Color inkMuted = Color(0xFF777777);

  // Background and borders
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE5E5E5);

  // Status colors
  static const Color success = Color(0xFF1F7A4C);
  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB26A00);

  /// Sale price and discount badge. Deliberately red so markdowns read at a glance.
  static const Color sale = Color(0xFFC62828);
}

/// Shared spacing tokens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Minimal corner radii for a streetwear design.
abstract final class AppRadii {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 8;
  static const double pill = 999;
}

/// Application theme.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.hairline,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.hairline),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.inkMuted,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.w700,
        ),
        border: _fieldBorder(AppColors.hairline),
        enabledBorder: _fieldBorder(AppColors.hairline),
        focusedBorder: _fieldBorder(AppColors.brand, width: 1.5),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(
          AppColors.danger,
          width: 1.5,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.brand,
        side: const BorderSide(color: AppColors.hairline),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandSoft,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.inkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.inkMuted,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkMuted,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: AppColors.inkMuted,
          fontSize: 13,
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: AppColors.ink,
      ),
      bodySmall: base.bodySmall?.copyWith(
        height: 1.4,
        color: AppColors.inkMuted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
