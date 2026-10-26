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

  // 47 Official Magic: The Gathering Expansions with verified MTGJSON booster pack wrappers
  static const List<CardSet> officialSets = [
    CardSet(
      id: 'mtg_blb',
      code: 'BLB',
      name: 'Bloomburrow',
      gameType: GameType.magic,
      totalCards: 261,
      releaseDate: '2024-08-02',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541237.jpg',
    ),
    CardSet(
      id: 'mtg_mh3',
      code: 'MH3',
      name: 'Modern Horizons 3',
      gameType: GameType.magic,
      totalCards: 261,
      releaseDate: '2024-06-14',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541173.jpg',
    ),
    CardSet(
      id: 'mtg_otj',
      code: 'OTJ',
      name: 'Outlaws of Thunder Junction',
      gameType: GameType.magic,
      totalCards: 276,
      releaseDate: '2024-04-19',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/541086.jpg',
    ),
    CardSet(
      id: 'mtg_fdn',
      code: 'FDN',
      name: 'Magic Foundations',
      gameType: GameType.magic,
      totalCards: 361,
      releaseDate: '2024-11-15',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/562121.jpg',
    ),
    CardSet(
      id: 'mtg_mkm',
      code: 'MKM',
      name: 'Murders at Karlov Manor',
      gameType: GameType.magic,
      totalCards: 286,
      releaseDate: '2024-02-09',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/529967.jpg',
    ),
    CardSet(
      id: 'mtg_lci',
      code: 'LCI',
      name: 'The Lost Caverns of Ixalan',
      gameType: GameType.magic,
      totalCards: 291,
      releaseDate: '2023-11-17',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/516613.jpg',
    ),
    CardSet(
      id: 'mtg_woe',
      code: 'WOE',
      name: 'Wilds of Eldraine',
      gameType: GameType.magic,
      totalCards: 276,
      releaseDate: '2023-09-08',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/496040.jpg',
    ),
    CardSet(
      id: 'mtg_mom',
      code: 'MOM',
      name: 'March of the Machine',
      gameType: GameType.magic,
      totalCards: 281,
      releaseDate: '2023-04-21',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/475583.jpg',
    ),
    CardSet(
      id: 'mtg_one',
      code: 'ONE',
      name: 'Phyrexia: All Will Be One',
      gameType: GameType.magic,
      totalCards: 271,
      releaseDate: '2023-02-10',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/451879.jpg',
    ),
    CardSet(
      id: 'mtg_bro',
      code: 'BRO',
      name: "The Brothers' War",
      gameType: GameType.magic,
      totalCards: 287,
      releaseDate: '2022-11-18',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/282223.jpg',
    ),
    CardSet(
      id: 'mtg_dmu',
      code: 'DMU',
      name: 'Dominaria United',
      gameType: GameType.magic,
      totalCards: 281,
      releaseDate: '2022-09-09',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/286610.jpg',
    ),
    CardSet(
      id: 'mtg_snc',
      code: 'SNC',
      name: 'Streets of New Capenna',
      gameType: GameType.magic,
      totalCards: 281,
      releaseDate: '2022-04-29',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/281723.jpg',
    ),
    CardSet(
      id: 'mtg_neo',
      code: 'NEO',
      name: 'Kamigawa: Neon Dynasty',
      gameType: GameType.magic,
      totalCards: 302,
      releaseDate: '2022-02-18',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/257562.jpg',
    ),
    CardSet(
      id: 'mtg_vow',
      code: 'VOW',
      name: 'Innistrad: Crimson Vow',
      gameType: GameType.magic,
      totalCards: 277,
      releaseDate: '2021-11-19',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/257132.jpg',
    ),
    CardSet(
      id: 'mtg_mid',
      code: 'MID',
      name: 'Innistrad: Midnight Hunt',
      gameType: GameType.magic,
      totalCards: 277,
      releaseDate: '2021-09-24',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/281713.jpg',
    ),
    CardSet(
      id: 'mtg_mh2',
      code: 'MH2',
      name: 'Modern Horizons 2',
      gameType: GameType.magic,
      totalCards: 303,
      releaseDate: '2021-06-18',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/450139.jpg',
    ),
    CardSet(
      id: 'mtg_stx',
      code: 'STX',
      name: 'Strixhaven: School of Mages',
      gameType: GameType.magic,
      totalCards: 275,
      releaseDate: '2021-04-23',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/236690.jpg',
    ),
    CardSet(
      id: 'mtg_khm',
      code: 'KHM',
      name: 'Kaldheim',
      gameType: GameType.magic,
      totalCards: 285,
      releaseDate: '2021-02-05',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/236691.jpg',
    ),
    CardSet(
      id: 'mtg_cmr',
      code: 'CMR',
      name: 'Commander Legends',
      gameType: GameType.magic,
      totalCards: 361,
      releaseDate: '2020-11-20',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/236692.jpg',
    ),
    CardSet(
      id: 'mtg_znr',
      code: 'ZNR',
      name: 'Zendikar Rising',
      gameType: GameType.magic,
      totalCards: 280,
      releaseDate: '2020-09-25',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/236693.jpg',
    ),
    CardSet(
      id: 'mtg_m21',
      code: 'M21',
      name: 'Core Set 2021',
      gameType: GameType.magic,
      totalCards: 274,
      releaseDate: '2020-07-03',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/215325.jpg',
    ),
    CardSet(
      id: 'mtg_iko',
      code: 'IKO',
      name: 'Ikoria: Lair of Behemoths',
      gameType: GameType.magic,
      totalCards: 274,
      releaseDate: '2020-04-24',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/214395.jpg',
    ),
    CardSet(
      id: 'mtg_thb',
      code: 'THB',
      name: 'Theros Beyond Death',
      gameType: GameType.magic,
      totalCards: 254,
      releaseDate: '2020-01-24',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/206254.jpg',
    ),
    CardSet(
      id: 'mtg_eld',
      code: 'ELD',
      name: 'Throne of Eldraine',
      gameType: GameType.magic,
      totalCards: 269,
      releaseDate: '2019-10-04',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/243105.jpg',
    ),
    CardSet(
      id: 'mtg_mh1',
      code: 'MH1',
      name: 'Modern Horizons',
      gameType: GameType.magic,
      totalCards: 255,
      releaseDate: '2019-06-14',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/185892.jpg',
    ),
    CardSet(
      id: 'mtg_war',
      code: 'WAR',
      name: 'War of the Spark',
      gameType: GameType.magic,
      totalCards: 264,
      releaseDate: '2019-05-03',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/185677.jpg',
    ),
    CardSet(
      id: 'mtg_rna',
      code: 'RNA',
      name: 'Ravnica Allegiance',
      gameType: GameType.magic,
      totalCards: 259,
      releaseDate: '2019-01-25',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/180735.jpg',
    ),
    CardSet(
      id: 'mtg_grn',
      code: 'GRN',
      name: 'Guilds of Ravnica',
      gameType: GameType.magic,
      totalCards: 259,
      releaseDate: '2018-10-05',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/173364.jpg',
    ),
    CardSet(
      id: 'mtg_m19',
      code: 'M19',
      name: 'Core Set 2019',
      gameType: GameType.magic,
      totalCards: 280,
      releaseDate: '2018-07-13',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/166551.jpg',
    ),
    CardSet(
      id: 'mtg_dom',
      code: 'DOM',
      name: 'Dominaria',
      gameType: GameType.magic,
      totalCards: 269,
      releaseDate: '2018-04-27',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/158425.jpg',
    ),
    CardSet(
      id: 'mtg_rix',
      code: 'RIX',
      name: 'Rivals of Ixalan',
      gameType: GameType.magic,
      totalCards: 196,
      releaseDate: '2018-01-19',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/149405.jpg',
    ),
    CardSet(
      id: 'mtg_xln',
      code: 'XLN',
      name: 'Ixalan',
      gameType: GameType.magic,
      totalCards: 279,
      releaseDate: '2017-09-29',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/141991.jpg',
    ),
    CardSet(
      id: 'mtg_hou',
      code: 'HOU',
      name: 'Hour of Devastation',
      gameType: GameType.magic,
      totalCards: 199,
      releaseDate: '2017-07-14',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/131457.jpg',
    ),
    CardSet(
      id: 'mtg_akh',
      code: 'AKH',
      name: 'Amonkhet',
      gameType: GameType.magic,
      totalCards: 269,
      releaseDate: '2017-04-28',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/127173.jpg',
    ),
    CardSet(
      id: 'mtg_aer',
      code: 'AER',
      name: 'Aether Revolt',
      gameType: GameType.magic,
      totalCards: 184,
      releaseDate: '2017-01-20',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/125793.jpg',
    ),
    CardSet(
      id: 'mtg_kld',
      code: 'KLD',
      name: 'Kaladesh',
      gameType: GameType.magic,
      totalCards: 264,
      releaseDate: '2016-09-30',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/121529.jpg',
    ),
    CardSet(
      id: 'mtg_emn',
      code: 'EMN',
      name: 'Eldritch Moon',
      gameType: GameType.magic,
      totalCards: 205,
      releaseDate: '2016-07-22',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/118394.jpg',
    ),
    CardSet(
      id: 'mtg_soi',
      code: 'SOI',
      name: 'Shadows over Innistrad',
      gameType: GameType.magic,
      totalCards: 297,
      releaseDate: '2016-04-08',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/112708.jpg',
    ),
    CardSet(
      id: 'mtg_ogw',
      code: 'OGW',
      name: 'Oath of the Gatewatch',
      gameType: GameType.magic,
      totalCards: 184,
      releaseDate: '2016-01-22',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/110420.jpg',
    ),
    CardSet(
      id: 'mtg_bfz',
      code: 'BFZ',
      name: 'Battle for Zendikar',
      gameType: GameType.magic,
      totalCards: 274,
      releaseDate: '2015-10-02',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/102716.jpg',
    ),
    CardSet(
      id: 'mtg_dtk',
      code: 'DTK',
      name: 'Dragons of Tarkir',
      gameType: GameType.magic,
      totalCards: 264,
      releaseDate: '2015-03-27',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/96139.jpg',
    ),
    CardSet(
      id: 'mtg_frf',
      code: 'FRF',
      name: 'Fate Reforged',
      gameType: GameType.magic,
      totalCards: 185,
      releaseDate: '2015-01-23',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/95031.jpg',
    ),
    CardSet(
      id: 'mtg_ktk',
      code: 'KTK',
      name: 'Khans of Tarkir',
      gameType: GameType.magic,
      totalCards: 269,
      releaseDate: '2014-09-26',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/91653.jpg',
    ),
    CardSet(
      id: 'mtg_isd',
      code: 'ISD',
      name: 'Innistrad (Original)',
      gameType: GameType.magic,
      totalCards: 264,
      releaseDate: '2011-09-30',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/47787.jpg',
    ),
    CardSet(
      id: 'mtg_zen',
      code: 'ZEN',
      name: 'Zendikar (Original)',
      gameType: GameType.magic,
      totalCards: 249,
      releaseDate: '2009-10-02',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/32791.jpg',
    ),
    CardSet(
      id: 'mtg_wwk',
      code: 'WWK',
      name: 'Worldwake',
      gameType: GameType.magic,
      totalCards: 145,
      releaseDate: '2010-02-05',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/34469.jpg',
    ),
    CardSet(
      id: 'mtg_roe',
      code: 'ROE',
      name: 'Rise of the Eldrazi',
      gameType: GameType.magic,
      totalCards: 248,
      releaseDate: '2010-04-23',
      boosterArtUrl: 'https://product-images.tcgplayer.com/fit-in/437x437/34680.jpg',
    ),
  ];

  static final Map<String, String> _knownBoosterArts = {
    for (final s in officialSets)
      if (s.boosterArtUrl != null && s.boosterArtUrl!.isNotEmpty)
        s.code.toLowerCase(): s.boosterArtUrl!,
  };

  /// Returns ALL official Magic sets dynamically from Scryfall API,
  /// matching booster pack wrappers where available, and falling back to officialSets offline.
  static Future<List<CardSet>> getAllSets() async {
    if (_cachedSets != null && _cachedSets!.isNotEmpty) {
      return _cachedSets!;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.scryfallBaseUrl}/sets'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>? ?? [];

        final sets = <CardSet>[];
        final now = DateTime.now();

        for (final item in list) {
          if (item is! Map<String, dynamic>) continue;
          final code = item['code']?.toString() ?? '';
          final name = item['name']?.toString() ?? code;
          final count = item['card_count'] as int? ?? 0;
          final type = item['set_type']?.toString() ?? '';
          final release = item['released_at']?.toString();
          final iconSvg = item['icon_svg_uri']?.toString();

          if (count < 10) continue;
          if (release != null) {
            final rel = DateTime.tryParse(release);
            if (rel != null && rel.isAfter(now)) continue;
          }

          final isStandardSet = type == 'expansion' ||
              type == 'core' ||
              type == 'masters' ||
              type == 'draft_innovation' ||
              type == 'funny';

          if (!isStandardSet) continue;

          final cleanCode = code.toLowerCase();
          final boosterArt = _knownBoosterArts[cleanCode];

          sets.add(CardSet(
            id: 'mtg_$code',
            code: code,
            name: name,
            gameType: GameType.magic,
            totalCards: count,
            releaseDate: release,
            iconUrl: iconSvg,
            boosterArtUrl:
                boosterArt, // Null if no cover, BoosterPackWidget renders procedural
          ));
        }

        if (sets.isNotEmpty) {
          _cachedSets = sets;
          return sets;
        }
      }
    } catch (e) {
      debugPrint('Error fetching MTG sets from Scryfall: $e');
    }

    _cachedSets = List<CardSet>.from(officialSets);
    return _cachedSets!;
  }

  static List<CardSet> getFallbackSets() {
    return officialSets;
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
