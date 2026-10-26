import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class OnePieceApiService {
  static final Map<String, List<CardModel>> _cachedCardsByPack = {};

  // Official Booster Sets mapped to Punk Records pack IDs with official Bandai wrapper art
  static const List<Map<String, String>> officialPacks = [
    {
      'id': '569105',
      'code': 'OP-05',
      'name': 'Awakening of the New Era',
      'date': '2023-12-08',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op05/img_item01.webp',
    },
    {
      'id': '569101',
      'code': 'OP-01',
      'name': 'Romance Dawn',
      'date': '2022-12-02',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op01/img_item01.webp',
    },
    {
      'id': '569102',
      'code': 'OP-02',
      'name': 'Paramount War',
      'date': '2023-03-10',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op02/img_item01.webp',
    },
    {
      'id': '569103',
      'code': 'OP-03',
      'name': 'Pillars of Strength',
      'date': '2023-06-30',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op03/img_item01.webp',
    },
    {
      'id': '569104',
      'code': 'OP-04',
      'name': 'Kingdoms of Intrigue',
      'date': '2023-09-22',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op04/img_item01.webp',
    },
    {
      'id': '569106',
      'code': 'OP-06',
      'name': 'Wings of the Captain',
      'date': '2024-03-15',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op06/img_item01.webp',
    },
    {
      'id': '569107',
      'code': 'OP-07',
      'name': '500 Years in the Future',
      'date': '2024-06-28',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op07/img_item01.webp',
    },
    {
      'id': '569108',
      'code': 'OP-08',
      'name': 'Two Legends',
      'date': '2024-09-13',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op08/img_item01.webp',
    },
    {
      'id': '569109',
      'code': 'OP-09',
      'name': 'Emperors in the New World',
      'date': '2024-12-13',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op09/img_item01.webp',
    },
    {
      'id': '569110',
      'code': 'OP-10',
      'name': 'Royal Blood',
      'date': '2025-03-21',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/op10/img_item01.webp',
    },
    {
      'id': '569201',
      'code': 'EB-01',
      'name': 'Memorial Collection',
      'date': '2024-05-03',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/eb01/img_item01.webp',
    },
    {
      'id': '569301',
      'code': 'PRB-01',
      'name': 'One Piece Card The Best',
      'date': '2024-11-08',
      'booster': 'https://en.onepiece-cardgame.com/renewal/images/products/boosters/prb01/img_item01.webp',
    },
  ];

  static Future<List<CardSet>> getAllSets() async {
    return officialPacks.map((p) {
      return CardSet(
        id: 'op_${p['id']}',
        code: p['code']!,
        name: '${p['code']!} ${p['name']!}',
        gameType: GameType.onepiece,
        totalCards: 126,
        releaseDate: p['date'],
        boosterArtUrl: p['booster'],
      );
    }).toList();
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    final cleanCode = setCode.toUpperCase().trim();

    // Find pack id by set code (e.g. OP-05 -> 569105)
    final pack = officialPacks.firstWhere(
      (p) => cleanCode.contains(p['code']!) || p['code']!.contains(cleanCode),
      orElse: () => officialPacks.first,
    );

    final packId = pack['id']!;

    if (_cachedCardsByPack.containsKey(packId) &&
        _cachedCardsByPack[packId]!.isNotEmpty) {
      return _cachedCardsByPack[packId]!;
    }

    try {
      final url = Uri.parse(
          'https://raw.githubusercontent.com/buhbbl/punk-records/main/english/data/$packId.json');
      final res = await http.get(url, headers: {'User-Agent': 'BoosterTCG/1.0'});

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final cards = <CardModel>[];

        for (final item in list) {
          final imgUrl = item['img_full_url'] as String?;
          if (imgUrl == null || imgUrl.isEmpty) continue;

          final name = item['name'] as String? ?? 'One Piece Card';
          final id = item['id'] as String? ?? '';
          final rarityRaw = item['rarity'] as String? ?? 'Common';

          // Official One Piece Rarity Mapping
          Rarity r = Rarity.common;
          final lowerR = rarityRaw.toLowerCase();
          if (lowerR.contains('secret') ||
              lowerR.contains('sec') ||
              lowerR.contains('special') ||
              lowerR.contains('treasure') ||
              lowerR.contains('manga')) {
            r = Rarity.secretRare;
          } else if (lowerR.contains('super') ||
              lowerR == 'sr' ||
              lowerR.contains('leader')) {
            r = Rarity.ultraRare;
          } else if (lowerR.contains('rare') || lowerR == 'r') {
            r = Rarity.rare;
          } else if (lowerR.contains('uncommon') || lowerR == 'uc') {
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
            id: 'op_$id',
            name: name,
            gameType: GameType.onepiece,
            setCode: pack['code']!,
            setName: pack['name']!,
            cardNumber: id,
            rarity: r,
            imageUrl: imgUrl,
            imageHighResUrl: imgUrl,
            foilType: foilType,
            extraData: {
              'category': item['category'] ?? '',
              'colors': item['colors'] ?? [],
              'power': item['power'] ?? '',
              'cost': item['cost'] ?? '',
            },
          ));
        }

        if (cards.isNotEmpty) {
          _cachedCardsByPack[packId] = cards;
          return cards;
        }
      }
    } catch (e) {
      debugPrint('Error loading One Piece cards for $packId: $e');
    }

    return [];
  }
}
