import 'package:flipsyncox/game_models.dart';
import 'package:flutter/material.dart';
import 'game_controller.dart';

class GameOverOverlay extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final bool won;

  const GameOverOverlay({
    super.key,
    required this.ctrl,
    required this.accent,
    required this.won,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = won ? accent : const Color(0xFFff3344);
    return Container(
      color: const Color(0xFF080c1a).withOpacity(0.9),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: borderColor.withOpacity(0.45), width: 1),
            boxShadow: [BoxShadow(color: borderColor.withOpacity(0.18), blurRadius: 48)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(won ? '🏆' : '💀', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                won ? 'YOU WIN!' : 'GAME OVER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                  letterSpacing: 3,
                  shadows: [Shadow(color: borderColor.withOpacity(0.7), blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 20),
              if (won) ...[
                Text(
                  'FINAL SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.35),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${ctrl.finalScore}',
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    shadows: [Shadow(color: accent.withOpacity(0.6), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 14),
                _ScoreRow(label: 'Time Left', value: '${ctrl.timeLeft}s', accent: accent),
                _ScoreRow(label: 'Moves Used', value: '${ctrl.moves}', accent: accent),
                _ScoreRow(label: 'Level', value: ctrl.level.label, accent: accent),
                const SizedBox(height: 20),
              ] else ...[
                Text(
                  'Time ran out!\nBetter luck next time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.45),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _BigButton(
                label: '↺  PLAY AGAIN',
                color: accent,
                onTap: ctrl.restart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _ScoreRow({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 1)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent)),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.12)],
          ),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}