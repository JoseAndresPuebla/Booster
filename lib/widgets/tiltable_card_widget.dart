import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';

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
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.card.gameType.defaultCardBackUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Text(
                  widget.card.gameType.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
