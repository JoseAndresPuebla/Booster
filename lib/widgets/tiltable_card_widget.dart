import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../models/game_type.dart';

class TiltableCardWidget extends StatefulWidget {
  final CardModel card;
  final bool isFaceUp;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const TiltableCardWidget({
    super.key,
    required this.card,
    this.isFaceUp = true,
    this.onTap,
    this.width = 240,
    this.height = 340,
  });

  @override
  State<TiltableCardWidget> createState() => _TiltableCardWidgetState();
}

class _TiltableCardWidgetState extends State<TiltableCardWidget>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    if (widget.isFaceUp) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TiltableCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFaceUp != oldWidget.isFaceUp) {
      if (widget.isFaceUp) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _tiltY += details.delta.dx * 0.005;
      _tiltX -= details.delta.dy * 0.005;
      _tiltX = _tiltX.clamp(-0.4, 0.4);
      _tiltY = _tiltY.clamp(-0.4, 0.4);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final flipAngle = _flipAnimation.value * pi;
          final isUnder = flipAngle > (pi / 2);

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // 3D Perspective
            ..rotateX(_tiltX)
            ..rotateY(_tiltY + flipAngle);

          return Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: isUnder
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFront(),
                  )
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.card.rarity.tier >= 3
                ? Colors.amber.withOpacity(0.3)
                : Colors.black.withOpacity(0.5),
            blurRadius: 18,
            offset: Offset(_tiltY * 30, _tiltX * 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card Artwork
            CachedNetworkImage(
              imageUrl: widget.card.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildCardBack(),
              errorWidget: (context, url, error) => _buildCardBack(),
            ),

            // Holographic / Foil Layer if rare or holo
            if (widget.card.isHolographic)
              _buildHolographicFoilOverlay(),

            // Border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.card.rarity.tier >= 4
                      ? Colors.amberAccent.withOpacity(0.7)
                      : Colors.white24,
                  width: widget.card.rarity.tier >= 4 ? 2.0 : 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Procedural stylized Card Back by Game
            _buildProceduralGameCardBack(widget.card.gameType),

            // Optional online image overlay if available
            if (widget.card.gameType.defaultCardBackUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.card.gameType.defaultCardBackUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                placeholder: (_, __) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduralGameCardBack(GameType game) {
    switch (game) {
      case GameType.onepiece:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF071426), Color(0xFF0F2647), Color(0xFF071426)],
            ),
            border: Border.all(color: const Color(0xFFD4AF37), width: 3.5),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
                    color: const Color(0xFF0A1C36),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.anchor_rounded,
                      size: 44,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ONE PIECE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'CARD GAME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );

      case GameType.riftbound:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF03141F), Color(0xFF0B2E42), Color(0xFF03141F)],
            ),
            border: Border.all(color: const Color(0xFF00E5FF), width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.change_history_rounded,
                      size: 46,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RIFTBOUND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'LEAGUE OF LEGENDS TCG',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        );

      case GameType.magic:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B1410), Color(0xFF2C221B), Color(0xFF1B1410)],
            ),
            border: Border.all(color: const Color(0xFF9E784F), width: 4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 5 Mana dots representation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircleAvatar(radius: 6, backgroundColor: Colors.amberAccent),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 6, backgroundColor: Colors.blueAccent),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 6, backgroundColor: Colors.purpleAccent),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 6, backgroundColor: Colors.redAccent),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 6, backgroundColor: Colors.greenAccent),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Magic',
                  style: TextStyle(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFFE85D04),
                  ),
                ),
                const Text(
                  'THE GATHERING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFFC7A27C),
                  ),
                ),
              ],
            ),
          ),
        );

      case GameType.pokemon:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15449A), Color(0xFF0F2B66)],
            ),
            border: Border.all(color: const Color(0xFFFFCB05), width: 3.5),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stylized Pokeball
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFCB05), width: 3),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEE1515), Color(0xFFF5F5F5)],
                      stops: [0.5, 0.5],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'POKÉMON',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Color(0xFFFFCB05),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildHolographicFoilOverlay() {
    // Holographic gradient shifting based on 3D tilt coordinates
    final gradientAlignment = Alignment(
      _tiltY * 3.0,
      _tiltX * 3.0,
    );

    return Opacity(
      opacity: 0.35 + (_tiltX.abs() + _tiltY.abs()) * 0.4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: gradientAlignment,
            end: Alignment(-gradientAlignment.x, -gradientAlignment.y),
            colors: const [
              Colors.transparent,
              Colors.cyanAccent,
              Colors.pinkAccent,
              Colors.amberAccent,
              Colors.purpleAccent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}
