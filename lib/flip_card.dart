import 'dart:math';
import 'package:flutter/material.dart';
import 'game_models.dart';

class FlipCard extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;
  final Color accent;

  const FlipCard({
    super.key,
    required this.card,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final revealed = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: card.isMatched ? null : onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (ctx, child) {
              final angle = rotate.value;
              final isFront = angle < pi / 2;
              return Transform(
                transform: Matrix4.rotationY(isFront ? angle : pi - angle),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: revealed
            ? _FrontFace(key: const ValueKey('front'), card: card, accent: accent)
            : _BackFace(key: const ValueKey('back'), accent: accent),
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  final Color accent;
  const _BackFace({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Icon(Icons.star_outline_rounded, color: accent.withOpacity(0.35), size: 22),
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  final CardModel card;
  final Color accent;
  const _FrontFace({super.key, required this.card, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: card.isMatched
              ? [accent.withOpacity(0.2), accent.withOpacity(0.08)]
              : [const Color(0xFF0f3460), const Color(0xFF16213e)],
        ),
        border: Border.all(
          color: card.isMatched ? accent.withOpacity(0.6) : accent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: card.isMatched ? accent.withOpacity(0.3) : accent.withOpacity(0.1),
            blurRadius: card.isMatched ? 14 : 6,
          ),
          const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text(
          card.emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}