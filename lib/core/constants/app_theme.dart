import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tactile Neo-Glass Vault Base Palette
  static const Color background = Color(0xFF0C0E16);
  static const Color surface = Color(0xFF11131B);
  static const Color surfaceContainerLowest = Color(0xFF0C0E16);
  static const Color surfaceContainerLow = Color(0xFF191B24);
  static const Color surfaceContainer = Color(0xFF1D1F28);
  static const Color surfaceContainerHigh = Color(0xFF282A32);
  static const Color surfaceContainerHighest = Color(0xFF33343E);
  static const Color cardBorder = Color(0xFF25293A);
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white hairline
  static const Color textPrimary = Color(0xFFE2E1EE);
  static const Color textSecondary = Color(0xFFBAC9CC);
  static const Color textMuted = Color(0xFF6B7280);

  // TCG Franchise Dynamic Accents
  static const Color pokemonColor = Color(0xFFFFCB05);
  static const Color pokemonAccent = Color(0xFF00E5FF);

  static const Color magicColor = Color(0xFFFF6F00);
  static const Color magicAccent = Color(0xFFD4AF37);

  static const Color onepieceColor = Color(0xFFD32F2F);
  static const Color onepieceAccent = Color(0xFF0D47A1);

  static const Color riftboundColor = Color(0xFF7B1FA2);
  static const Color riftboundAccent = Color(0xFFE040FB);

  static const Color wweColor = Color(0xFFFFD700);
  static const Color wweAccent = Color(0xFFB71C1C);

  // Rarity Colors
  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityUncommon = Color(0xFF26A69A);
  static const Color rarityRare = Color(0xFF00E5FF);
  static const Color rarityUltraRare = Color(0xFFFFB300);
  static const Color raritySecret = Color(0xFFFF4081);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: pokemonColor,
      cardColor: surfaceContainer,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: pokemonColor,
        secondary: pokemonAccent,
        surface: surface,
      ),
    );
  }
}
