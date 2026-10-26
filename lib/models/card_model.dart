import 'game_type.dart';

enum Rarity {
  common('Common', 1),
  uncommon('Uncommon', 2),
  rare('Rare', 3),
  ultraRare('Ultra Rare', 4),
  secretRare('Secret Rare', 5);

  final String label;
  final int tier;
  const Rarity(this.label, this.tier);

  static Rarity fromString(String? val) {
    if (val == null) return Rarity.common;
    final lower = val.toLowerCase();
    if (lower.contains('secret') || lower.contains('alt') || lower.contains('god') || lower.contains('masterpiece')) {
      return Rarity.secretRare;
    }
    if (lower.contains('ultra') || lower.contains('mythic') || lower.contains('super') || lower.contains('ex') || lower.contains('sr')) {
      return Rarity.ultraRare;
    }
    if (lower.contains('rare') || lower.contains('holo') || lower.contains('r')) {
      return Rarity.rare;
    }
    if (lower.contains('uncommon') || lower.contains('uc')) {
      return Rarity.uncommon;
    }
    return Rarity.common;
  }
}

class CardModel {
  final String id;
  final String name;
  final GameType gameType;
  final String setCode;
  final String setName;
  final String cardNumber;
  final Rarity rarity;
  final String imageUrl;
  final String? imageHighResUrl;
  final String foilType; // 'none', 'holo', 'rainbow', 'gold'
  final Map<String, dynamic> extraData;

  const CardModel({
    required this.id,
    required this.name,
    required this.gameType,
    required this.setCode,
    required this.setName,
    required this.cardNumber,
    required this.rarity,
    required this.imageUrl,
    this.imageHighResUrl,
    this.foilType = 'none',
    this.extraData = const {},
  });

  bool get isHolographic =>
      foilType != 'none' ||
      rarity == Rarity.rare ||
      rarity == Rarity.ultraRare ||
      rarity == Rarity.secretRare;

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      gameType: GameType.fromKey(json['game_type'] as String),
      setCode: json['set_code'] as String,
      setName: json['set_name'] as String? ?? json['set_code'] as String,
      cardNumber: json['card_number']?.toString() ?? '',
      rarity: Rarity.fromString(json['rarity'] as String?),
      imageUrl: json['image_url'] as String,
      imageHighResUrl: json['image_high_res_url'] as String?,
      foilType: json['foil_type'] as String? ?? 'none',
      extraData: json['extra_data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'game_type': gameType.key,
      'set_code': setCode,
      'set_name': setName,
      'card_number': cardNumber,
      'rarity': rarity.label,
      'image_url': imageUrl,
      'image_high_res_url': imageHighResUrl,
      'foil_type': foilType,
      'extra_data': extraData,
    };
  }
}
