import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_set.dart';

class BoosterPackWidget extends StatefulWidget {
  final CardSet cardSet;
  final VoidCallback onTearComplete;

  const BoosterPackWidget({
    super.key,
    required this.cardSet,
    required this.onTearComplete,
  });

  @override
  State<BoosterPackWidget> createState() => _BoosterPackWidgetState();
}

class _BoosterPackWidgetState extends State<BoosterPackWidget>
    with SingleTickerProviderStateMixin {
  double _tearProgress = 0.0;
  bool _isTorn = false;

  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _onTearUpdate(DragUpdateDetails details, double packWidth) {
    if (_isTorn) return;

    setState(() {
      _tearProgress += details.delta.dx / packWidth;
      _tearProgress = _tearProgress.clamp(0.0, 1.0);
    });

    if (_tearProgress > 0.8 && !_isTorn) {
      _isTorn = true;
      HapticFeedback.heavyImpact();
      widget.onTearComplete();
    }
  }

  Widget _buildFallbackEmblem() {
    return Center(
      child: Text(
        widget.cardSet.code.toUpperCase(),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double packWidth = 260.0;
    const double packHeight = 400.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Booster Pack Envelope
          Container(
            width: packWidth,
            height: packHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.cardSet.gameType.primaryColor.withOpacity(0.9),
                  const Color(0xFF151824),
                  widget.cardSet.gameType.primaryColor.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.cardSet.gameType.primaryColor.withOpacity(0.35),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Metallic Foil Texture Shimmer
                  AnimatedBuilder(
                    animation: _shineController,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.5 + _shineController.value * 3.0, -1),
                              end: Alignment(-0.5 + _shineController.value * 3.0, 1),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Pack Header & Game Branding
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          widget.cardSet.gameType.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.cardSet.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Logo / Pack Emblem
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black45,
                        border: Border.all(
                          color: widget.cardSet.gameType.primaryColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.cardSet.gameType.primaryColor
                                .withOpacity(0.5),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: widget.cardSet.iconUrl != null &&
                                widget.cardSet.iconUrl!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: CachedNetworkImage(
                                  imageUrl: widget.cardSet.iconUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) => _buildFallbackEmblem(),
                                  placeholder: (context, url) => _buildFallbackEmblem(),
                                ),
                              )
                            : _buildFallbackEmblem(),
                      ),
                    ),
                  ),

                  // Pack Footer details
                  const Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Text(
                      '5 CARTAS • 1 RARA GARANTIZADA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white60,
                      ),
                    ),
                  ),

                  // TOP TEAR STRIP (Interactive Swipe Line)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) =>
                          _onTearUpdate(details, packWidth),
                      child: Container(
                        color: Colors.black26,
                        child: Stack(
                          children: [
                            // Dotted rip guide line
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isTorn
                                        ? '¡ABIERTO!'
                                        : 'DESLIZA PARA ABRIR',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tear progress mask
                            FractionallySizedBox(
                              widthFactor: _tearProgress,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                color: Colors.amberAccent.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instruction Indicator
          AnimatedOpacity(
            opacity: _isTorn ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.touch_app_rounded, color: Colors.white54, size: 18),
                SizedBox(width: 8),
                Text(
                  'Desliza el dedo por la parte superior para rasgar',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
