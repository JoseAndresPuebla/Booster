import 'game_type.dart';

class CardSet {
  final String id;
  final String code;
  final String name;
  final GameType gameType;
  final int totalCards;
  final String? releaseDate;
  final String? iconUrl;
  final String? boosterArtUrl;

  const CardSet({
    required this.id,
    required this.code,
    required this.name,
    required this.gameType,
    this.totalCards = 0,
    this.releaseDate,
    this.iconUrl,
    this.boosterArtUrl,
  });

  factory CardSet.fromJson(Map<String, dynamic> json) {
    return CardSet(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      gameType: GameType.fromKey(json['game_type'] as String),
      totalCards: json['total_cards'] as int? ?? 0,
      releaseDate: json['release_date'] as String?,
      iconUrl: json['icon_url'] as String?,
      boosterArtUrl: json['booster_art_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'game_type': gameType.key,
      'total_cards': totalCards,
      'release_date': releaseDate,
      'icon_url': iconUrl,
      'booster_art_url': boosterArtUrl,
    };
  }
}
