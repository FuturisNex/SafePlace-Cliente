import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Cores
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  
  static const Color background = Color(0xFFF8F9FB); // Off-white suave
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF1A1A1A); // Preto suave
  static const Color textSecondary = Color(0xFF757575);

  static ThemeData get lightTheme {
    return lightThemeWithPrimary(primaryGreen);
  }

  static ThemeData lightThemeWithPrimary(Color primaryColor) {
    final secondaryColor = _shiftLightness(primaryColor, 0.14);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surface,
        background: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ).copyWith(
        surfaceTint: Colors.transparent,
      ),
      canvasColor: background,
      dialogBackgroundColor: surface,
      
      // Tipografia Moderna
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32,
        ),
        displayMedium: GoogleFonts.poppins(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28,
        ),
        displaySmall: GoogleFonts.poppins(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary, fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary, fontSize: 14,
        ),
      ),

      // Cards Modernos (Arredondados e com Sombra Suave)
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Inputs Modernos
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),

      // Botões Elevados (Pill Shape)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100), // Pill shape
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      // Botões Outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),

      // AppBar Limpa
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
