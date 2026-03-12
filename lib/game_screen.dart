import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_controller.dart';
import 'game_models.dart';
import 'flip_card.dart';
import 'stats_bar.dart';

Color _levelAccent(GameLevel level) {
  switch (level.difficulty) {
    case GameDifficulty.easy:   return const Color(0xFF00FF88);
    case GameDifficulty.medium: return const Color(0xFF00C8FF);
    case GameDifficulty.hard:   return const Color(0xFFFF8800);
    case GameDifficulty.expert: return const Color(0xFFFF0066);
  }
}

class GameScreen extends StatefulWidget {
  final GameLevel level;
  final VoidCallback? onLevelComplete;

  const GameScreen({super.key, required this.level, this.onLevelComplete});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameController _ctrl;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  GameStatus _lastStatus = GameStatus.idle;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GameController(level: widget.level);
    _ctrl.addListener(_onControllerChanged);

    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _entryAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);

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
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
        ),
        pageBuilder: (_, __, ___) => _PauseDialog(
          ctrl: _ctrl, accent: _accent,
          onRestart: () { Navigator.pop(context); _restartGame(); },
          onMainMenu: () { Navigator.pop(context); Navigator.pop(context); },
        ),
      );
    }
  }

  void _showGameOver(bool won) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (_, __, ___) => _GameOverDialog(
        ctrl: _ctrl, accent: _accent, won: won,
        onRestart: () { Navigator.pop(context); _restartGame(); },
        onNextLevel: won && widget.onLevelComplete != null
            ? () {
          Navigator.pop(context);
          widget.onLevelComplete?.call();
          Navigator.pop(context);
        }
            : null,
        onMainMenu: () {
          if (won) widget.onLevelComplete?.call();
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

  Widget _buildGrid() {
    final cols = _ctrl.level.cols;
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, __) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.0,
        ),
        itemCount: _ctrl.cards.length,
        itemBuilder: (context, i) {
          final card = _ctrl.cards[i];
          final delay = (i / _ctrl.cards.length) * 0.55;
          final progress = ((_entryAnim.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, 28 * (1.0 - progress)),
            child: Opacity(opacity: progress,
                child: FlipCard(card: card, accent: _accent, onTap: () => _ctrl.flipCard(i))),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF080C1A),
      body: Stack(children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, __) => Positioned(
            top: -screenH * 0.15, left: 0, right: 0,
            child: Container(
              height: screenH * 0.55,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter, radius: 0.85,
                  colors: [_accent.withValues(alpha: 0.10 * _glowAnim.value), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: Column(children: [
          _TopBar(ctrl: _ctrl, accent: _accent, onPause: _onPauseTap, onBack: () => Navigator.pop(context)),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: StatsBar(ctrl: _ctrl, accent: _accent)),
          const SizedBox(height: 8),
          _ProgressRow(ctrl: _ctrl, accent: _accent),
          const SizedBox(height: 6),
          Expanded(child: SingleChildScrollView(child: _buildGrid())),
          _ScorePreviewBar(ctrl: _ctrl, accent: _accent),
          const SizedBox(height: 10),
        ])),
      ]),
    );
  }
}

class _TopBar extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final VoidCallback onPause, onBack;
  const _TopBar({required this.ctrl, required this.accent, required this.onPause, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isPaused = ctrl.status == GameStatus.paused;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _IconBtn(icon: Icons.arrow_back_ios_new_rounded, accent: accent, onTap: onBack),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(
            style: const TextStyle(fontFamily: 'Courier', fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: 2.5),
            children: [
              const TextSpan(text: 'FLIP', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'SYNCO', style: TextStyle(color: accent)),
              const TextSpan(text: 'X', style: TextStyle(color: Colors.white)),
            ],
          )),
          Text('${ctrl.level.difficulty.label.toUpperCase()}  ·  STAGE ${ctrl.level.stage}',
              style: TextStyle(fontFamily: 'Courier', fontSize: 9,
                  color: accent.withValues(alpha: 0.7), letterSpacing: 3)),
        ]),
        const Spacer(),
        _IconBtn(icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            accent: accent, onTap: onPause, large: true),
      ]),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  const _ProgressRow({required this.ctrl, required this.accent});

  @override
  Widget build(BuildContext context) {
    final matched = ctrl.matchedPairs;
    final total   = ctrl.totalPairs;
    final pct     = total == 0 ? 0.0 : matched / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('PAIRS FOUND', style: TextStyle(fontFamily: 'Courier', fontSize: 9,
              color: Colors.white.withValues(alpha: 0.35), letterSpacing: 2)),
          Text('$matched / $total', style: TextStyle(fontFamily: 'Courier', fontSize: 11,
              fontWeight: FontWeight.bold, color: accent, letterSpacing: 1)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(accent)),
        ),
      ]),
    );
  }
}

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
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('SCORE PREVIEW  ', style: TextStyle(fontFamily: 'Courier', fontSize: 10,
              color: Colors.white.withValues(alpha: 0.3), letterSpacing: 2)),
          Text('${ctrl.currentScore}', style: TextStyle(fontFamily: 'Courier', fontSize: 22,
              fontWeight: FontWeight.w900, color: accent,
              shadows: [Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 12)])),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool large;
  const _IconBtn({required this.icon, required this.accent, required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 44.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
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

class _PauseDialog extends StatelessWidget {
  final GameController ctrl;
  final Color accent;
  final VoidCallback onRestart, onMainMenu;
  const _PauseDialog({required this.ctrl, required this.accent, required this.onRestart, required this.onMainMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080c1a).withValues(alpha: 0.92),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF0B0F1C),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 40)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⏸', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            const Text('PAUSED', style: TextStyle(fontFamily: 'Courier', fontSize: 22,
                fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
            const SizedBox(height: 4),
            Text('${ctrl.level.difficulty.label.toUpperCase()}  ·  STAGE ${ctrl.level.stage}',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3), letterSpacing: 2)),
            const SizedBox(height: 28),
            _PrimaryBtn(label: '▶  RESUME', color: accent,
                onTap: () { ctrl.togglePause(); Navigator.pop(context); }),
            const SizedBox(height: 8),
            _Btn(label: '↺  RESTART', color: Colors.white54, onTap: onRestart),
            const SizedBox(height: 8),
            _Btn(label: '⌂  MAIN MENU', color: Colors.white38, onTap: onMainMenu),
          ]),
        ),
      ),
    );
  }
}

