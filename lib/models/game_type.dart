import 'package:flutter/material.dart';
import '../core/constants/app_theme.dart';

enum GameType {
  pokemon('pokemon', 'Pokémon TCG', 'Pókemon Pocket Edition', AppTheme.pokemonColor),
  magic('magic', 'Magic: The Gathering', 'Multiverse Booster Packs', AppTheme.magicColor),
  riftbound('riftbound', 'Riftbound TCG', 'Runeterra Universe Battles', AppTheme.riftboundColor),
  onepiece('onepiece', 'One Piece Card Game', 'Grand Line Booster Series', AppTheme.onepieceColor),
  wwe('wwe', 'WWE Trading Cards', 'Topps & Panini Superstars', AppTheme.wweColor);

  final String key;
  final String title;
  final String subtitle;
  final Color primaryColor;

  const GameType(this.key, this.title, this.subtitle, this.primaryColor);

  static GameType fromKey(String key) {
    return GameType.values.firstWhere(
      (e) => e.key == key.toLowerCase(),
      orElse: () => GameType.pokemon,
    );
  }

  // URLs for default high-res card backs
  String get defaultCardBackUrl {
    switch (this) {
      case GameType.pokemon:
        return 'https://images.pokemontcg.io/back.png';
      case GameType.magic:
        return 'https://cards.scryfall.io/back.png';
      case GameType.onepiece:
        return 'https://onepiece-cardgame.dev/images/card-back.png';
      case GameType.riftbound:
        return 'https://www.riftbound-db.com/images/card-back.png';
      case GameType.wwe:
        return '';
    }
  }
}
