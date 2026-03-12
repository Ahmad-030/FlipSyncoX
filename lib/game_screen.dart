import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_controller.dart';
import 'game_models.dart';
import 'flip_card.dart';
import 'stats_bar.dart';
import 'pause_overlay.dart';
import 'game_over_overlay.dart';

class GameScreen extends StatefulWidget {
  final GameLevel level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late GameController _ctrl;

  // Ambient glow animation
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // Cards entry animation
  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();

    _ctrl = GameController(
      level: widget.level,
      onStateChanged: () => setState(() {}),
    );

    // Pulse glow on accent color
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Cards slide-in on load
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

  @override
  void dispose() {
    _ctrl.dispose();
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Color get _accent => _ctrl.accentColor;

  // ─── PAUSE ────────────────────────────────────────────────────────────────
  void _onPause() {
    _ctrl.pause();
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
      ),
      pageBuilder: (_, __, ___) => PauseOverlay(
        ctrl: _ctrl,
        accent: _accent,
        onResume: () {
          Navigator.pop(context);
          _ctrl.resume();
        },
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

  // ─── GAME OVER ────────────────────────────────────────────────────────────
  void _showGameOver(bool won) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
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
      pageBuilder: (_, __, ___) => GameOverOverlay(
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
    _ctrl.restart();
    _entryController.forward(from: 0);
  }

  // ─── CARD TAP ─────────────────────────────────────────────────────────────
  void _onCardTap(int index) {
    final result = _ctrl.flipCard(index);
    if (result == FlipResult.win) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showGameOver(true);
      });
    } else if (result == FlipResult.lose) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showGameOver(false);
      });
    }
  }

  // ─── GRID ─────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    final cfg = _ctrl.config;
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, __) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cfg.cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: _ctrl.cards.length,
          itemBuilder: (context, i) {
            final card = _ctrl.cards[i];
            // Staggered entry: each card slides up with delay
            final delay = (i / _ctrl.cards.length) * 0.6;
            final slideProgress = (((_entryAnim.value - delay) / (1.0 - delay))
                .clamp(0.0, 1.0));
            return Transform.translate(
              offset: Offset(0, 30 * (1 - slideProgress)),
              child: Opacity(
                opacity: slideProgress,
                child: FlipCard(
                  card: card,
                  accent: _accent,
                  onTap: () => _onCardTap(i),
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      body: Stack(
        children: [
          // ── Ambient radial glow background ──
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Positioned(
              top: -screenSize.height * 0.15,
              left: 0,
              right: 0,
              child: Container(
                height: screenSize.height * 0.55,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.8,
                    colors: [
                      _accent.withOpacity(0.10 * _glowAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ──
                _TopBar(
                  ctrl: _ctrl,
                  accent: _accent,
                  onPause: _onPause,
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 6),

                // ── Stats Bar ──
                StatsBar(ctrl: _ctrl, accent: _accent),

                const SizedBox(height: 8),

                // ── Progress indicator ──
                _ProgressRow(ctrl: _ctrl, accent: _accent),

                const SizedBox(height: 10),

                // ── Card Grid (scrollable for larger levels) ──
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildGrid(),
                  ),
                ),

                // ── Bottom score preview ──
                _BottomBar(ctrl: _ctrl, accent: _accent),

                const SizedBox(height: 8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back button
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            accent: accent,
            onTap: onBack,
          ),

          const SizedBox(width: 10),

          // Title
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
                    const TextSpan(
                      text: 'FLIP',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'SYNCO',
                      style: TextStyle(color: accent),
                    ),
                    const TextSpan(
                      text: 'X',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                ctrl.config.label.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  color: accent.withOpacity(0.7),
                  letterSpacing: 3,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Pause button
          _IconBtn(
            icon: ctrl.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
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
// PROGRESS ROW — pairs matched bar
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
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$matched / $total',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.bold,
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
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR — live score preview
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final GameController ctrl;
  final Color accent;

  const _BottomBar({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    final liveScore = ctrl.liveScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SCORE PREVIEW  ',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 2,
              ),
            ),
            Text(
              '$liveScore',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: 1,
                shadows: [
                  Shadow(color: accent.withOpacity(0.6), blurRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE ICON BUTTON
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: large ? 44 : 36,
        height: large ? 44 : 36,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Icon(
          icon,
          color: accent,
          size: large ? 22 : 17,
        ),
      ),
    );
  }
}