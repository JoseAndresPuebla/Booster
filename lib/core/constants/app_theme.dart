import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main Palette
  static const Color background = Color(0xFF0C0E14);
  static const Color surface = Color(0xFF151824);
  static const Color surfaceLight = Color(0xFF1E2336);
  static const Color cardBorder = Color(0xFF2A314D);

  // TCG Brand Accents
  static const Color pokemonColor = Color(0xFFFFCB05);
  static const Color pokemonAccent = Color(0xFF2A75BB);

  static const Color magicColor = Color(0xFFE85D04);
  static const Color magicAccent = Color(0xFFF48C06);

  static const Color riftboundColor = Color(0xFF00E5FF);
  static const Color riftboundAccent = Color(0xFF00B0FF);

  static const Color onepieceColor = Color(0xFFFF1744);
  static const Color onepieceAccent = Color(0xFFD50000);

  // Rarity Colors
  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityUncommon = Color(0xFF26A69A);
  static const Color rarityRare = Color(0xFFFFB300);
  static const Color rarityUltraRare = Color(0xFFAB47BC);
  static const Color raritySecret = Color(0xFFFF4081);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: pokemonColor,
      cardColor: surface,
      fontFamily: GoogleFonts.outfit().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: const ColorScheme.dark(
        primary: pokemonColor,
        secondary: riftboundColor,
        surface: surface,
      ),
    );
  }
}
