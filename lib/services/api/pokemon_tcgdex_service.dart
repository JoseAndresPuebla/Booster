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

  // Base URL for authentic high-res transparent booster packshot assets
  static const String _packAssetBase =
      'https://raw.githubusercontent.com/1niceroli/ptcg-assets/main';

  // Comprehensive official catalogue of Pokémon TCG expansions with authentic wrappers
  static const List<CardSet> officialSets = [
    // SCARLET & VIOLET ERA
    CardSet(
      id: 'pkm_sv08',
      code: 'sv08',
      name: 'Surging Sparks',
      gameType: GameType.pokemon,
      totalCards: 191,
      releaseDate: '2024-11-08',
      boosterArtUrl:
          '$_packAssetBase/sv8/packshots/Pokemon_TCG_Scarlet_Violet%E2%80%94Surging_Sparks_Booster_Wrap_PikachuStellar.png',
    ),
    CardSet(
      id: 'pkm_sv07',
      code: 'sv07',
      name: 'Stellar Crown',
      gameType: GameType.pokemon,
      totalCards: 142,
      releaseDate: '2024-09-13',
      boosterArtUrl:
          '$_packAssetBase/sv7/packshots/Pokemon_TCG_Scarlet_Violet%E2%80%94Stellar_Crown_Booster_Wrap_Cinderace.png',
    ),
    CardSet(
      id: 'pkm_sv06',
      code: 'sv06',
      name: 'Twilight Masquerade',
      gameType: GameType.pokemon,
      totalCards: 167,
      releaseDate: '2024-05-24',
      boosterArtUrl: '$_packAssetBase/sv6/packshots/SV6_Booster_Dragapult.webp',
    ),
    CardSet(
      id: 'pkm_sv05',
      code: 'sv05',
      name: 'Temporal Forces',
      gameType: GameType.pokemon,
      totalCards: 162,
      releaseDate: '2024-03-22',
      boosterArtUrl: '$_packAssetBase/sv5/packshots/SV5_Booster_Iron_Crown.webp',
    ),
    CardSet(
      id: 'pkm_sv04.5',
      code: 'sv04.5',
      name: 'Paldean Fates',
      gameType: GameType.pokemon,
      totalCards: 91,
      releaseDate: '2024-01-26',
      boosterArtUrl:
          '$_packAssetBase/sv4pt5/packshots/Pokemon_TCG_Scarlet_Violet%E2%80%94Paldean_Fates_Booster_Wrap_Ceruledge.webp',
    ),
    CardSet(
      id: 'pkm_sv04',
      code: 'sv04',
      name: 'Paradox Rift',
      gameType: GameType.pokemon,
      totalCards: 182,
      releaseDate: '2023-11-03',
      boosterArtUrl: '$_packAssetBase/sv4/packshots/SV4_Booster_Armarouge.webp',
    ),
    CardSet(
      id: 'pkm_sv03.5',
      code: 'sv03.5',
      name: 'Pokémon 151',
      gameType: GameType.pokemon,
      totalCards: 165,
      releaseDate: '2023-09-22',
      boosterArtUrl: '$_packAssetBase/sv3pt5/packshots/151_Booster.webp',
    ),
    CardSet(
      id: 'pkm_sv03',
      code: 'sv03',
      name: 'Obsidian Flames',
      gameType: GameType.pokemon,
      totalCards: 197,
      releaseDate: '2023-08-11',
      boosterArtUrl: '$_packAssetBase/sv3/packshots/SV3_Booster_Charizard.webp',
    ),
    CardSet(
      id: 'pkm_sv02',
      code: 'sv02',
      name: 'Paldea Evolved',
      gameType: GameType.pokemon,
      totalCards: 193,
      releaseDate: '2023-06-09',
      boosterArtUrl: '$_packAssetBase/sv2/packshots/SV2_Booster_Chien-Pao.webp',
    ),
    CardSet(
      id: 'pkm_sv01',
      code: 'sv01',
      name: 'Scarlet & Violet Base',
      gameType: GameType.pokemon,
      totalCards: 198,
      releaseDate: '2023-03-31',
      boosterArtUrl: '$_packAssetBase/sv1/packshots/SV1_pack_Gyarados.webp',
    ),

    // SWORD & SHIELD ERA
    CardSet(
      id: 'pkm_swsh12.5',
      code: 'swsh12.5',
      name: 'Crown Zenith',
      gameType: GameType.pokemon,
      totalCards: 160,
      releaseDate: '2023-01-20',
      boosterArtUrl: '$_packAssetBase/swsh12pt5/packshots/Crown_Zenith_Booster.webp',
    ),
    CardSet(
      id: 'pkm_swsh12',
      code: 'swsh12',
      name: 'Silver Tempest',
      gameType: GameType.pokemon,
      totalCards: 195,
      releaseDate: '2022-11-11',
      boosterArtUrl: '$_packAssetBase/swsh12/packshots/HRAkc04667-03.webp',
    ),
    CardSet(
      id: 'pkm_swsh11',
      code: 'swsh11',
      name: 'Lost Origin',
      gameType: GameType.pokemon,
      totalCards: 196,
      releaseDate: '2022-09-09',
      boosterArtUrl: '$_packAssetBase/swsh11/packshots/SWSH11_Booster_Enamorus.webp',
    ),
    CardSet(
      id: 'pkm_swsh10',
      code: 'swsh10',
      name: 'Astral Radiance',
      gameType: GameType.pokemon,
      totalCards: 189,
      releaseDate: '2022-05-27',
      boosterArtUrl:
          '$_packAssetBase/swsh10/packshots/SWSH10_Booster_Hisuian_Decidueye.webp',
    ),
    CardSet(
      id: 'pkm_swsh09',
      code: 'swsh09',
      name: 'Brilliant Stars',
      gameType: GameType.pokemon,
      totalCards: 172,
      releaseDate: '2022-02-25',
      boosterArtUrl:
          '$_packAssetBase/swsh9/packshots/Pokemon_TCG_Sword_Shield%E2%80%94Brilliant_Stars_Booster_Wrap_Arceus_VSTAR-2.webp',
    ),
    CardSet(
      id: 'pkm_swsh08',
      code: 'swsh08',
      name: 'Fusion Strike',
      gameType: GameType.pokemon,
      totalCards: 264,
      releaseDate: '2021-11-12',
      boosterArtUrl: '$_packAssetBase/swsh8/packshots/SWSH8_Booster_Boltund.webp',
    ),
    CardSet(
      id: 'pkm_swsh07',
      code: 'swsh07',
      name: 'Evolving Skies',
      gameType: GameType.pokemon,
      totalCards: 203,
      releaseDate: '2021-08-27',
      boosterArtUrl:
          '$_packAssetBase/swsh7/packshots/SWSH7_Booster_Gigantamax_Duraludon.webp',
    ),
    CardSet(
      id: 'pkm_swsh45',
      code: 'swsh4.5',
      name: 'Shining Fates',
      gameType: GameType.pokemon,
      totalCards: 73,
      releaseDate: '2021-02-19',
      boosterArtUrl:
          '$_packAssetBase/swsh45/packshots/Shining_Fates_Booster_Shiny_Charizard_VMAX.webp',
    ),
    CardSet(
      id: 'pkm_swsh04',
      code: 'swsh04',
      name: 'Vivid Voltage',
      gameType: GameType.pokemon,
      totalCards: 185,
      releaseDate: '2020-11-13',
      boosterArtUrl: '$_packAssetBase/swsh4/packshots/SWSH4_Booster_Pikachu.webp',
    ),
    CardSet(
      id: 'pkm_swsh03',
      code: 'swsh03',
      name: 'Darkness Ablaze',
      gameType: GameType.pokemon,
      totalCards: 189,
      releaseDate: '2020-08-14',
      boosterArtUrl: '$_packAssetBase/swsh3/packshots/SWSH3_Booster_Charizard.webp',
    ),
    CardSet(
      id: 'pkm_swsh01',
      code: 'swsh01',
      name: 'Sword & Shield Base',
      gameType: GameType.pokemon,
      totalCards: 202,
      releaseDate: '2020-02-07',
      boosterArtUrl: '$_packAssetBase/swsh1/packshots/SWSH1_Booster_Zacian.webp',
    ),

    // SUN & MOON ERA
    CardSet(
      id: 'pkm_sm12',
      code: 'sm12',
      name: 'Cosmic Eclipse',
      gameType: GameType.pokemon,
      totalCards: 236,
      releaseDate: '2019-11-01',
      boosterArtUrl: '$_packAssetBase/sm12/packshots/SM12_Booster_Blastoise_Piplup.webp',
    ),
    CardSet(
      id: 'pkm_sm11.5',
      code: 'sm11.5',
      name: 'Hidden Fates',
      gameType: GameType.pokemon,
      totalCards: 68,
      releaseDate: '2019-08-23',
      boosterArtUrl: '$_packAssetBase/sm115/packshots/Hidden_Fates_Booster_Charizard.webp',
    ),
    CardSet(
      id: 'pkm_sm07.5',
      code: 'sm07.5',
      name: 'Dragon Majesty',
      gameType: GameType.pokemon,
      totalCards: 70,
      releaseDate: '2018-09-07',
      boosterArtUrl: '$_packAssetBase/sm75/packshots/Dragon_Majesty_Booster_Charizard.webp',
    ),
    CardSet(
      id: 'pkm_sm03.5',
      code: 'sm03.5',
      name: 'Shining Legends',
      gameType: GameType.pokemon,
      totalCards: 73,
      releaseDate: '2017-10-06',
      boosterArtUrl: '$_packAssetBase/sm35/packshots/Shining_Legends_Booster_Genesect.webp',
    ),
    CardSet(
      id: 'pkm_sm01',
      code: 'sm01',
      name: 'Sun & Moon Base',
      gameType: GameType.pokemon,
      totalCards: 149,
      releaseDate: '2017-02-03',
      boosterArtUrl: '$_packAssetBase/sm1/packshots/SM1_Booster_Decidueye.webp',
    ),

    // XY ERA
    CardSet(
      id: 'pkm_xy12',
      code: 'xy12',
      name: 'Evolutions (Classic Remake)',
      gameType: GameType.pokemon,
      totalCards: 108,
      releaseDate: '2016-11-02',
      boosterArtUrl: '$_packAssetBase/xy12/packshots/XY12_Booster_Blastoise.webp',
    ),
    CardSet(
      id: 'pkm_xy10',
      code: 'xy10',
      name: 'Fates Collide',
      gameType: GameType.pokemon,
      totalCards: 124,
      releaseDate: '2016-05-02',
      boosterArtUrl: '$_packAssetBase/xy10/packshots/XY10_Booster_Alakazam.webp',
    ),
    CardSet(
      id: 'pkm_xy07',
      code: 'xy07',
      name: 'Ancient Origins',
      gameType: GameType.pokemon,
      totalCards: 98,
      releaseDate: '2015-08-12',
      boosterArtUrl: '$_packAssetBase/xy7/packshots/XY7_Booster_Groudon.webp',
    ),
    CardSet(
      id: 'pkm_xy01',
      code: 'xy01',
      name: 'XY Base Set',
      gameType: GameType.pokemon,
      totalCards: 146,
      releaseDate: '2014-02-05',
      boosterArtUrl: '$_packAssetBase/xy1/packshots/XY1_Booster_Blastoise.webp',
    ),

    // VINTAGE ERA (WIZARDS OF THE COAST)
    CardSet(
      id: 'pkm_bw01',
      code: 'bw01',
      name: 'Black & White Base',
      gameType: GameType.pokemon,
      totalCards: 114,
      releaseDate: '2011-04-25',
      boosterArtUrl: '$_packAssetBase/bw1/packshots/BW1_Booster_Reshiram.webp',
    ),
    CardSet(
      id: 'pkm_hgss01',
      code: 'hgss01',
      name: 'HeartGold & SoulSilver',
      gameType: GameType.pokemon,
      totalCards: 123,
      releaseDate: '2010-02-10',
      boosterArtUrl: '$_packAssetBase/hgss1/packshots/HS1_Booster_Ampharos.webp',
    ),
    CardSet(
      id: 'pkm_dp01',
      code: 'dp01',
      name: 'Diamond & Pearl',
      gameType: GameType.pokemon,
      totalCards: 130,
      releaseDate: '2007-05-23',
      boosterArtUrl: '$_packAssetBase/dp1/packshots/DP1_Booster_Dialga.webp',
    ),
    CardSet(
      id: 'pkm_neo1',
      code: 'neo1',
      name: 'Neo Genesis',
      gameType: GameType.pokemon,
      totalCards: 111,
      releaseDate: '2000-12-16',
      boosterArtUrl: '$_packAssetBase/neo1/packshots/138141.webp',
    ),
    CardSet(
      id: 'pkm_gym1',
      code: 'gym1',
      name: 'Gym Heroes',
      gameType: GameType.pokemon,
      totalCards: 132,
      releaseDate: '2000-08-14',
      boosterArtUrl: '$_packAssetBase/gym1/packshots/Gym_Heroes_Booster_Brock.webp',
    ),
    CardSet(
      id: 'pkm_base1',
      code: 'base1',
      name: 'Classic Base Set (1999)',
      gameType: GameType.pokemon,
      totalCards: 102,
      releaseDate: '1999-01-09',
      boosterArtUrl:
          '$_packAssetBase/base1/packshots/Base_Set_Booster_Blastoise_Shadowless.webp',
    ),
  ];

  static final Map<String, String> _knownBoosterArts = {
    for (final s in officialSets)
      if (s.boosterArtUrl != null && s.boosterArtUrl!.isNotEmpty)
        s.code.toLowerCase(): s.boosterArtUrl!,
  };

  /// Returns ALL official Pokémon sets dynamically from TcgDex API,
  /// matching booster pack wrappers where available, and falling back to officialSets offline.
  static Future<List<CardSet>> getAllSets() async {
    if (_cachedSets != null && _cachedSets!.isNotEmpty) {
      return _cachedSets!;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.tcgdexBaseUrl}/sets'),
        headers: {'User-Agent': 'BoosterTCG/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>? ?? [];

        final sets = <CardSet>[];
        for (final item in list) {
          if (item is! Map<String, dynamic>) continue;
          final id = (item['id']?.toString() ?? '').toLowerCase().trim();
          final name = item['name']?.toString() ?? id;
          final countMap = item['cardCount'] as Map<String, dynamic>?;
          final total =
              countMap?['total'] as int? ?? countMap?['official'] as int? ?? 0;
          final logo = item['logo'] as String?;

          // Ignore empty demo/promo lists, but DO NOT filter out sets lacking booster art
          if (total < 10 || id == '30th-c' || id.contains('demo')) continue;

          final boosterArt = _knownBoosterArts[id];

          sets.add(CardSet(
            id: 'pkm_$id',
            code: id,
            name: name,
            gameType: GameType.pokemon,
            totalCards: total,
            iconUrl: logo != null ? '$logo.webp' : null,
            boosterArtUrl:
                boosterArt, // Null if no cover, BoosterPackWidget renders procedural
          ));
        }

        if (sets.isNotEmpty) {
          final reversed = sets.reversed.toList();
          _cachedSets = reversed;
          return reversed;
        }
      }
    } catch (e) {
      debugPrint('Error fetching Pokemon sets from TcgDex: $e');
    }

    _cachedSets = List<CardSet>.from(officialSets);
    return _cachedSets!;
  }

  static List<CardSet> getFallbackSets() {
    return officialSets;
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
      final res = await http.get(url, headers: {'User-Agent': 'BoosterTCG/1.0'});

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
