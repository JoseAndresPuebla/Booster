import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_set.dart';
import '../models/game_type.dart';
import '../models/pack_blueprint.dart';
import 'api/magic_scryfall_service.dart';
import 'api/pokemon_tcgdex_service.dart';
import 'api/onepiece_api_service.dart';
import 'api/riftbound_service.dart';
import 'api/wwe_topps_service.dart';

class PackGeneratorService {
  static final Random _random = Random();

  // Unified Set Loader
  static Future<List<CardSet>> getSetsForGame(GameType game) async {
    switch (game) {
      case GameType.pokemon:
        return PokemonTcgDexService.getAllSets();
      case GameType.magic:
        return MagicScryfallService.getAllSets();
      case GameType.onepiece:
        return OnePieceApiService.getAllSets();
      case GameType.riftbound:
        return RiftboundService.getAllSets();
      case GameType.wwe:
        return WweToppsService.getAllSets();
    }
  }

  // Unified Card Pool Loader
  static Future<List<CardModel>> getCardsForSet(
      GameType game, String setCode) async {
    switch (game) {
      case GameType.pokemon:
        return PokemonTcgDexService.getCardsForSet(setCode);
      case GameType.magic:
        return MagicScryfallService.getCardsForSet(setCode);
      case GameType.onepiece:
        return OnePieceApiService.getCardsForSet(setCode);
      case GameType.riftbound:
        return RiftboundService.getCardsForSet(setCode);
      case GameType.wwe:
        return WweToppsService.getCardsForSet(setCode);
    }
  }

  /// Generates a realistic 5-card booster pack using official probability distributions
  static Future<List<CardModel>> generateBoosterPack({
    required GameType game,
    required CardSet cardSet,
    PackBlueprint blueprint = PackBlueprint.standardPocket,
  }) async {
    final pool = await getCardsForSet(game, cardSet.code);
    if (pool.isEmpty) return [];

    // Group cards by rarity
    final Map<Rarity, List<CardModel>> byRarity = {
      Rarity.common: [],
      Rarity.uncommon: [],
      Rarity.rare: [],
      Rarity.ultraRare: [],
      Rarity.secretRare: [],
    };

    for (final card in pool) {
      byRarity[card.rarity]?.add(card);
    }

    // Ensure non-empty fallback lists
    for (final rarity in Rarity.values) {
      if (byRarity[rarity]!.isEmpty) {
        byRarity[rarity] = pool;
      }
    }

    final List<CardModel> pack = [];
    final Set<String> pickedCardIds = {};

    // 1. Check for God Pack (0.5% chance where all 5 cards are Ultra or Secret Rare)
    final bool isGodPack =
        (_random.nextDouble() * 100.0) <= blueprint.godPackChance;

    if (isGodPack) {
      for (int i = 0; i < blueprint.cardsPerPack; i++) {
        final highTier = _random.nextBool() ? Rarity.ultraRare : Rarity.secretRare;
        final list = byRarity[highTier]!;
        final nonDup = list.where((c) => !pickedCardIds.contains(c.id)).toList();
        final pickPool = nonDup.isNotEmpty ? nonDup : list;
        final picked = pickPool[_random.nextInt(pickPool.length)];
        pickedCardIds.add(picked.id);
        pack.add(picked);
      }
      return pack;
    }

    // 2. Standard slot-by-slot generation (No duplicates in same pack)
    for (int slot = 0; slot < blueprint.cardsPerPack; slot++) {
      final rule = blueprint.slotRules[slot];
      final targetRarity = rule.rollRarity(_random);

      final candidates = byRarity[targetRarity]!;
      final nonDup = candidates.where((c) => !pickedCardIds.contains(c.id)).toList();
      final pickPool = nonDup.isNotEmpty ? nonDup : candidates;

      final picked = pickPool[_random.nextInt(pickPool.length)];
      pickedCardIds.add(picked.id);
      pack.add(picked);
    }

    return pack;
  }

  /// Just-In-Time Precaching: Preloads the 5 card images during the pack tearing animation
  static Future<void> precachePackImages(
    BuildContext context,
    List<CardModel> cards,
  ) async {
    final futures = cards.map((card) {
      return precacheImage(
        NetworkImage(card.imageUrl),
        context,
      ).catchError((_) {
        // Fallback gracefully on image network error
      });
    });

    await Future.wait(futures);
  }
}
