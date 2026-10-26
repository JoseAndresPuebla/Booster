import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class RiftboundService {
  static const String _cardsJsonUrl =
      'https://github.com/LouisCourrian/riftbound-cards/releases/download/v2026-10-18/cards.json';

  static List<dynamic>? _rawCardsCache;
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};

  static const List<CardSet> sets = [
    CardSet(
      id: 'rb_ogn',
      code: 'Origins',
      name: 'Origins (Runeterra Genesis)',
      gameType: GameType.riftbound,
      totalCards: 352,
      releaseDate: '2024-05-10',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/09da06c69d07d4e72dde703737ef167472c715af-1488x2078.png',
    ),
    CardSet(
      id: 'rb_spf',
      code: 'Spiritforged',
      name: 'Spiritforged',
      gameType: GameType.riftbound,
      totalCards: 287,
      releaseDate: '2024-10-18',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/9019c449004f246de6607bf1829f4f3cabcda200-744x1039.png',
    ),
    CardSet(
      id: 'rb_unl',
      code: 'Unleashed',
      name: 'Unleashed',
      gameType: GameType.riftbound,
      totalCards: 288,
      releaseDate: '2025-02-14',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/9b742ef3dc17f5da03d41e3349839037183b5ea9-744x1039.png',
    ),
    CardSet(
      id: 'rb_vdt',
      code: 'Vendetta',
      name: 'Vendetta',
      gameType: GameType.riftbound,
      totalCards: 237,
      releaseDate: '2025-06-20',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/a14d1be8f014a331f60885013d81a1a8f5c8c076-744x1039.png',
    ),
    CardSet(
      id: 'rb_rad',
      code: 'Radiance',
      name: 'Radiance of Targon',
      gameType: GameType.riftbound,
      totalCards: 219,
      releaseDate: '2025-10-15',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/e4be56cd7dc8075298567c5b28ecc3e46b87bc57-744x1039.png',
    ),
    CardSet(
      id: 'rb_pvg',
      code: 'Proving Grounds',
      name: 'Proving Grounds (Starter)',
      gameType: GameType.riftbound,
      totalCards: 24,
      releaseDate: '2024-04-01',
      boosterArtUrl:
          'https://cmsassets.rgpub.io/sanity/images/dsfx7636/game_data_live/532d75dc36a16eb5954253a77366fcceac7aec62-744x1039.png',
    ),
  ];

  static Future<List<CardSet>> getAllSets() async {
    return sets;
  }

  static Future<List<dynamic>> _loadAllCards() async {
    if (_rawCardsCache != null && _rawCardsCache!.isNotEmpty) {
      return _rawCardsCache!;
    }

    try {
      final res = await http.get(
        Uri.parse(_cardsJsonUrl),
        headers: {'User-Agent': 'BoosterTCG/1.0'},
      );

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        _rawCardsCache = list;
        return list;
      }
    } catch (e) {
      debugPrint('Error loading Riftbound cards.json: $e');
    }

    return [];
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    final cleanSet = setCode.trim().toLowerCase();

    if (_cachedCardsBySet.containsKey(cleanSet) &&
        _cachedCardsBySet[cleanSet]!.isNotEmpty) {
      return _cachedCardsBySet[cleanSet]!;
    }

    final all = await _loadAllCards();
    if (all.isEmpty) return [];

    final filtered = all.where((item) {
      final itemSet = (item['cardSet'] as String? ?? '').toLowerCase();
      final itemCode = (item['setCode'] as String? ?? '').toLowerCase();
      return itemSet == cleanSet || itemCode == cleanSet;
    }).toList();

    final cards = <CardModel>[];

    for (final item in filtered) {
      final img = item['imageUrl'] as String?;
      if (img == null || img.isEmpty) continue;

      final name = item['fullName'] as String? ?? item['name'] as String? ?? 'Riftbound Card';
      final rarityRaw = (item['rarity'] as String? ?? 'Common').toLowerCase();
      final cardCode = item['cardCode'] as String? ?? item['cardNumber'] as String? ?? '0';

      // Official Riftbound Rarity Mapping
      Rarity r = Rarity.common;
      if (rarityRaw.contains('showcase') || rarityRaw.contains('mythic')) {
        r = Rarity.secretRare;
      } else if (rarityRaw.contains('epic') || rarityRaw.contains('champion')) {
        r = Rarity.ultraRare;
      } else if (rarityRaw.contains('rare')) {
        r = Rarity.rare;
      } else if (rarityRaw.contains('uncommon')) {
        r = Rarity.uncommon;
      }

      String foilType = 'none';
      if (r == Rarity.secretRare) {
        foilType = 'rainbow';
      } else if (r == Rarity.ultraRare) {
        foilType = 'gold';
      } else if (r == Rarity.rare) {
        foilType = 'holo';
      }

      cards.add(CardModel(
        id: 'rb_${item['cardCode'] ?? item['name']}',
        name: name,
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: item['cardSet'] as String? ?? setCode,
        cardNumber: cardCode,
        rarity: r,
        imageUrl: img,
        imageHighResUrl: img,
        foilType: foilType,
        extraData: {
          'domain': item['domain'] ?? '',
          'energy': item['energy'] ?? 0,
          'might': item['might'] ?? 0,
          'power': item['power'] ?? 0,
        },
      ));
    }

    if (cards.isNotEmpty) {
      _cachedCardsBySet[cleanSet] = cards;
      return cards;
    }

    return [];
  }
}
