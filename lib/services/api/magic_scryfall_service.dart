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
          '${ApiConstants.scryfallBaseUrl}/cards/search?q=set:$cleanCode+is:booster&order=rarity');
      final res = await http.get(url, headers: _headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];

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

        if (cards.isNotEmpty) {
          _cachedCardsBySet[cleanCode] = cards;
          return cards;
        }
      } else {
        debugPrint('Scryfall returned status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error fetching MTG cards for set $cleanCode: $e');
    }

    return [];
  }
}
