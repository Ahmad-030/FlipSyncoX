import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_controller.dart';
import 'game_models.dart';
import 'flip_card.dart';
import 'stats_bar.dart';

// ─── Accent color per level ───────────────────────────────────────────────────
Color _levelAccent(GameLevel level) {
  switch (level) {
    case GameLevel.easy:   return const Color(0xFF00FF88);
    case GameLevel.medium: return const Color(0xFF00C8FF);
    case GameLevel.hard:   return const Color(0xFFFF8800);
    case GameLevel.expert: return const Color(0xFFFF0066);
  }
}

class GameScreen extends StatefulWidget {
  final GameLevel level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _ctrl;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  // Track previous status so we only trigger game-over dialog once
  GameStatus _lastStatus = GameStatus.idle;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    _ctrl = GameController(level: widget.level);
    _ctrl.addListener(_onControllerChanged);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});

    if (!_dialogShown) {
      if (_ctrl.status == GameStatus.won && _lastStatus != GameStatus.won) {
        _dialogShown = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showGameOver(true);
        });
      } else if (_ctrl.status == GameStatus.lost && _lastStatus != GameStatus.lost) {
        _dialogShown = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _showGameOver(false);
        });
      }
    }
    _lastStatus = _ctrl.status;
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Color get _accent => _levelAccent(_ctrl.level);

  // ─── PAUSE ────────────────────────────────────────────────────────────────
  void _onPauseTap() {
    _ctrl.togglePause();
    if (_ctrl.status == GameStatus.paused) {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        pageBuilder: (_, __, ___) => _PauseDialog(
          ctrl: _ctrl,
          accent: _accent,
          onRestart: () {
            Navigator.pop(context);
            _restartGame();
          },
          onMainMenu: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  // ─── GAME OVER ────────────────────────────────────────────────────────────
  void _showGameOver(bool won) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (_, __, ___) => _GameOverDialog(
        ctrl: _ctrl,
        accent: _accent,
        won: won,
        onRestart: () {
          Navigator.pop(context);
          _restartGame();
        },
        onMainMenu: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _restartGame() {
    _lastStatus = GameStatus.idle;
    _dialogShown = false;
    _ctrl.restart();
    _entryController.forward(from: 0);
  }

  // ─── GRID ─────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final cols = _ctrl.level.cols;
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, __) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: _ctrl.cards.length,
          itemBuilder: (context, i) {
            final card = _ctrl.cards[i];
            final delay = (i / _ctrl.cards.length) * 0.55;
            final progress =
            ((_entryAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, 28 * (1.0 - progress)),
              child: Opacity(
                opacity: progress,
                child: FlipCard(
                  card: card,
                  accent: _accent,
                  onTap: () => _ctrl.flipCard(i),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      body: Stack(
        children: [
          // Pulsing ambient glow
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Positioned(
              top: -screenH * 0.15,
              left: 0,
              right: 0,
              child: Container(
                height: screenH * 0.55,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.85,
                    colors: [
                      _accent.withValues(alpha: 0.10 * _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main UI
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  ctrl: _ctrl,
                  accent: _accent,
                  onPause: _onPauseTap,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: StatsBar(ctrl: _ctrl, accent: _accent),
                ),
                const SizedBox(height: 8),
                _ProgressRow(ctrl: _ctrl, accent: _accent),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(child: _buildGrid()),
                ),
                _ScorePreviewBar(ctrl: _ctrl, accent: _accent),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const _TopBar({
    required this.ctrl,
    required this.accent,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = ctrl.status == GameStatus.paused;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_ios_new_rounded, accent: accent, onTap: onBack),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                  children: [
                    const TextSpan(text: 'FLIP', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'SYNCO', style: TextStyle(color: accent)),
                    const TextSpan(text: 'X', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Text(
                ctrl.level.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  color: accent.withValues(alpha: 0.7),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            accent: accent,
            onTap: onPause,
            large: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressRow extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  const _ProgressRow({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    final matched = ctrl.matchedPairs;
    final total = ctrl.totalPairs;
    final pct = total == 0 ? 0.0 : matched / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAIRS FOUND',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$matched / $total',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE PREVIEW BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ScorePreviewBar extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  const _ScorePreviewBar({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SCORE PREVIEW  ',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 2,
              ),
            ),
            Text(
              '${ctrl.currentScore}',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accent,
                shadows: [Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 12)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool large;

  const _IconBtn({
    required this.icon,
    required this.accent,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 44.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: accent, size: large ? 22 : 17),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAUSE DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _PauseDialog extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const _PauseDialog({
    required this.ctrl,
    required this.accent,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080c1a).withValues(alpha: 0.88),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 40)],
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
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 28),
              _OverlayBtn(
                label: '▶  RESUME',
                color: accent,
                onTap: () {
                  ctrl.togglePause();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _OverlayBtn(label: '↺  RESTART', color: Colors.white54, onTap: onRestart),
              const SizedBox(height: 8),
              _OverlayBtn(label: '⌂  MAIN MENU', color: Colors.white38, onTap: onMainMenu),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GAME OVER DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _GameOverDialog extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final bool won;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const _GameOverDialog({
    required this.ctrl,
    required this.accent,
    required this.won,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = won ? accent : const Color(0xFFff3344);
    return Container(
      color: const Color(0xFF080c1a).withValues(alpha: 0.92),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: borderColor.withValues(alpha: 0.45)),
            boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.18), blurRadius: 48)],
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
                  shadows: [Shadow(color: borderColor.withValues(alpha: 0.7), blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 20),
              if (won) ...[
                Text(
                  'FINAL SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
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
                    shadows: [Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 20)],
                  ),
                ),
                const SizedBox(height: 14),
                _StatRow(label: 'Time Left', value: '${ctrl.timeLeft}s', accent: accent),
                _StatRow(label: 'Moves Used', value: '${ctrl.moves}', accent: accent),
                _StatRow(label: 'Level', value: ctrl.level.label, accent: accent),
                const SizedBox(height: 20),
              ] else ...[
                Text(
                  'Time ran out!\nBetter luck next time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _OverlayBtn(label: '↺  PLAY AGAIN', color: accent, onTap: onRestart),
              const SizedBox(height: 8),
              _OverlayBtn(label: '⌂  MAIN MENU', color: Colors.white38, onTap: onMainMenu),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatRow({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OverlayBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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