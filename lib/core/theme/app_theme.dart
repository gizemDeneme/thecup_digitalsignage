import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// thecup brand renk paleti.
/// Krem & kraft kahve — kafe estetiği.
class AppColors {
  static const ink = Color(0xFF111111);       // ana metin / koyu
  static const ink2 = Color(0xFF2A2A2A);      // ikinci koyu
  static const paper = Color(0xFFF4EEE4);     // ana arka plan (krem)
  static const paper2 = Color(0xFFEDE5D6);    // yüzey (koyu krem)
  static const kraft = Color(0xFF8B6F52);     // accent (kraft kahve)
  static const kraft2 = Color(0xFF6B5640);    // accent koyu
  static const line = Color(0xFF1A1A1A);      // çizgi/border
  static const muted = Color(0xFF7A7366);     // pasif metin
  static const white = Color(0xFFFFFFFF);
  static const danger = Color(0xFFB54B4B);    // hata/sil
  static const success = Color(0xFF4A7C4E);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.kraft,
        onPrimary: AppColors.white,
        secondary: AppColors.kraft2,
        onSecondary: AppColors.white,
        surface: AppColors.paper2,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunitoSans(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.muted,
          disabledForegroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.nunitoSans(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.nunitoSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.kraft2,
          textStyle: GoogleFonts.nunitoSans(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: AppColors.line.withValues(alpha: 0.4), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.kraft, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.line.withValues(alpha: 0.08)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.muted,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.ink, width: 2),
        ),
        labelStyle: GoogleFonts.nunitoSans(
            fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunitoSans(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: AppColors.paper),
      ),
    );
  }
}
