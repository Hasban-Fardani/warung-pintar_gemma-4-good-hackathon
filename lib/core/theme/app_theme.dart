
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF005DAC),
        onPrimary: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF), 
        onSurface: Color(0xFF1A1A1A),
        error: Color(0xFFC62828),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodyMedium: GoogleFonts.inter(
          fontSize: 16, 
          height: 1.5, 
          color: const Color(0xFF1A1A1A)
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16, 
          fontWeight: FontWeight.w600
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48), // 48dp touch targets
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48), // 48dp touch targets
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        splashRadius: 24, // Touch target 48
      ),
    );
  }
}
