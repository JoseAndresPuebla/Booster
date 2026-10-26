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

  // Official booster pack wrapper artworks from TCGPlayer CDN
  static const Map<String, String> _officialBoosterArts = {
    'sv08': 'https://product-images.tcgplayer.com/fit-in/437x437/566420.jpg', // Surging Sparks
    'sv07': 'https://product-images.tcgplayer.com/fit-in/437x437/554743.jpg', // Stellar Crown
    'sv06': 'https://product-images.tcgplayer.com/fit-in/437x437/543329.jpg', // Twilight Masquerade
    'sv05': 'https://product-images.tcgplayer.com/fit-in/437x437/536332.jpg', // Temporal Forces
    'sv04.5': 'https://product-images.tcgplayer.com/fit-in/437x437/531393.jpg', // Paldean Fates
    'sv03.5': 'https://product-images.tcgplayer.com/fit-in/437x437/501309.jpg', // 151
    'sv03': 'https://product-images.tcgplayer.com/fit-in/437x437/497532.jpg', // Obsidian Flames
    'sv02': 'https://product-images.tcgplayer.com/fit-in/437x437/485304.jpg', // Paldea Evolved
    'sv01': 'https://product-images.tcgplayer.com/fit-in/437x437/476839.jpg', // Scarlet & Violet Base
    'swsh12.5': 'https://product-images.tcgplayer.com/fit-in/437x437/452906.jpg', // Crown Zenith
    'swsh12': 'https://product-images.tcgplayer.com/fit-in/437x437/285324.jpg', // Silver Tempest
    'swsh11': 'https://product-images.tcgplayer.com/fit-in/437x437/276997.jpg', // Lost Origin
    'swsh09': 'https://product-images.tcgplayer.com/fit-in/437x437/260386.jpg', // Brilliant Stars
    'swsh07': 'https://product-images.tcgplayer.com/fit-in/437x437/242436.jpg', // Evolving Skies
    'base1': 'https://product-images.tcgplayer.com/fit-in/437x437/42382.jpg', // Base Set (1999)
  };

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
              final id = (item['id'] as String? ?? '').toLowerCase();
              final countMap = item['cardCount'] as Map<String, dynamic>?;
              final total = countMap?['total'] as int? ?? 0;
              // Ignore empty sets, known broken sets (e.g. 30th-c has 0 images), or single promos
              if (id == '30th-c' || id.contains('demo')) return false;
              return total >= 30;
            })
            .map((item) {
              final id = item['id'] as String;
              final name = item['name'] as String;
              final countMap = item['cardCount'] as Map<String, dynamic>?;
              final total = countMap?['total'] as int? ?? 0;
              final logo = item['logo'] as String?;

              final cleanId = id.toLowerCase();
              final boosterArt = _officialBoosterArts[cleanId];

              return CardSet(
                id: 'pkm_$id',
                code: id,
                name: name,
                gameType: GameType.pokemon,
                totalCards: total,
                iconUrl: logo != null ? '$logo.webp' : null,
                boosterArtUrl: boosterArt ?? (logo != null ? '$logo.webp' : null),
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
        id: 'sv08',
        code: 'sv08',
        name: 'Surging Sparks',
        gameType: GameType.pokemon,
        totalCards: 191,
        releaseDate: '2024-11-08',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/566420.jpg',
      ),
      CardSet(
        id: 'me',
        code: 'sv03.5',
        name: 'Pokémon 151 (Scarlet & Violet)',
        gameType: GameType.pokemon,
        totalCards: 165,
        releaseDate: '2023-09-22',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/501309.jpg',
      ),
      CardSet(
        id: 'zenith',
        code: 'swsh12.5',
        name: 'Crown Zenith',
        gameType: GameType.pokemon,
        totalCards: 160,
        releaseDate: '2023-01-20',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/452906.jpg',
      ),
      CardSet(
        id: 'base1',
        code: 'base1',
        name: 'Classic Base Set (1999)',
        gameType: GameType.pokemon,
        totalCards: 102,
        releaseDate: '1999-01-09',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/42382.jpg',
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

        final countMap = data['cardCount'] as Map<String, dynamic>?;
        final int officialCount = countMap?['official'] as int? ??
            countMap?['total'] as int? ??
            cardsList.length;

        final cards = <CardModel>[];

        for (final item in cardsList) {
          final localId = item['localId']?.toString() ?? '1';
          final cardId = item['id']?.toString() ?? '$cleanCode-$localId';
          final name = item['name'] as String? ?? 'Pokémon';
          final imageBase = item['image'] as String?;

          // STRICT FILTER: reject missing images or known 404 CDN placeholders
          if (imageBase == null || imageBase.trim().isEmpty) continue;
          if (localId == 'B' || localId == 'G' || localId == 'R') continue;

          final imgUrl = '$imageBase/high.webp';

          // Official Pokémon Rarity Mapping
          final Rarity rarity = _determinePokemonRarity(
            localId: localId,
            name: name,
            officialCount: officialCount,
          );

          String foilType = 'none';
          if (rarity == Rarity.secretRare) {
            foilType = 'rainbow';
          } else if (rarity == Rarity.ultraRare) {
            foilType = 'gold';
          } else if (rarity == Rarity.rare) {
            foilType = 'holo';
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
            foilType: foilType,
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

    return _buildFallbackCards(cleanCode);
  }

  /// Accurate Official Pokémon Rarity Rule Engine
  static Rarity _determinePokemonRarity({
    required String localId,
    required String name,
    required int officialCount,
  }) {
    final lowerName = name.toLowerCase();
    final upperId = localId.toUpperCase();
    final int? numId = int.tryParse(localId.replaceAll(RegExp(r'[^0-9]'), ''));

    // 1. Secret Rares: numbered past official set count (SAR, Gold, Rainbow, Hyper Rares)
    if (numId != null && numId > officialCount) {
      return Rarity.secretRare;
    }

    // 2. Special gallery cards (Trainer Gallery, Galarian Gallery, Shiny Vault)
    if (upperId.startsWith('TG') ||
        upperId.startsWith('GG') ||
        upperId.startsWith('SV') ||
        upperId.startsWith('SIR') ||
        upperId.startsWith('IR') ||
        upperId.startsWith('AR')) {
      return Rarity.ultraRare;
    }

    // 3. Ultra Rares: Modern ex, EX, GX, V, VMAX, VSTAR, Radiant, Shining
    final bool isUltraKeyword =
        lowerName.contains(' ex') ||
        lowerName.endsWith('ex') ||
        lowerName.contains(' gx') ||
        lowerName.endsWith('gx') ||
        lowerName.contains(' v') ||
        lowerName.endsWith('v') ||
        lowerName.contains('vmax') ||
        lowerName.contains('vstar') ||
        lowerName.contains('radiant ') ||
        lowerName.contains('shining ') ||
        lowerName.contains('prism star') ||
        lowerName.contains('legend') ||
        lowerName.contains('lv.x') ||
        lowerName.contains('break');

    if (isUltraKeyword) {
      return Rarity.ultraRare;
    }

    // 4. Vintage WOTC Sets (Base Set, Jungle, Fossil, etc.) where 1-16 are Holo Rares
    if (officialCount <= 130 && numId != null && numId <= 16) {
      return Rarity.ultraRare;
    }

    // 5. Standard Set distribution for numbered cards within official count
    if (numId != null) {
      if (numId > (officialCount * 0.72)) {
        return Rarity.rare;
      } else if (numId > (officialCount * 0.40)) {
        return Rarity.uncommon;
      } else {
        return Rarity.common;
      }
    }

    return Rarity.common;
  }

  static List<CardModel> _buildFallbackCards(String code) {
    return [
      CardModel(
        id: 'pkm_charizard_base',
        name: 'Charizard',
        gameType: GameType.pokemon,
        setCode: code,
        setName: 'Base Set',
        cardNumber: '4',
        rarity: Rarity.ultraRare,
        imageUrl: 'https://assets.tcgdex.net/en/base/base1/4/high.webp',
        foilType: 'gold',
      ),
      CardModel(
        id: 'pkm_pikachu_surging',
        name: 'Pikachu ex',
        gameType: GameType.pokemon,
        setCode: code,
        setName: 'Surging Sparks',
        cardNumber: '057',
        rarity: Rarity.ultraRare,
        imageUrl: 'https://assets.tcgdex.net/en/sv/sv08/057/high.webp',
        foilType: 'gold',
      ),
      CardModel(
        id: 'pkm_mewtwo_base',
        name: 'Mewtwo',
        gameType: GameType.pokemon,
        setCode: code,
        setName: 'Base Set',
        cardNumber: '10',
        rarity: Rarity.rare,
        imageUrl: 'https://assets.tcgdex.net/en/base/base1/10/high.webp',
        foilType: 'holo',
      ),
      CardModel(
        id: 'pkm_haunter_base',
        name: 'Haunter',
        gameType: GameType.pokemon,
        setCode: code,
        setName: 'Base Set',
        cardNumber: '29',
        rarity: Rarity.uncommon,
        imageUrl: 'https://assets.tcgdex.net/en/base/base1/29/high.webp',
        foilType: 'none',
      ),
      CardModel(
        id: 'pkm_pikachu_base',
        name: 'Pikachu',
        gameType: GameType.pokemon,
        setCode: code,
        setName: 'Base Set',
        cardNumber: '58',
        rarity: Rarity.common,
        imageUrl: 'https://assets.tcgdex.net/en/base/base1/58/high.webp',
        foilType: 'none',
      ),
    ];
  }
}
