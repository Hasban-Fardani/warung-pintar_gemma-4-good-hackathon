import 'dart:ui';

/// Design tokens — Color palette.
/// Source: @docs/DESIGN.md (single source of truth for visual tokens).
/// Business state colors from PRD §12.7 where WCAG-validated.
class AppColors {
  AppColors._();

  // ── Surface System (DESIGN.md) ──
  static const Color surface = Color(0xFFFCF9F8);
  static const Color surfaceDim = Color(0xFFDCD9D9);
  static const Color surfaceBright = Color(0xFFFCF9F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceContainerHigh = Color(0xFFEAE7E7);
  static const Color surfaceContainerHighest = Color(0xFFE5E2E1);
  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color onSurfaceVariant = Color(0xFF414752);
  static const Color inverseSurface = Color(0xFF313030);
  static const Color inverseOnSurface = Color(0xFFF3F0EF);
  static const Color surfaceVariant = Color(0xFFE5E2E1);

  // ── Primary (DESIGN.md) ──
  static const Color primary = Color(0xFF005DAC);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1976D2);
  static const Color onPrimaryContainer = Color(0xFFFFFDFF);
  static const Color inversePrimary = Color(0xFFA5C8FF);
  static const Color surfaceTint = Color(0xFF005FAF);

  // ── Secondary (DESIGN.md) ──
  static const Color secondary = Color(0xFF1B6D24);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA0F399);
  static const Color onSecondaryContainer = Color(0xFF217128);

  // ── Tertiary (DESIGN.md) ──
  static const Color tertiary = Color(0xFF9A4300);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFC05600);
  static const Color onTertiaryContainer = Color(0xFFFFFDFF);

  // ── Error (DESIGN.md) ──
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Fixed Colors (DESIGN.md) ──
  static const Color primaryFixed = Color(0xFFD4E3FF);
  static const Color primaryFixedDim = Color(0xFFA5C8FF);
  static const Color onPrimaryFixed = Color(0xFF001C3A);
  static const Color onPrimaryFixedVariant = Color(0xFF004786);
  static const Color secondaryFixed = Color(0xFFA3F69C);
  static const Color secondaryFixedDim = Color(0xFF88D982);
  static const Color onSecondaryFixed = Color(0xFF002204);
  static const Color onSecondaryFixedVariant = Color(0xFF005312);
  static const Color tertiaryFixed = Color(0xFFFFDBCA);
  static const Color tertiaryFixedDim = Color(0xFFFFB68F);
  static const Color onTertiaryFixed = Color(0xFF331200);
  static const Color onTertiaryFixedVariant = Color(0xFF773200);

  // ── Outline (DESIGN.md) ──
  static const Color outline = Color(0xFF717783);
  static const Color outlineVariant = Color(0xFFC1C6D4);

  // ── Background (DESIGN.md) ──
  static const Color background = Color(0xFFFCF9F8);
  static const Color onBackground = Color(0xFF1C1B1B);

  // ── Structural (DESIGN.md §Elevation) ──
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // ── Business State Colors (PRD §12.7 — WCAG validated) ──
  static const Color confirmed = Color(0xFF059669);
  static const Color pendingText = Color(0xFFBA7517);
  static const Color pendingBackground = Color(0xFFFAEEDA);
  static const Color errorState = Color(0xFFDC2626);

  // ── Typography Color (DESIGN.md §Colors) ──
  static const Color textPrimary = Color(0xFF1A1A1A);
}
