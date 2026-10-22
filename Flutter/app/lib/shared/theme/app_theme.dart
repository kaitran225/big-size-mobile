import 'package:flutter/material.dart';

/// Shared design tokens for the storefront, checkout and account surfaces.
abstract final class AppColors {
  static const Color brand = Color(0xFF14432F);
  static const Color brandDark = Color(0xFF0C2B1D);
  static const Color brandSoft = Color(0xFFE7EFEA);
  static const Color accent = Color(0xFFC2703D);
  static const Color accentSoft = Color(0xFFFBEEE4);
  static const Color ink = Color(0xFF1B1D1A);
  static const Color inkMuted = Color(0xFF6B6F68);
  static const Color canvas = Color(0xFFFBFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color hairline = Color(0xFFE8E4DC);
  static const Color success = Color(0xFF1F7A4C);
  static const Color danger = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB26A00);
}

/// Shared layout tokens so spacing stays consistent across screens.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Shared corner radii used by cards, fields and buttons.
abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double pill = 999;
}

/// The application theme, tuned for a retail storefront rather than a form app.
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
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
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
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.hairline),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        labelStyle: const TextStyle(color: AppColors.inkMuted),
        floatingLabelStyle: const TextStyle(
          color: AppColors.brand,
          fontWeight: FontWeight.w600,
        ),
        border: _fieldBorder(AppColors.hairline),
        enabledBorder: _fieldBorder(AppColors.hairline),
        focusedBorder: _fieldBorder(AppColors.brand, width: 1.6),
        errorBorder: _fieldBorder(AppColors.danger),
        focusedErrorBorder: _fieldBorder(AppColors.danger, width: 1.6),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
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
                ? FontWeight.w700
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.inkMuted,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(color: AppColors.inkMuted, fontSize: 13),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.45, color: AppColors.ink),
    bodySmall: base.bodySmall?.copyWith(height: 1.4, color: AppColors.inkMuted),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
