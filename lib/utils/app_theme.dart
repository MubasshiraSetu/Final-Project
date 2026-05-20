import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(AppColors.backgroundDark),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.primaryViolet),
        secondary: Color(AppColors.primaryGold),
        surface: Color(AppColors.backgroundCard),
        error: Color(AppColors.errorRed),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: const Color(AppColors.textPrimary),
        displayColor: const Color(AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(AppColors.backgroundCard),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A3A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(AppColors.primaryViolet), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(AppColors.errorRed), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(AppColors.errorRed), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
            color: Color(AppColors.textSecondary), fontSize: 14),
        labelStyle:
            const TextStyle(color: Color(AppColors.textSecondary)),
        prefixIconColor: const Color(AppColors.textSecondary),
        suffixIconColor: const Color(AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primaryViolet),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
     cardTheme: const CardThemeData(
  color: Color(AppColors.backgroundCard),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  ),
  elevation: 0,
  margin: EdgeInsets.zero,
),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppColors.backgroundDark),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: const Color(AppColors.textPrimary),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme:
            const IconThemeData(color: Color(AppColors.textPrimary)),
      ),
      dividerColor: const Color(0xFF2A2A3A),
      useMaterial3: true,
    );
  }
}
