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

              return CardSet(
                id: 'mtg_$code',
                code: code,
                name: name,
                gameType: GameType.magic,
                totalCards: count,
                releaseDate: release,
                iconUrl: iconSvg,
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
      ),
      CardSet(
        id: 'mtg_mh3',
        code: 'mh3',
        name: 'Modern Horizons 3',
        gameType: GameType.magic,
        totalCards: 261,
        releaseDate: '2024-06-14',
      ),
      CardSet(
        id: 'mtg_otj',
        code: 'otj',
        name: 'Outlaws of Thunder Junction',
        gameType: GameType.magic,
        totalCards: 276,
        releaseDate: '2024-04-19',
      ),
      CardSet(
        id: 'mtg_neo',
        code: 'neo',
        name: 'Kamigawa: Neon Dynasty',
        gameType: GameType.magic,
        totalCards: 302,
        releaseDate: '2022-02-18',
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

      if (normalUrl == null) continue;

      final rarityStr = item['rarity'] as String? ?? 'common';
      final name = item['name'] as String? ?? 'Magic Card';
      final num = item['collector_number']?.toString() ?? '1';

      cards.add(CardModel(
        id: 'mtg_${item['id']}',
        name: name,
        gameType: GameType.magic,
        setCode: cleanCode.toUpperCase(),
        setName: item['set_name'] as String? ?? cleanCode.toUpperCase(),
        cardNumber: num,
        rarity: Rarity.fromString(rarityStr),
        imageUrl: normalUrl,
        imageHighResUrl: largeUrl,
        foilType: item['foil'] == true ? 'holo' : 'none',
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
      ),
      CardModel(
        id: 'mtg_fallback_counterspell',
        name: 'Counterspell',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '002',
        rarity: Rarity.common,
        imageUrl: 'https://cards.scryfall.io/normal/front/4/f/4f0ba07f-de7a-4221-a392-60f1ad788647.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/4/f/4f0ba07f-de7a-4221-a392-60f1ad788647.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_dark_ritual',
        name: 'Dark Ritual',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '003',
        rarity: Rarity.common,
        imageUrl: 'https://cards.scryfall.io/normal/front/9/5/95f27eeb-6f14-4db3-adb9-9be5ed76b34b.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/9/5/95f27eeb-6f14-4db3-adb9-9be5ed76b34b.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_swords',
        name: 'Swords to Plowshares',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '004',
        rarity: Rarity.uncommon,
        imageUrl: 'https://cards.scryfall.io/normal/front/7/d/7d839f21-68c7-47db-8407-ff3e2c3e13b4.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/7/d/7d839f21-68c7-47db-8407-ff3e2c3e13b4.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_demonic_tutor',
        name: 'Demonic Tutor',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '005',
        rarity: Rarity.uncommon,
        imageUrl: 'https://cards.scryfall.io/normal/front/9/9/99d3a778-be76-47b7-b089-6e3e5b3ee0b7.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/9/9/99d3a778-be76-47b7-b089-6e3e5b3ee0b7.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_birds',
        name: 'Birds of Paradise',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '006',
        rarity: Rarity.rare,
        imageUrl: 'https://cards.scryfall.io/normal/front/f/e/feefe9f0-24a6-461c-9ef1-86c5a6f33b83.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/f/e/feefe9f0-24a6-461c-9ef1-86c5a6f33b83.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_wrath',
        name: 'Wrath of God',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '007',
        rarity: Rarity.rare,
        imageUrl: 'https://cards.scryfall.io/normal/front/6/6/664e6656-36a3-4635-9f33-9289fe12fe8a.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/6/6/664e6656-36a3-4635-9f33-9289fe12fe8a.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_lotus',
        name: 'Black Lotus',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '008',
        rarity: Rarity.ultraRare,
        foilType: 'holo',
        imageUrl: 'https://cards.scryfall.io/normal/front/b/d/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/b/d/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd.jpg',
      ),
      CardModel(
        id: 'mtg_fallback_ring',
        name: 'The One Ring',
        gameType: GameType.magic,
        setCode: upper,
        setName: 'MTG Iconic Collection',
        cardNumber: '009',
        rarity: Rarity.secretRare,
        foilType: 'holo',
        imageUrl: 'https://cards.scryfall.io/normal/front/9/3/93de71d0-b0b7-4730-8d07-648e4894f380.jpg',
        imageHighResUrl: 'https://cards.scryfall.io/large/front/9/3/93de71d0-b0b7-4730-8d07-648e4894f380.jpg',
      ),
    ];
  }
}
