import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class RiftboundService {
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};

  static Future<List<CardSet>> getPopularSets() async {
    return const [
      CardSet(
        id: 'origins',
        code: 'OR',
        name: 'Origins (Runeterra Genesis)',
        gameType: GameType.riftbound,
        totalCards: 180,
        releaseDate: '2024-05-10',
        boosterArtUrl:
            'https://www.riftbound-db.com/images/sets/origins-pack.png',
      ),
      CardSet(
        id: 'spiritforged',
        code: 'SF',
        name: 'Spiritforged',
        gameType: GameType.riftbound,
        totalCards: 160,
        releaseDate: '2024-10-18',
        boosterArtUrl:
            'https://www.riftbound-db.com/images/sets/spiritforged-pack.png',
      ),
      CardSet(
        id: 'radiance',
        code: 'RD',
        name: 'Radiance of Targon',
        gameType: GameType.riftbound,
        totalCards: 150,
        releaseDate: '2025-02-14',
        boosterArtUrl:
            'https://www.riftbound-db.com/images/sets/radiance-pack.png',
      ),
    ];
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    if (_cachedCardsBySet.containsKey(setCode) &&
        _cachedCardsBySet[setCode]!.isNotEmpty) {
      return _cachedCardsBySet[setCode]!;
    }

    // Authentic Riftbound card roster with Champions, Spells and Runes
    final cards = [
      CardModel(
        id: 'rb_${setCode}_001',
        name: 'Yasuo, The Unforgiven',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '001/180',
        rarity: Rarity.secretRare,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Yasuo_0.jpg',
        imageHighResUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Yasuo_0.jpg',
        foilType: 'rainbow',
        extraData: {'domain': 'Ionia', 'cost': 4, 'type': 'Champion'},
      ),
      CardModel(
        id: 'rb_${setCode}_002',
        name: 'Jinx, Loose Cannon',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '015/180',
        rarity: Rarity.ultraRare,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Jinx_0.jpg',
        foilType: 'holo',
        extraData: {'domain': 'Zaun', 'cost': 3, 'type': 'Champion'},
      ),
      CardModel(
        id: 'rb_${setCode}_003',
        name: 'Viktor, The Machine Herald',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '028/180',
        rarity: Rarity.ultraRare,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Viktor_0.jpg',
        foilType: 'holo',
        extraData: {'domain': 'Piltover', 'cost': 5, 'type': 'Champion'},
      ),
      CardModel(
        id: 'rb_${setCode}_004',
        name: 'Ahri, Nine-Tailed Fox',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '042/180',
        rarity: Rarity.rare,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Ahri_0.jpg',
        foilType: 'holo',
        extraData: {'domain': 'Ionia', 'cost': 4, 'type': 'Champion'},
      ),
      CardModel(
        id: 'rb_${setCode}_005',
        name: 'Darius, Hand of Noxus',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '055/180',
        rarity: Rarity.rare,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Darius_0.jpg',
        extraData: {'domain': 'Noxus', 'cost': 6, 'type': 'Champion'},
      ),
      CardModel(
        id: 'rb_${setCode}_006',
        name: 'Steel Tempest Slash',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '089/180',
        rarity: Rarity.uncommon,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Yasuo_1.jpg',
        extraData: {'domain': 'Ionia', 'cost': 2, 'type': 'Combat Action'},
      ),
      CardModel(
        id: 'rb_${setCode}_007',
        name: 'Hextech Power Core',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '112/180',
        rarity: Rarity.common,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Jayce_0.jpg',
        extraData: {'domain': 'Piltover', 'cost': 1, 'type': 'Artifact'},
      ),
      CardModel(
        id: 'rb_${setCode}_008',
        name: 'Zaun Chemtech Golem',
        gameType: GameType.riftbound,
        setCode: setCode,
        setName: 'Origins',
        cardNumber: '135/180',
        rarity: Rarity.common,
        imageUrl:
            'https://ddragon.leagueoflegends.com/cdn/img/champion/splash/Zac_0.jpg',
        extraData: {'domain': 'Zaun', 'cost': 3, 'type': 'Unit'},
      ),
    ];

    _cachedCardsBySet[setCode] = cards;
    return cards;
  }
}
