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
    ),
    CardSet(
      id: 'rb_spf',
      code: 'Spiritforged',
      name: 'Spiritforged',
      gameType: GameType.riftbound,
      totalCards: 287,
      releaseDate: '2024-10-18',
    ),
    CardSet(
      id: 'rb_unl',
      code: 'Unleashed',
      name: 'Unleashed',
      gameType: GameType.riftbound,
      totalCards: 288,
      releaseDate: '2025-02-14',
    ),
    CardSet(
      id: 'rb_vdt',
      code: 'Vendetta',
      name: 'Vendetta',
      gameType: GameType.riftbound,
      totalCards: 237,
      releaseDate: '2025-06-20',
    ),
    CardSet(
      id: 'rb_rad',
      code: 'Radiance',
      name: 'Radiance of Targon',
      gameType: GameType.riftbound,
      totalCards: 219,
      releaseDate: '2025-10-15',
    ),
    CardSet(
      id: 'rb_pvg',
      code: 'Proving Grounds',
      name: 'Proving Grounds (Starter)',
      gameType: GameType.riftbound,
      totalCards: 24,
      releaseDate: '2024-04-01',
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
      final rarityRaw = item['rarity'] as String? ?? 'Common';
      final cardCode = item['cardCode'] as String? ?? item['cardNumber'] as String? ?? '0';

      Rarity r = Rarity.common;
      final lowerR = rarityRaw.toLowerCase();
      if (lowerR.contains('showcase') || lowerR.contains('mythic') || lowerR.contains('secret')) {
        r = Rarity.secretRare;
      } else if (lowerR.contains('epic') || lowerR.contains('champion')) {
        r = Rarity.ultraRare;
      } else if (lowerR.contains('rare')) {
        r = Rarity.rare;
      } else if (lowerR.contains('uncommon')) {
        r = Rarity.uncommon;
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
        foilType: r.tier >= 3 ? 'holo' : 'none',
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
    }

    return cards;
  }
}
