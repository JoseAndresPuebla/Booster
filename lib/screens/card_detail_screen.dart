import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/tiltable_card_widget.dart';

class CardDetailScreen extends StatelessWidget {
  final CardModel card;
  final int count;

  const CardDetailScreen({
    super.key,
    required this.card,
    this.count = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(card.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 3D Tiltable Inspection Card
            Expanded(
              child: Center(
                child: TiltableCardWidget(
                  card: card,
                  isFaceUp: true,
                  width: 300,
                  height: 420,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card metadata card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151824),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.setName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x$count en posesión',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nº ${card.cardNumber}',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      Text(
                        card.rarity.label.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: card.rarity.tier >= 4
                              ? Colors.amberAccent
                              : Colors.white70,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
