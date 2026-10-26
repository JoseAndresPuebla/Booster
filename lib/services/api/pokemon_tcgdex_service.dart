import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class PokemonTcgDexService {
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};

  static Future<List<CardSet>> getPopularSets() async {
    return const [
      CardSet(
        id: 'me',
        code: 'sv03.5',
        name: 'Pokémon 151 (Scarlet & Violet)',
        gameType: GameType.pokemon,
        totalCards: 165,
        releaseDate: '2023-09-22',
        boosterArtUrl:
            'https://assets.tcgdex.net/en/sv/sv03.5/logo.webp',
      ),
      CardSet(
        id: 'surging',
        code: 'sv08',
        name: 'Surging Sparks',
        gameType: GameType.pokemon,
        totalCards: 191,
        releaseDate: '2024-11-08',
        boosterArtUrl:
            'https://assets.tcgdex.net/en/sv/sv08/logo.webp',
      ),
      CardSet(
        id: 'zenith',
        code: 'swsh12.5',
        name: 'Crown Zenith',
        gameType: GameType.pokemon,
        totalCards: 160,
        releaseDate: '2023-01-20',
        boosterArtUrl:
            'https://assets.tcgdex.net/en/swsh/swsh12.5/logo.webp',
      ),
      CardSet(
        id: 'base1',
        code: 'base1',
        name: 'Classic Base Set (1999)',
        gameType: GameType.pokemon,
        totalCards: 102,
        releaseDate: '1999-01-09',
        boosterArtUrl:
            'https://assets.tcgdex.net/en/base/base1/logo.webp',
      ),
    ];
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    if (_cachedCardsBySet.containsKey(setCode) &&
        _cachedCardsBySet[setCode]!.isNotEmpty) {
      return _cachedCardsBySet[setCode]!;
    }

    try {
      final url = Uri.parse('${ApiConstants.tcgdexBaseUrl}/sets/$setCode');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cardsList = data['cards'] as List<dynamic>? ?? [];

        final cards = cardsList.map((item) {
          final localId = item['localId']?.toString() ?? '1';
          final cardId = item['id']?.toString() ?? '$setCode-$localId';
          final name = item['name'] as String? ?? 'Pokémon';
          final imageBase = item['image'] as String?;

          final imgUrl = imageBase != null
              ? '$imageBase/high.webp'
              : GameType.pokemon.defaultCardBackUrl;

          // Estimate rarity
          Rarity rarity = Rarity.common;
          final int numId = int.tryParse(localId) ?? 50;
          if (numId > 165) {
            rarity = Rarity.secretRare;
          } else if (numId > 140) {
            rarity = Rarity.ultraRare;
          } else if (numId > 100) {
            rarity = Rarity.rare;
          } else if (numId > 50) {
            rarity = Rarity.uncommon;
          }

          return CardModel(
            id: 'pkm_$cardId',
            name: name,
            gameType: GameType.pokemon,
            setCode: setCode,
            setName: data['name'] as String? ?? setCode,
            cardNumber: localId,
            rarity: rarity,
            imageUrl: imgUrl,
            imageHighResUrl: imgUrl,
            foilType: rarity.tier >= 3 ? 'holo' : 'none',
          );
        }).toList();

        _cachedCardsBySet[setCode] = cards;
        return cards;
      }
    } catch (e) {
      debugPrint('Error fetching Pokémon cards: $e');
    }

    return _getFallbackPokemonCards(setCode);
  }

  static List<CardModel> _getFallbackPokemonCards(String setCode) {
    return [
      CardModel(
        id: 'pkm_flb_charizard',
        name: 'Charizard EX',
        gameType: GameType.pokemon,
        setCode: setCode,
        setName: 'Pokémon 151',
        cardNumber: '006',
        rarity: Rarity.secretRare,
        imageUrl:
            'https://assets.tcgdex.net/en/sv/sv03.5/006/high.webp',
        foilType: 'rainbow',
      ),
      CardModel(
        id: 'pkm_flb_pikachu',
        name: 'Pikachu',
        gameType: GameType.pokemon,
        setCode: setCode,
        setName: 'Pokémon 151',
        cardNumber: '025',
        rarity: Rarity.rare,
        imageUrl:
            'https://assets.tcgdex.net/en/sv/sv03.5/025/high.webp',
        foilType: 'holo',
      ),
      CardModel(
        id: 'pkm_flb_mew',
        name: 'Mew EX',
        gameType: GameType.pokemon,
        setCode: setCode,
        setName: 'Pokémon 151',
        cardNumber: '151',
        rarity: Rarity.ultraRare,
        imageUrl:
            'https://assets.tcgdex.net/en/sv/sv03.5/151/high.webp',
        foilType: 'holo',
      ),
      CardModel(
        id: 'pkm_flb_squirtle',
        name: 'Squirtle',
        gameType: GameType.pokemon,
        setCode: setCode,
        setName: 'Pokémon 151',
        cardNumber: '007',
        rarity: Rarity.common,
        imageUrl:
            'https://assets.tcgdex.net/en/sv/sv03.5/007/high.webp',
      ),
    ];
  }
}
