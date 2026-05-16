import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constant/app_colors.dart';

/// App theme built from @docs/DESIGN.md tokens.
/// Font: Inter (DESIGN.md single source of truth).
/// Touch targets: 48dp minimum (PRD §12.1).
/// Numerics: tabular-nums for all monetary displays.
class AppTheme {
  AppTheme._();

  // ── Spacing tokens (DESIGN.md §spacing) ──
  static const double spacingUnit = 8;
  static const double marginPage = 16;
  static const double gutter = 16;
  static const double touchTargetMin = 48;
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;

  // ── Shape tokens (DESIGN.md §rounded) ──
  static const double radiusSm = 2;
  static const double radiusDefault = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surfaceContainerLowest,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceTint: AppColors.surfaceTint,
      ),
      scaffoldBackgroundColor: AppColors.surfaceContainerLowest,
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(touchTargetMin, touchTargetMin),
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(touchTargetMin, touchTargetMin),
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(touchTargetMin, touchTargetMin),
        ),
      ),
      checkboxTheme: const CheckboxThemeData(
        splashRadius: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.all(marginPage),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(radiusDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(radiusDefault),
        ),
        labelStyle: textTheme.bodyMedium,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
        color: AppColors.surfaceContainerLowest,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: AppColors.cardBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        indicatorColor: AppColors.primaryFixed,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
      ),
    );
  }

  /// Build complete typography scale from DESIGN.md §typography.
  /// All sizes use Inter. Minimum body text = 16px.
  static TextTheme _buildTextTheme() {
    return TextTheme(
      // headline-lg: 28px / 700 / 36px line / -0.02em
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.56,
        color: AppColors.textPrimary,
      ),
      // headline-md: 24px / 700 / 32px / -0.01em
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.24,
        color: AppColors.textPrimary,
      ),
      // headline-sm: 20px / 600 / 28px
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.textPrimary,
      ),
      // body-lg: 18px / 400 / 26px
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 26 / 18,
        color: AppColors.textPrimary,
      ),
      // body-md: 16px / 400 / 24px (minimum body size)
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.textPrimary,
      ),
      // label-lg: 16px / 600 / 20px / 0.01em
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 20 / 16,
        letterSpacing: 0.16,
        color: AppColors.textPrimary,
      ),
      // label-md: 14px / 500 / 18px / 0.02em
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 18 / 14,
        letterSpacing: 0.28,
        color: AppColors.textPrimary,
      ),
      // Numeric display — tabular-nums (PRD §12.7)
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
