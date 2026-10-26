import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class PokemonTcgDexService {
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};
  static List<CardSet>? _cachedSets;

  /// Fetches ALL official Pokémon TCG sets dynamically from TcgDex
  static Future<List<CardSet>> getAllSets() async {
    if (_cachedSets != null && _cachedSets!.isNotEmpty) {
      return _cachedSets!;
    }

    try {
      final res = await http.get(Uri.parse('${ApiConstants.tcgdexBaseUrl}/sets'));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>? ?? [];

        final sets = list
            .where((item) {
              final countMap = item['cardCount'] as Map<String, dynamic>?;
              final total = countMap?['total'] as int? ?? 0;
              // Ignore promo single cards or miscellaneous sets
              return total >= 30;
            })
            .map((item) {
              final id = item['id'] as String;
              final name = item['name'] as String;
              final countMap = item['cardCount'] as Map<String, dynamic>?;
              final total = countMap?['total'] as int? ?? 0;
              final logo = item['logo'] as String?;

              return CardSet(
                id: 'pkm_$id',
                code: id,
                name: name,
                gameType: GameType.pokemon,
                totalCards: total,
                iconUrl: logo != null ? '$logo.webp' : null,
              );
            })
            .toList();

        // Reverse to show newest sets first
        final reversed = sets.reversed.toList();
        _cachedSets = reversed;
        return reversed;
      }
    } catch (e) {
      debugPrint('Error fetching Pokemon sets from TcgDex: $e');
    }

    return getFallbackSets();
  }

  static List<CardSet> getFallbackSets() {
    return const [
      CardSet(
        id: 'me',
        code: 'sv03.5',
        name: 'Pokémon 151 (Scarlet & Violet)',
        gameType: GameType.pokemon,
        totalCards: 165,
        releaseDate: '2023-09-22',
      ),
      CardSet(
        id: 'surging',
        code: 'sv08',
        name: 'Surging Sparks',
        gameType: GameType.pokemon,
        totalCards: 191,
        releaseDate: '2024-11-08',
      ),
      CardSet(
        id: 'zenith',
        code: 'swsh12.5',
        name: 'Crown Zenith',
        gameType: GameType.pokemon,
        totalCards: 160,
        releaseDate: '2023-01-20',
      ),
      CardSet(
        id: 'base1',
        code: 'base1',
        name: 'Classic Base Set (1999)',
        gameType: GameType.pokemon,
        totalCards: 102,
        releaseDate: '1999-01-09',
      ),
    ];
  }

  /// Fetches real cards for the chosen set using TcgDex API
  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    final cleanCode = setCode.toLowerCase().trim();

    if (_cachedCardsBySet.containsKey(cleanCode) &&
        _cachedCardsBySet[cleanCode]!.isNotEmpty) {
      return _cachedCardsBySet[cleanCode]!;
    }

    try {
      final url = Uri.parse('${ApiConstants.tcgdexBaseUrl}/sets/$cleanCode');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cardsList = data['cards'] as List<dynamic>? ?? [];

        final cards = <CardModel>[];

        for (final item in cardsList) {
          final localId = item['localId']?.toString() ?? '1';
          final cardId = item['id']?.toString() ?? '$cleanCode-$localId';
          final name = item['name'] as String? ?? 'Pokémon';
          final imageBase = item['image'] as String?;

          if (imageBase == null) continue;

          final imgUrl = '$imageBase/high.webp';

          // Estimate rarity
          Rarity rarity = Rarity.common;
          final int numId = int.tryParse(localId) ?? 50;
          if (numId > 165) {
            rarity = Rarity.secretRare;
          } else if (numId > 135) {
            rarity = Rarity.ultraRare;
          } else if (numId > 90) {
            rarity = Rarity.rare;
          } else if (numId > 45) {
            rarity = Rarity.uncommon;
          }

          cards.add(CardModel(
            id: 'pkm_$cardId',
            name: name,
            gameType: GameType.pokemon,
            setCode: cleanCode,
            setName: data['name'] as String? ?? cleanCode,
            cardNumber: localId,
            rarity: rarity,
            imageUrl: imgUrl,
            imageHighResUrl: imgUrl,
            foilType: rarity.tier >= 3 ? 'holo' : 'none',
          ));
        }

        if (cards.isNotEmpty) {
          _cachedCardsBySet[cleanCode] = cards;
          return cards;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Pokémon cards: $e');
    }

    return [];
  }
}
