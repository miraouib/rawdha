import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème de l'application basé sur le guide UI/UX
/// 
/// Couleurs modernes avec dégradés, ombres douces, coins arrondis
class AppTheme {
  // Couleurs primaires
  static const Color primaryBlue = Color(0xFF5B8DEF);
  static const Color primaryPurple = Color(0xFF8B7FE8);
  
  // Couleurs d'accent
  static const Color accentTeal = Color(0xFF4ECDC4);
  static const Color accentGreen = Color(0xFF95E1D3);
  static const Color accentOrange = Color(0xFFFFB84D);
  static const Color accentYellow = Color(0xFFFFE66D);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentPurple = Color(0xFF9F7AEA);
  static const Color accentRed = Color(0xFFFF6B6B);
  
  // Couleurs neutres
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGray = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color borderColor = Color(0xFFE2E8F0);
  
  // Couleurs de statut
  static const Color successGreen = Color(0xFF48BB78);
  static const Color warningOrange = Color(0xFFED8936);
  static const Color errorRed = Color(0xFFF56565);
  static const Color infoBlue = Color(0xFF4299E1);

  /// Dégradé primaire (bleu → violet)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé pour les cartes de modules (bleu → teal)
  static const LinearGradient moduleGradient = LinearGradient(
    colors: [primaryBlue, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé pour l'accès parent (rose → violet)
  static const LinearGradient parentGradient = LinearGradient(
    colors: [accentPink, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Thème clair de l'application
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: primaryPurple,
      surface: backgroundWhite,
      background: backgroundLight,
      error: errorRed,
    ),
    
    // Typographie avec Google Fonts (Inter)
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textDark,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: textDark,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textGray,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Cartes
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor),
      ),
      color: backgroundWhite,
    ),
    
    // AppBar
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: backgroundWhite,
      foregroundColor: textDark,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
  );

  /// Ombre douce pour les cartes
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Ombre pour les cartes avec dégradé
  static List<BoxShadow> get gradientCardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