class _GameOverDialog extends StatefulWidget {
  final GameController ctrl;
  final Color accent;
  final bool won;
  final VoidCallback onRestart, onMainMenu;
  final VoidCallback? onNextLevel;
  const _GameOverDialog({
    required this.ctrl, required this.accent, required this.won,
    required this.onRestart, required this.onMainMenu, this.onNextLevel,
  });
  @override State<_GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<_GameOverDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.won ? widget.accent : const Color(0xFFff3344);
    return Container(
      color: const Color(0xFF080c1a).withValues(alpha: 0.92),
      child: Center(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, __) => Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF0B0F1C),
              border: Border.all(color: borderColor.withValues(alpha: 0.5 * _glow.value), width: 1.5),
              boxShadow: [
                BoxShadow(color: borderColor.withValues(alpha: 0.22 * _glow.value), blurRadius: 50),
                const BoxShadow(color: Colors.black54, blurRadius: 20),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withValues(alpha: 0.1),
                  border: Border.all(color: borderColor.withValues(alpha: 0.3 * _glow.value)),
                  boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.25 * _glow.value), blurRadius: 20)],
                ),
                child: Center(child: Text(widget.won ? '🏆' : '💀', style: const TextStyle(fontSize: 34))),
              ),
              const SizedBox(height: 12),
              Text(widget.won ? 'LEVEL CLEAR!' : 'GAME OVER',
                style: TextStyle(fontFamily: 'Courier', fontSize: 22, fontWeight: FontWeight.bold,
                    color: borderColor, letterSpacing: 3,
                    shadows: [Shadow(color: borderColor.withValues(alpha: 0.7 * _glow.value), blurRadius: 16)]),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                    color: borderColor.withValues(alpha: 0.1),
                    border: Border.all(color: borderColor.withValues(alpha: 0.25))),
                child: Text(
                    '${widget.ctrl.level.difficulty.label.toUpperCase()}  ·  STAGE ${widget.ctrl.level.stage}',
                    style: TextStyle(fontFamily: 'Courier', fontSize: 9,
                        color: borderColor.withValues(alpha: 0.8), letterSpacing: 2)),
              ),
              const SizedBox(height: 18),
              if (widget.won) ...[
                Text('FINAL SCORE', style: TextStyle(fontFamily: 'Courier', fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35), letterSpacing: 3)),
                const SizedBox(height: 3),
                Text('${widget.ctrl.finalScore}', style: TextStyle(fontFamily: 'Courier', fontSize: 50,
                    fontWeight: FontWeight.bold, color: widget.accent,
                    shadows: [Shadow(color: widget.accent.withValues(alpha: 0.6 * _glow.value), blurRadius: 20)])),
                const SizedBox(height: 10),
                Row(children: [
                  _StatChip(label: 'TIME LEFT', value: '${widget.ctrl.timeLeft}s', color: widget.accent),
                  const SizedBox(width: 7),
                  _StatChip(label: 'MOVES', value: '${widget.ctrl.moves}', color: widget.accent),
                  const SizedBox(width: 7),
                  _StatChip(label: 'PAIRS', value: '${widget.ctrl.totalPairs}', color: widget.accent),
                ]),
                const SizedBox(height: 18),
                if (widget.onNextLevel != null) ...[
                  _PrimaryBtn(label: '▶  NEXT LEVEL', color: widget.accent, onTap: widget.onNextLevel!),
                  const SizedBox(height: 8),
                  _Btn(label: '↺  REPLAY', color: Colors.white54, onTap: widget.onRestart),
                ] else ...[
                  _PrimaryBtn(label: '🏆  COMPLETE!', color: widget.accent, onTap: widget.onMainMenu),
                  const SizedBox(height: 8),
                  _Btn(label: '↺  REPLAY', color: Colors.white54, onTap: widget.onRestart),
                ],
              ] else ...[
                Text('Time ran out!\nBetter luck next time.', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.45), height: 1.6)),
                const SizedBox(height: 20),
                _PrimaryBtn(label: '↺  TRY AGAIN', color: widget.accent, onTap: widget.onRestart),
              ],
              const SizedBox(height: 8),
              _Btn(label: '⌂  MAIN MENU', color: Colors.white38, onTap: widget.onMainMenu),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 7,
            color: Colors.white.withValues(alpha: 0.35), letterSpacing: 1)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontFamily: 'Courier', fontSize: 15,
            fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.12)]),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16)],
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Courier', color: color, fontSize: 14,
              fontWeight: FontWeight.bold, letterSpacing: 2)),
    ),
  );
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Courier', color: color, fontSize: 12,
              fontWeight: FontWeight.bold, letterSpacing: 2)),
    ),
  );
}