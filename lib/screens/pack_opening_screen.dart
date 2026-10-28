import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  PackOpeningStage _stage = PackOpeningStage.sealed;
  List<CardModel> _packCards = [];
  int _currentCardIndex = 0;
  final Set<int> _flippedCards = {};
  bool _isSaving = false;
  Future<void>? _cardRollFuture;

  // Swipe-to-dismiss gesture state
  double _dragX = 0.0;
  bool _isDismissing = false;
  late AnimationController _swipeController;
  Animation<double>? _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _cardRollFuture = _rollCardsEarly();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
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

    // Pre-flip all cards except the first one (card 0)
    // Only the first card starts face down; cards 1..N will be face up as swiped!
    _flippedCards.clear();
    for (int i = 1; i < _packCards.length; i++) {
      _flippedCards.add(i);
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

  void _dismissCard({double velocity = 0.0, double direction = 1.0}) {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });
    HapticFeedback.lightImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = direction >= 0 ? screenWidth * 1.3 : -screenWidth * 1.3;

    _swipeAnimation = Tween<double>(
      begin: _dragX,
      end: targetX,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _swipeController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      _flippedCards.add(_currentCardIndex);
      if (_currentCardIndex < _packCards.length - 1) {
        setState(() {
          _currentCardIndex++;
          _dragX = 0.0;
          _isDismissing = false;
        });
        _swipeController.reset();

        final nextCard = _packCards[_currentCardIndex];
        if (nextCard.rarity.tier >= 4) {
          HapticFeedback.heavyImpact();
        }
      } else {
        _finishOpening();
      }
    });
  }

  void _snapBack() {
    _swipeAnimation = Tween<double>(
      begin: _dragX,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutBack,
    ));
    _swipeController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _dragX = 0.0;
      });
      _swipeController.reset();
    });
  }

  void _nextCard() {
    _dismissCard(direction: 1.0);
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withOpacity(0.85),
        elevation: 0,
        title: Text(
          widget.cardSet.name,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Dynamic Spotlight
          Positioned(
            top: -40,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.game.primaryColor.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _buildCurrentStage(),
            ),
          ),
        ],
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
              Text(
                '¡Abriendo sobre!',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.textPrimary,
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
            color: AppTheme.surfaceContainerHigh.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Text(
            'CARTA ${_currentCardIndex + 1} DE ${_packCards.length}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.0,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        const Spacer(),

        // The Card Stack with Swipe Gestures
        Center(
          child: SizedBox(
            width: 270,
            height: 380,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Next card underneath (already face up!)
                if (_currentCardIndex + 1 < _packCards.length)
                  Transform.scale(
                    scale: 0.94,
                    child: Opacity(
                      opacity: 0.75,
                      child: TiltableCardWidget(
                        key: ValueKey('pack_card_${_currentCardIndex + 1}'),
                        card: _packCards[_currentCardIndex + 1],
                        isFaceUp: _flippedCards.contains(_currentCardIndex + 1),
                        enablePanTilt: false,
                        width: 270,
                        height: 380,
                      ),
                    ),
                  ),

                // Top active card
                GestureDetector(
                  onTap: () {
                    if (!_flippedCards.contains(_currentCardIndex)) {
                      _flipCard(_currentCardIndex);
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_isDismissing) return;
                    setState(() {
                      _dragX += details.delta.dx;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isDismissing) return;
                    final velocity = details.primaryVelocity ?? 0.0;
                    if (_dragX.abs() > 80 || velocity.abs() > 400) {
                      final dir = velocity.abs() > 400
                          ? (velocity > 0 ? 1.0 : -1.0)
                          : (_dragX > 0 ? 1.0 : -1.0);
                      _dismissCard(velocity: velocity, direction: dir);
                    } else {
                      _snapBack();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _swipeController,
                    builder: (context, child) {
                      final currentX = _isDismissing || _swipeController.isAnimating
                          ? (_swipeAnimation?.value ?? _dragX)
                          : _dragX;
                      final rotation = currentX * 0.0006;

                      return Transform.translate(
                        offset: Offset(currentX, 0),
                        child: Transform.rotate(
                          angle: rotation,
                          child: child,
                        ),
                      );
                    },
                    child: TiltableCardWidget(
                      key: ValueKey('pack_card_$_currentCardIndex'),
                      card: currentCard,
                      isFaceUp: isFlipped,
                      enablePanTilt: false,
                      onTap: () => _flipCard(_currentCardIndex),
                      width: 270,
                      height: 380,
                    ),
                  ),
                ),
              ],
            ),
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
                  : AppTheme.surfaceContainerHigh.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: currentCard.rarity.tier >= 4
                    ? Colors.amberAccent
                    : AppTheme.glassBorder,
                width: 1.2,
              ),
              boxShadow: currentCard.rarity.tier >= 4
                  ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.3), blurRadius: 12)]
                  : null,
            ),
            child: Text(
              currentCard.rarity.label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 12,
                color: currentCard.rarity.tier >= 4
                    ? Colors.amberAccent
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Desliza hacia un lado para la siguiente carta ➔',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
          ),
        ] else ...[
          Text(
            'Toca la carta para revelarla (o desliza hacia un lado)',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
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
                    : AppTheme.surfaceContainerHigh,
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
                style: GoogleFonts.outfit(
                  color: isFlipped ? Colors.black : AppTheme.textPrimary,
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
          Text(
            '¡SOBRE COMPLETADO!',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estas cartas se han añadido a tu álbum de colección',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
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
                backgroundColor: widget.game.primaryColor,
                elevation: 4,
                shadowColor: widget.game.primaryColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      'GUARDAR EN MI COLECCIÓN',
                      style: GoogleFonts.outfit(
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
