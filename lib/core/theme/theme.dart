import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Design Tokens
  static const primaryIndigo = Color(0xFF4F46E5);
  static const primaryViolet = Color(0xFF7C3AED);
  static const background = Color(0xFFF7F8FB);
  static const cardBg = Color(0xFFFFFFFF);

  static const statusPaid = Color(0xFF059669);
  static const statusIssued = Color(0xFF4F46E5);
  static const statusOverdue = Color(0xFFDC2626);
  static const statusAccepted = Color(0xFF10B981);
  static const statusConverted = Color(0xFF6366F1);
  static const statusCancelled = Color(0xFF94A3B8);

  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF94A3B8);

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primaryIndigo, primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
    transform: GradientRotation(135 * 3.14159 / 180),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: GoogleFonts.nunito(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.nunito(color: textPrimary),
        bodyMedium: GoogleFonts.nunito(color: textSecondary),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIndigo,
        secondary: primaryViolet,
        surface: cardBg,
        onSurface: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0, // Flat design with subtle border or shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Dark theme follows same logic but with darker background if needed,
  // but for this specific design request we focus on the light/premium version.
  static ThemeData get darkTheme => lightTheme;
}
