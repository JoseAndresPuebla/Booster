import '../../models/card_model.dart';
import '../../models/card_set.dart';
import '../../models/game_type.dart';

class OnePieceApiService {
  static final Map<String, List<CardModel>> _cachedCardsBySet = {};

  static Future<List<CardSet>> getPopularSets() async {
    return const [
      CardSet(
        id: 'op05',
        code: 'OP05',
        name: 'Awakening of the New Era (Gear 5)',
        gameType: GameType.onepiece,
        totalCards: 126,
        releaseDate: '2023-12-08',
        boosterArtUrl:
            'https://onepiece-cardgame.dev/images/sets/OP-05.png',
      ),
      CardSet(
        id: 'op01',
        code: 'OP01',
        name: 'Romance Dawn',
        gameType: GameType.onepiece,
        totalCards: 121,
        releaseDate: '2022-12-02',
        boosterArtUrl:
            'https://onepiece-cardgame.dev/images/sets/OP-01.png',
      ),
      CardSet(
        id: 'op07',
        code: 'OP07',
        name: '500 Years in the Future',
        gameType: GameType.onepiece,
        totalCards: 126,
        releaseDate: '2024-06-28',
        boosterArtUrl:
            'https://onepiece-cardgame.dev/images/sets/OP-07.png',
      ),
    ];
  }

  static Future<List<CardModel>> getCardsForSet(String setCode) async {
    if (_cachedCardsBySet.containsKey(setCode) &&
        _cachedCardsBySet[setCode]!.isNotEmpty) {
      return _cachedCardsBySet[setCode]!;
    }

    // High quality community card list for One Piece
    final cards = [
      CardModel(
        id: 'optcg_${setCode}_001',
        name: 'Monkey D. Luffy (Gear 5)',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Awakening of the New Era',
        cardNumber: 'OP05-119',
        rarity: Rarity.secretRare,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP05-119_p1.png',
        foilType: 'rainbow',
      ),
      CardModel(
        id: 'optcg_${setCode}_002',
        name: 'Roronoa Zoro',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Romance Dawn',
        cardNumber: 'OP01-025',
        rarity: Rarity.ultraRare,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP01-025.png',
        foilType: 'holo',
      ),
      CardModel(
        id: 'optcg_${setCode}_003',
        name: 'Portgas D. Ace',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Paramount War',
        cardNumber: 'OP02-013',
        rarity: Rarity.rare,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP02-013.png',
        foilType: 'holo',
      ),
      CardModel(
        id: 'optcg_${setCode}_004',
        name: 'Nami',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Romance Dawn',
        cardNumber: 'OP01-016',
        rarity: Rarity.uncommon,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP01-016.png',
      ),
      CardModel(
        id: 'optcg_${setCode}_005',
        name: 'Tony Tony Chopper',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Romance Dawn',
        cardNumber: 'OP01-006',
        rarity: Rarity.common,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP01-006.png',
      ),
      CardModel(
        id: 'optcg_${setCode}_006',
        name: 'Trafalgar Law',
        gameType: GameType.onepiece,
        setCode: setCode,
        setName: 'Romance Dawn',
        cardNumber: 'OP01-047',
        rarity: Rarity.ultraRare,
        imageUrl:
            'https://onepiece-cardgame.dev/images/cards/OP01-047.png',
        foilType: 'holo',
      ),
    ];

    _cachedCardsBySet[setCode] = cards;
    return cards;
  }
}
