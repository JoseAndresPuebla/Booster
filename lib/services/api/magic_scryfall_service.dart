import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class MagicScryfallService {
  // Cache of cards per set code to avoid repeated network calls
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};

  static Future<List<CardSet>> getPopularSets() async {
    // Curated high-popularity modern sets for opening
    return const [
      CardSet(
        id: 'blb',
        code: 'blb',
        name: 'Bloomburrow',
        gameType: GameType.magic,
        totalCards: 261,
        releaseDate: '2024-08-02',
        boosterArtUrl:
            'https://cards.scryfall.io/large/front/d/e/de522a1b-1991-460f-b040-398df903932a.jpg',
      ),
      CardSet(
        id: 'mh3',
        code: 'mh3',
        name: 'Modern Horizons 3',
        gameType: GameType.magic,
        totalCards: 261,
        releaseDate: '2024-06-14',
        boosterArtUrl:
            'https://cards.scryfall.io/large/front/4/a/4a1c6e18-5a96-4740-9799-52834b953a15.jpg',
      ),
      CardSet(
        id: 'otj',
        code: 'otj',
        name: 'Outlaws of Thunder Junction',
        gameType: GameType.magic,
        totalCards: 276,
        releaseDate: '2024-04-19',
        boosterArtUrl:
            'https://cards.scryfall.io/large/front/6/b/6b579133-72a0-482a-a92c-0e86b4618e53.jpg',
      ),
      CardSet(
        id: 'neo',
        code: 'neo',
        name: 'Kamigawa: Neon Dynasty',
        gameType: GameType.magic,
        totalCards: 302,
        releaseDate: '2022-02-18',
        boosterArtUrl:
            'https://cards.scryfall.io/large/front/0/8/087ec80b-70c8-47c3-8f55-14f762a4ebf0.jpg',
      ),
    ];
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    if (_cachedCardsBySet.containsKey(setCode) &&
        _cachedCardsBySet[setCode]!.isNotEmpty) {
      return _cachedCardsBySet[setCode]!;
    }

    try {
      final url = Uri.parse(
          '${ApiConstants.scryfallBaseUrl}/cards/search?q=set:$setCode+is:booster&order=rarity');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];

        final cards = list.map((item) {
          final imageUris = item['image_uris'] as Map<String, dynamic>?;
          final imageUrl = imageUris?['normal'] ??
              imageUris?['large'] ??
              GameType.magic.defaultCardBackUrl;

          final highRes = imageUris?['large'] ?? imageUrl;

          return CardModel(
            id: 'mtg_${item['id']}',
            name: item['name'] as String? ?? 'Card',
            gameType: GameType.magic,
            setCode: setCode.toUpperCase(),
            setName: item['set_name'] as String? ?? setCode.toUpperCase(),
            cardNumber: item['collector_number']?.toString() ?? '0',
            rarity: Rarity.fromString(item['rarity'] as String?),
            imageUrl: imageUrl as String,
            imageHighResUrl: highRes as String,
            foilType: item['foil'] == true ? 'holo' : 'none',
            extraData: {
              'mana_cost': item['mana_cost'],
              'type_line': item['type_line'],
            },
          );
        }).toList();

        _cachedCardsBySet[setCode] = cards;
        return cards;
      }
    } catch (e) {
      debugPrint('Error fetching MTG cards: $e');
    }

    return _getFallbackMtgCards(setCode);
  }

  static List<CardModel> _getFallbackMtgCards(String setCode) {
    return [
      CardModel(
        id: 'mtg_flb_1',
        name: 'Black Lotus',
        gameType: GameType.magic,
        setCode: setCode,
        setName: 'Masterpiece',
        cardNumber: '001',
        rarity: Rarity.secretRare,
        imageUrl:
            'https://cards.scryfall.io/large/front/b/d/bd8fa327-dd41-4737-8f19-2cf5eb1f7cdd.jpg',
        foilType: 'rainbow',
      ),
      CardModel(
        id: 'mtg_flb_2',
        name: 'Lightning Bolt',
        gameType: GameType.magic,
        setCode: setCode,
        setName: 'Standard',
        cardNumber: '002',
        rarity: Rarity.common,
        imageUrl:
            'https://cards.scryfall.io/large/front/f/2/f29ba16f-c8fb-42fe-aabf-87089cb214a7.jpg',
      ),
      CardModel(
        id: 'mtg_flb_3',
        name: 'Counterspell',
        gameType: GameType.magic,
        setCode: setCode,
        setName: 'Standard',
        cardNumber: '003',
        rarity: Rarity.uncommon,
        imageUrl:
            'https://cards.scryfall.io/large/front/a/9/a97b9766-d0a3-4c5b-b915-2a233e7dc915.jpg',
      ),
      CardModel(
        id: 'mtg_flb_4',
        name: 'Wrath of God',
        gameType: GameType.magic,
        setCode: setCode,
        setName: 'Standard',
        cardNumber: '004',
        rarity: Rarity.rare,
        imageUrl:
            'https://cards.scryfall.io/large/front/6/6/664e6656-36a3-4635-9f33-92890c204277.jpg',
        foilType: 'holo',
      ),
    ];
  }
}
