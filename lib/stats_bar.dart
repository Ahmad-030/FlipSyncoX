import 'package:flutter/material.dart';

import 'game_controller.dart';

class StatsBar extends StatelessWidget {
  final GameController ctrl;
  final Color accent;

  const StatsBar({super.key, required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    final timerPct = ctrl.timerProgress;
    final timerColor = timerPct > 0.5
        ? accent
        : timerPct > 0.25
        ? const Color(0xFFffaa00)
        : const Color(0xFFff3344);

    final mins = ctrl.timeLeft ~/ 60;
    final secs = ctrl.timeLeft % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Row(
      children: [
        // Timer
        Expanded(
          child: _StatCard(
            label: 'TIME',
            accent: timerColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [Shadow(color: timerColor.withOpacity(0.6), blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: timerPct,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Moves
        Expanded(
          child: _StatCard(
            label: 'MOVES',
            accent: Colors.white.withOpacity(0.4),
            child: Text(
              '${ctrl.moves}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Pairs
        Expanded(
          child: _StatCard(
            label: 'PAIRS',
            accent: accent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${ctrl.matchedPairs}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      TextSpan(
                        text: '/${ctrl.totalPairs}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: ctrl.matchProgress,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Color accent;
  final Widget child;

  const _StatCard({required this.label, required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white38,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}