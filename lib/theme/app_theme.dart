import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna dari desain Figma "florapulse".
class AppColors {
  static const background = Color(0xFFF1FDEE);
  static const primary = Color(0xFF154212);
  static const primarySoft = Color(0xFF2D5A27);
  static const onSurface = Color(0xFF141E15);
  static const onSurfaceVariant = Color(0xFF42493E);
  static const secondary = Color(0xFF3F683E);
  static const secondaryText = Color(0xFF436C42);
  static const container = Color(0xFFEBF7E8);
  static const containerHigh = Color(0xFFE5F1E3);
  static const containerHighest = Color(0xFFE0EBDD);
  static const containerDim = Color(0xFFDAE6D7);
  static const track = Color(0xFFE2EBE0);
  static const accent = Color(0xFFBDECB7);
  static const accentAlt = Color(0xFFBCF0AE);
  static const accentLight = Color(0xFFC0EFBA);
  static const white = Colors.white;
}

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1),
    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
}

/// Plus Jakarta Sans untuk judul/label, Inter untuk teks isi.
class AppText {
  static TextStyle jakarta(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.onSurface,
    double? height,
    double spacing = 0,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height == null ? null : height / size,
        letterSpacing: spacing,
        decoration: decoration,
        decorationColor: color,
      );

  static TextStyle inter(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.onSurfaceVariant,
    double? height,
    double spacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height == null ? null : height / size,
        letterSpacing: spacing,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
  );
}
