import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class MagicScryfallService {
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};
  static List<CardSet>? _cachedSets;

  // Custom User-Agent required by Scryfall API policy
  static const Map<String, String> _headers = {
    'User-Agent': 'BoosterTCG/1.0 (contact: byjos@booster.local)',
    'Accept': 'application/json',
  };

  // Official MTG Booster Pack wrappers from TCGPlayer CDN
  static const Map<String, String> _officialBoosterArts = {
    'blb': 'https://product-images.tcgplayer.com/fit-in/437x437/541237.jpg', // Bloomburrow
    'mh3': 'https://product-images.tcgplayer.com/fit-in/437x437/541173.jpg', // Modern Horizons 3
    'otj': 'https://product-images.tcgplayer.com/fit-in/437x437/541086.jpg', // Outlaws of Thunder Junction
    'neo': 'https://product-images.tcgplayer.com/fit-in/437x437/257562.jpg', // Kamigawa Neon Dynasty
    'fdn': 'https://product-images.tcgplayer.com/fit-in/437x437/562121.jpg', // Foundations
    'mkm': 'https://product-images.tcgplayer.com/fit-in/437x437/531238.jpg', // Murders at Karlov Manor
    'lci': 'https://product-images.tcgplayer.com/fit-in/437x437/508688.jpg', // Lost Caverns of Ixalan
    'woe': 'https://product-images.tcgplayer.com/fit-in/437x437/500139.jpg', // Wilds of Eldraine
    'mom': 'https://product-images.tcgplayer.com/fit-in/437x437/478546.jpg', // March of the Machine
    'one': 'https://product-images.tcgplayer.com/fit-in/437x437/451996.jpg', // Phyrexia All Will Be One
    'dmu': 'https://product-images.tcgplayer.com/fit-in/437x437/276530.jpg', // Dominaria United
  };

  /// Fetches ALL official Magic expansion sets dynamically from Scryfall
  static Future<List<CardSet>> getAllSets() async {
    if (_cachedSets != null && _cachedSets!.isNotEmpty) {
      return _cachedSets!;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.scryfallBaseUrl}/sets'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];

        final now = DateTime.now();

        final sets = list
            .where((item) {
              final type = item['set_type'] as String? ?? '';
              final count = item['card_count'] as int? ?? 0;
              final relDateStr = item['released_at'] as String?;

              // Only include sets that are released and have booster cards
              if (count < 10) return false;
              if (relDateStr != null) {
                final rel = DateTime.tryParse(relDateStr);
                if (rel != null && rel.isAfter(now)) return false;
              }

              return type == 'expansion' ||
                  type == 'core' ||
                  type == 'masters' ||
                  type == 'draft_innovation';
            })
            .map((item) {
              final code = item['code'] as String;
              final name = item['name'] as String;
              final count = item['card_count'] as int? ?? 0;
              final release = item['released_at'] as String?;
              final iconSvg = item['icon_svg_uri'] as String?;

              final cleanCode = code.toLowerCase();
              final boosterArt = _officialBoosterArts[cleanCode];

              return CardSet(
                id: 'mtg_$code',
                code: code,
                name: name,
                gameType: GameType.magic,
                totalCards: count,
                releaseDate: release,
                iconUrl: iconSvg,
                boosterArtUrl: boosterArt ?? iconSvg,
              );
            })
            .toList();

        _cachedSets = sets;
        return sets;
      }
    } catch (e) {
      debugPrint('Error fetching MTG sets from Scryfall: $e');
    }

    return getFallbackSets();
  }

  static List<CardSet> getFallbackSets() {
    return const [
      CardSet(
        id: 'mtg_blb',
        code: 'blb',
        name: 'Bloomburrow',
        gameType: GameType.magic,
        totalCards: 261,
        releaseDate: '2024-08-02',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541237.jpg',
      ),
      CardSet(
        id: 'mtg_mh3',
        code: 'mh3',
        name: 'Modern Horizons 3',
        gameType: GameType.magic,
        totalCards: 261,
        releaseDate: '2024-06-14',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541173.jpg',
      ),
      CardSet(
        id: 'mtg_otj',
        code: 'otj',
        name: 'Outlaws of Thunder Junction',
        gameType: GameType.magic,
        totalCards: 276,
        releaseDate: '2024-04-19',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541086.jpg',
      ),
      CardSet(
        id: 'mtg_neo',
        code: 'neo',
        name: 'Kamigawa: Neon Dynasty',
        gameType: GameType.magic,
        totalCards: 302,
        releaseDate: '2022-02-18',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/257562.jpg',
      ),
      CardSet(
        id: 'mtg_fdn',
        code: 'fdn',
        name: 'Magic Foundations',
        gameType: GameType.magic,
        totalCards: 361,
        releaseDate: '2024-11-15',
        boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/562121.jpg',
      ),
    ];
  }

  /// Fetches real cards for the chosen set using Scryfall search API
  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    final cleanCode = setCode.toLowerCase().trim();

    if (_cachedCardsBySet.containsKey(cleanCode) &&
        _cachedCardsBySet[cleanCode]!.isNotEmpty) {
      return _cachedCardsBySet[cleanCode]!;
    }

    try {
      final url = Uri.parse(
          '${ApiConstants.scryfallBaseUrl}/cards/search?q=set:$cleanCode&order=rarity');
      final res = await http.get(url, headers: _headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];

        final cards = _parseScryfallCards(list, cleanCode);
        if (cards.isNotEmpty) {
          _cachedCardsBySet[cleanCode] = cards;
          return cards;
        }
      } else {
        debugPrint('Scryfall returned status ${res.statusCode} for set $cleanCode');
      }
    } catch (e) {
      debugPrint('Error fetching MTG cards for set $cleanCode: $e');
    }

    final fallbacks = _buildFallbackCards(cleanCode);
    _cachedCardsBySet[cleanCode] = fallbacks;
    return fallbacks;
  }

  static List<CardModel> _parseScryfallCards(List<dynamic> list, String cleanCode) {
    final cards = <CardModel>[];

    for (final item in list) {
      final imageUris = item['image_uris'] as Map<String, dynamic>? ??
          (item['card_faces'] != null && (item['card_faces'] as List).isNotEmpty
              ? (item['card_faces'][0]['image_uris'] as Map<String, dynamic>?)
              : null);

      final normalUrl = imageUris?['normal'] as String?;
      final largeUrl = imageUris?['large'] as String? ?? normalUrl;

      // Filter out cards without valid image
      if (normalUrl == null || normalUrl.isEmpty) continue;

      final rarityRaw = (item['rarity'] as String? ?? 'common').toLowerCase();
      final name = item['name'] as String? ?? 'Magic Card';
      final num = item['collector_number']?.toString() ?? '1';

      // Official Magic: The Gathering Rarity Mapping
      Rarity r = Rarity.common;
      if (rarityRaw == 'mythic') {
        r = Rarity.ultraRare;
      } else if (rarityRaw == 'rare') {
        r = Rarity.rare;
      } else if (rarityRaw == 'uncommon') {
        r = Rarity.uncommon;
      } else if (rarityRaw == 'special' || rarityRaw == 'bonus') {
        r = Rarity.secretRare;
      } else {
        r = Rarity.common;
      }

      // Check for showcase / borderless / serialized / alt-art promotions
      final frameEffects = item['frame_effects'] as List<dynamic>? ?? [];
      final borderColor = item['border_color'] as String? ?? '';
      if (r == Rarity.rare && (frameEffects.contains('showcase') || borderColor == 'borderless')) {
        r = Rarity.ultraRare;
      }

      String foilType = 'none';
      if (r == Rarity.secretRare) {
        foilType = 'rainbow';
      } else if (r == Rarity.ultraRare) {
        foilType = 'gold';
      } else if (r == Rarity.rare || item['foil'] == true) {
        foilType = 'holo';
      }

      cards.add(CardModel(
        id: 'mtg_${item['id']}',
        name: name,
        gameType: GameType.magic,
        setCode: cleanCode.toUpperCase(),
        setName: item['set_name'] as String? ?? cleanCode.toUpperCase(),
        cardNumber: num,
        rarity: r,
        imageUrl: normalUrl,
        imageHighResUrl: largeUrl,
        foilType: foilType,
        extraData: {
          'mana_cost': item['mana_cost'] ?? '',
          'type_line': item['type_line'] ?? '',
        },
      ));
    }

    return cards;
  }

  static List<CardModel> _buildFallbackCards(String code) {
    final upper = code.toUpperCase();
    return [
      CardModel(
        id: 'mtg_fallback_bolt',
        name: 'Lightning Bolt',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '001',
        rarity: Rarity.common,
        imageUrl: 'https://cards.scryfall.io/normal/front/f/2/f29ba16f-c8fb-42fe-aabf-87089cb214a7.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/f/2/f29ba16f-c8fb-42fe-aabf-87089cb214a7.jpg',
        foilType: 'none',
      ),
      CardModel(
        id: 'mtg_fallback_counterspell',
        name: 'Counterspell',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '002',
        rarity: Rarity.uncommon,
        imageUrl: 'https://cards.scryfall.io/normal/front/4/f/4f0ba07f-de7a-4221-a392-60f1ad788647.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/4/f/4f0ba07f-de7a-4221-a392-60f1ad788647.jpg',
        foilType: 'none',
      ),
      CardModel(
        id: 'mtg_fallback_wrath',
        name: 'Wrath of God',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '003',
        rarity: Rarity.rare,
        imageUrl: 'https://cards.scryfall.io/normal/front/6/6/664e6656-36a3-4635-9f33-928921a54282.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/6/6/664e6656-36a3-4635-9f33-928921a54282.jpg',
        foilType: 'holo',
      ),
      CardModel(
        id: 'mtg_fallback_jace',
        name: 'Jace, the Mind Sculptor',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '004',
        rarity: Rarity.ultraRare,
        imageUrl: 'https://cards.scryfall.io/normal/front/c/8/c8817585-0d32-4d56-9142-0d29512e86a9.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/c/8/c8817585-0d32-4d56-9142-0d29512e86a9.jpg',
        foilType: 'gold',
      ),
      CardModel(
        id: 'mtg_fallback_lotus',
        name: 'Black Lotus',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '005',
        rarity: Rarity.secretRare,
        imageUrl: 'https://cards.scryfall.io/normal/front/b/d/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/b/d/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd.jpg',
        foilType: 'rainbow',
      ),
    ];
  }
}
