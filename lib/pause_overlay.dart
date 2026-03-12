import 'package:flutter/material.dart';
import 'game_controller.dart';

class PauseOverlay extends StatelessWidget {
  final GameController ctrl;
  final Color accent;

  const PauseOverlay({super.key, required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080c1a).withOpacity(0.88),
      child: BackdropFilter(
        filter: _blurFilter(),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: accent.withOpacity(0.35), width: 1),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 40)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⏸', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GAME IS PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 28),
                _OverlayButton(
                  label: '▶  RESUME',
                  color: accent,
                  onTap: ctrl.togglePause,
                ),
                const SizedBox(height: 8),
                _OverlayButton(
                  label: '↺  RESTART',
                  color: Colors.white54,
                  onTap: ctrl.restart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: deprecated_member_use
  static _blurFilter() => ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 0.9, 0,
  ]);
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}