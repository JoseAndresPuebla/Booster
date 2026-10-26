import 'dart:math';
import 'card_model.dart';

class PackSlotRule {
  final Map<Rarity, double> probabilities;

  const PackSlotRule(this.probabilities);

  Rarity rollRarity(Random random) {
    double roll = random.nextDouble() * 100.0;
    double cumulative = 0.0;

    for (final entry in probabilities.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) {
        return entry.key;
      }
    }
    return probabilities.keys.last;
  }
}

class PackBlueprint {
  final int cardsPerPack;
  final List<PackSlotRule> slotRules;
  final double godPackChance; // Chance (in %) that all cards are Ultra Rare or higher

  const PackBlueprint({
    this.cardsPerPack = 5,
    required this.slotRules,
    this.godPackChance = 0.5, // 0.5% chance
  });

  /// Standard Pocket-style drop rates:
  /// Slot 1: 100% Common
  /// Slot 2: 100% Common
  /// Slot 3: 80% Common, 20% Uncommon
  /// Slot 4: 85% Uncommon, 15% Rare
  /// Slot 5: 68% Rare, 22% Ultra Rare, 10% Secret Rare
  static const PackBlueprint standardPocket = PackBlueprint(
    cardsPerPack: 5,
    godPackChance: 0.5,
    slotRules: [
      PackSlotRule({Rarity.common: 100.0}),
      PackSlotRule({Rarity.common: 100.0}),
      PackSlotRule({Rarity.common: 80.0, Rarity.uncommon: 20.0}),
      PackSlotRule({Rarity.uncommon: 85.0, Rarity.rare: 15.0}),
      PackSlotRule({
        Rarity.rare: 68.0,
        Rarity.ultraRare: 22.0,
        Rarity.secretRare: 10.0,
      }),
    ],
  );
}
