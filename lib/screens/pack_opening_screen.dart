import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_theme.dart';
import '../core/services/supabase_service.dart';
import '../models/card_model.dart';
import '../models/card_set.dart';
import '../models/game_type.dart';
import '../services/pack_generator_service.dart';
import '../widgets/booster_pack_widget.dart';
import '../widgets/tiltable_card_widget.dart';

enum PackOpeningStage {
  sealed,
  opening,
  revealing,
  summary,
}

class PackOpeningScreen extends StatefulWidget {
  final GameType game;
  final CardSet cardSet;

  const PackOpeningScreen({
    super.key,
    required this.game,
    required this.cardSet,
  });

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen> {
  PackOpeningStage _stage = PackOpeningStage.sealed;
  List<CardModel> _packCards = [];
  int _currentCardIndex = 0;
  final Set<int> _flippedCards = {};
  bool _isSaving = false;
  Future<void>? _cardRollFuture;

  @override
  void initState() {
    super.initState();
    _cardRollFuture = _rollCardsEarly();
  }

  // Pre-generate cards immediately so precaching happens during the tear gesture!
  Future<void> _rollCardsEarly() async {
    try {
      final cards = await PackGeneratorService.generateBoosterPack(
        game: widget.game,
        cardSet: widget.cardSet,
      );

      if (mounted) {
        setState(() {
          _packCards = cards;
        });
        if (cards.isNotEmpty) {
          // Start downloading high-res images in background right now!
          PackGeneratorService.precachePackImages(context, cards);
        }
      }
    } catch (e) {
      debugPrint('Error generating booster pack: $e');
    }
  }

  void _onPackTorn() async {
    setState(() {
      _stage = PackOpeningStage.opening;
    });

    HapticFeedback.vibrate();

    // Wait for card generator if it is still fetching
    if (_packCards.isEmpty && _cardRollFuture != null) {
      await _cardRollFuture!.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
    }

    // Brief suspense delay for the pack burst effect
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _stage = PackOpeningStage.revealing;
      });
    }
  }

  void _flipCard(int index) {
    if (!_flippedCards.contains(index)) {
      setState(() {
        _flippedCards.add(index);
      });

      final card = _packCards[index];
      if (card.rarity.tier >= 4) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _nextCard() {
    if (_currentCardIndex < _packCards.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
    } else {
      _finishOpening();
    }
  }

  void _finishOpening() async {
    setState(() {
      _stage = PackOpeningStage.summary;
      _isSaving = true;
    });

    // Save cards and deduct pack count
    for (final card in _packCards) {
      await SupabaseService.syncCardObtained(card);
    }
    await SupabaseService.recordPackOpened(widget.game);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.cardSet.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: _buildCurrentStage(),
        ),
      ),
    );
  }

  Widget _buildCurrentStage() {
    switch (_stage) {
      case PackOpeningStage.sealed:
        return Center(
          child: BoosterPackWidget(
            cardSet: widget.cardSet,
            onTearComplete: _onPackTorn,
          ),
        );

      case PackOpeningStage.opening:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.game.primaryColor.withOpacity(0.2),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: widget.game.primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Abriendo sobre!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );

      case PackOpeningStage.revealing:
        if (_packCards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'No se pudieron cargar las cartas de esta expansión.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _stage = PackOpeningStage.sealed;
                    });
                    _cardRollFuture = _rollCardsEarly();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        return _buildCardRevealView();

      case PackOpeningStage.summary:
        return _buildSummaryView();
    }
  }

  Widget _buildCardRevealView() {
    final currentCard = _packCards[_currentCardIndex];
    final isFlipped = _flippedCards.contains(_currentCardIndex);

    return Column(
      children: [
        const SizedBox(height: 12),

        // Card Counter: "Carta 3 de 5"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Carta ${_currentCardIndex + 1} de ${_packCards.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),

        const Spacer(),

        // The 3D Interactive Card
        Center(
          child: TiltableCardWidget(
            card: currentCard,
            isFaceUp: isFlipped,
            onTap: () => _flipCard(_currentCardIndex),
            width: 270,
            height: 380,
          ),
        ),

        const SizedBox(height: 16),

        // Rarity Indicator when flipped
        if (isFlipped) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: currentCard.rarity.tier >= 4
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentCard.rarity.tier >= 4
                    ? Colors.amberAccent
                    : Colors.white24,
              ),
            ),
            child: Text(
              currentCard.rarity.label.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 13,
                color: currentCard.rarity.tier >= 4
                    ? Colors.amberAccent
                    : Colors.white70,
              ),
            ),
          ),
        ] else ...[
          const Text(
            'Toca la carta para revelarla',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],

        const Spacer(),

        // Continue Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFlipped
                    ? widget.game.primaryColor
                    : Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isFlipped ? _nextCard : () => _flipCard(_currentCardIndex),
              child: Text(
                !isFlipped
                    ? 'REVELAR CARTA'
                    : (_currentCardIndex < _packCards.length - 1
                        ? 'SIGUIENTE CARTA'
                        : 'VER TODAS'),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '¡SOBRE COMPLETADO!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estas cartas se han añadido a tu álbum de colección',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Grid of 5 opened cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _packCards.length,
              itemBuilder: (context, index) {
                final card = _packCards[index];
                return TiltableCardWidget(
                  card: card,
                  isFaceUp: true,
                  width: 140,
                  height: 200,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pokemonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'GUARDAR EN MI COLECCIÓN',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
