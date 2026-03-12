import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'game_models.dart';
import 'game_screen.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
const _kBg       = Color(0xFF06080F);
const _kSurface  = Color(0xFF0B0F1C);
const _kSurface2 = Color(0xFF0F1425);
const _kGreen    = Color(0xFF00FF88);
const _kCyan     = Color(0xFF00D4FF);
const _kOrange   = Color(0xFFFF8C00);
const _kRed      = Color(0xFFFF2D6A);
const _kText     = Color(0xFFDDE4F0);

Color _levelAccent(GameLevel l) {
  switch (l) {
    case GameLevel.easy:   return _kGreen;
    case GameLevel.medium: return _kCyan;
    case GameLevel.hard:   return _kOrange;
    case GameLevel.expert: return _kRed;
  }
}

// ─── Progress helpers ──────────────────────────────────────────────────────
// Levels in play order
const _kLevelOrder = [
  GameLevel.easy,
  GameLevel.medium,
  GameLevel.hard,
  GameLevel.expert,
];

const _kPrefCurrentLevel = 'current_level_index'; // int 0-3
const _kPrefHasProgress  = 'has_progress';         // bool

Future<int> _loadCurrentLevelIndex() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_kPrefCurrentLevel) ?? 0;
}

Future<bool> _loadHasProgress() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPrefHasProgress) ?? false;
}

Future<void> _saveProgress(int levelIndex) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefCurrentLevel, levelIndex);
  await prefs.setBool(_kPrefHasProgress, true);
}

Future<void> _resetProgress() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefCurrentLevel, 0);
  await prefs.setBool(_kPrefHasProgress, false);
}

// ─── Main ──────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const FlipSyncoXApp());
}

class FlipSyncoXApp extends StatelessWidget {
  const FlipSyncoXApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FlipSyncoX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: _kBg,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      }),
    ),
    home: const SplashScreen(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SPLASH SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _particleCtrl;

  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _subFade;
  late final Animation<double> _glow;

  final _rng = Random();
  late final List<_Dot> _dots;

  @override
  void initState() {
    super.initState();

    _entryCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _glowCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

    _cardScale = Tween<double>(begin: .5, end: 1.0).animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, .5, curve: Curves.easeOutBack)));
    _cardFade  = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, .4, curve: Curves.easeOut));
    _logoFade  = CurvedAnimation(parent: _entryCtrl, curve: const Interval(.3, .65, curve: Curves.easeOut));
    _subFade   = CurvedAnimation(parent: _entryCtrl, curve: const Interval(.55, .85, curve: Curves.easeOut));
    _glow      = Tween<double>(begin: .35, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _dots = List.generate(22, (_) => _Dot(
      x:       _rng.nextDouble(),
      y:       _rng.nextDouble(),
      speed:   .10 + _rng.nextDouble() * .28,
      radius:  1.0 + _rng.nextDouble() * 2.5,
      opacity: .08 + _rng.nextDouble() * .25,
    ));

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_fadeRoute(const MainMenuScreen()));
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => CustomPaint(
            size: size,
            painter: _DotPainter(_dots, _particleCtrl.value),
          ),
        ),
        AnimatedBuilder(
          animation: _glow,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center, radius: .85,
                colors: [_kGreen.withValues(alpha: .11 * _glow.value), Colors.transparent],
              ),
            ),
          ),
        ),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FadeTransition(
              opacity: _cardFade,
              child: ScaleTransition(scale: _cardScale, child: const _SplashCards()),
            ),
            const SizedBox(height: 42),
            FadeTransition(
              opacity: _logoFade,
              child: Column(children: [
                _Logo(size: 36),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _subFade,
                  child: Text('TRAIN YOUR MEMORY',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 11,
                          letterSpacing: 6, color: _kText.withValues(alpha: .32))),
                ),
              ]),
            ),
            const SizedBox(height: 52),
            FadeTransition(opacity: _subFade, child: _BounceDots(color: _kGreen)),
          ]),
        ),
        Positioned(
          bottom: 22, left: 0, right: 0,
          child: FadeTransition(
            opacity: _subFade,
            child: Text('ARSALAN LIMITED PRODUCTION',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Courier', fontSize: 9,
                    letterSpacing: 4, color: _kText.withValues(alpha: .18))),
          ),
        ),
      ]),
    );
  }
}

// splash: 3 animated flip cards
class _SplashCards extends StatefulWidget {
  const _SplashCards();
  @override State<_SplashCards> createState() => _SplashCardsState();
}
class _SplashCardsState extends State<_SplashCards> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;
  late final List<Animation<double>>   _angles;
  static const _emojis  = ['🔮','⚡','💎'];
  static const _accents = [_kGreen, _kOrange, _kCyan];

  @override
  void initState() {
    super.initState();
    _cs     = List.generate(3, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 620)));
    _angles = _cs.map((c) => Tween<double>(begin: 0, end: pi)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 160 + i * 210), () { if (mounted) _cs[i].forward(); });
    }
  }
  @override void dispose() { for (final c in _cs) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) {
      final accent = _accents[i];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: AnimatedBuilder(
          animation: _angles[i],
          builder: (_, __) {
            final a = _angles[i].value;
            final front = a > pi / 2;
            return Transform(
              transform: Matrix4.rotationY(a),
              alignment: Alignment.center,
              child: Container(
                width: 62, height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: front
                        ? [const Color(0xFF0e2e50), const Color(0xFF0b1a2e)]
                        : [_kSurface, _kSurface2],
                  ),
                  border: Border.all(
                    color: front ? accent.withValues(alpha: .55) : Colors.white.withValues(alpha: .07),
                    width: 1.5,
                  ),
                  boxShadow: front
                      ? [BoxShadow(color: accent.withValues(alpha: .35), blurRadius: 20)]
                      : [],
                ),
                child: Center(child: front
                    ? Text(_emojis[i], style: const TextStyle(fontSize: 26))
                    : Icon(Icons.grid_view_rounded,
                    color: Colors.white.withValues(alpha: .15), size: 22)),
              ),
            );
          },
        ),
      );
    }),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN MENU  –  NEW GAME / CONTINUE
// ═══════════════════════════════════════════════════════════════════════════
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override State<MainMenuScreen> createState() => _MainMenuState();
}
class _MainMenuState extends State<MainMenuScreen> with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _glow;
  late final Animation<double>   _glowAnim;
  late final List<_BgCard>       _bgCards;
  final _rng = Random();

  int  _currentLevelIndex = 0;
  bool _hasProgress        = false;
  bool _loadingProgress    = true;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _glow  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: .3, end: 1.0)
        .animate(CurvedAnimation(parent: _glow, curve: Curves.easeInOut));

    final emojis = ['🔮','⚡','💎','🎯','🌙','🏆','🔥','🌊','🎲','✨'];
    _bgCards = List.generate(10, (i) => _BgCard(
      x: _rng.nextDouble(), y: _rng.nextDouble(),
      size: 24 + _rng.nextDouble() * 30,
      opacity: .025 + _rng.nextDouble() * .045,
      emoji: emojis[i], rotation: _rng.nextDouble() * pi * 2,
    ));

    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final idx = await _loadCurrentLevelIndex();
    final has = await _loadHasProgress();
    if (mounted) {
      setState(() {
        _currentLevelIndex = idx;
        _hasProgress        = has;
        _loadingProgress    = false;
      });
    }
  }

  @override void dispose() { _entry.dispose(); _glow.dispose(); super.dispose(); }

  // ── NEW GAME ──────────────────────────────────────────────────────────────
  Future<void> _onNewGame() async {
    if (_hasProgress) {
      final confirm = await _showConfirmReset(context);
      if (!confirm) return;
    }
    await _resetProgress();
    if (!mounted) return;
    setState(() { _currentLevelIndex = 0; _hasProgress = false; });
    _launchLevel(0);
  }

  // ── CONTINUE ──────────────────────────────────────────────────────────────
  void _onContinue() {
    if (!_hasProgress) return;
    _launchLevel(_currentLevelIndex);
  }

  // ── Launch a level, then handle result ────────────────────────────────────
  Future<void> _launchLevel(int index) async {
    final level = _kLevelOrder[index];
    final result = await Navigator.push<_LevelResult>(
      context,
      _slideRoute(GameScreen(
        level: level,
        onLevelComplete: () => Navigator.pop(context, _LevelResult.won),
      )),
    );

    if (result == _LevelResult.won) {
      final nextIndex = index + 1;
      if (nextIndex >= _kLevelOrder.length) {
        // Beat the whole game
        await _resetProgress();
        if (mounted) setState(() { _currentLevelIndex = 0; _hasProgress = false; });
        if (mounted) _showGameBeatenDialog();
      } else {
        await _saveProgress(nextIndex);
        if (mounted) setState(() { _currentLevelIndex = nextIndex; _hasProgress = true; });
      }
    }
  }

  // ── Confirm reset dialog ──────────────────────────────────────────────────
  Future<bool> _showConfirmReset(BuildContext ctx) async {
    return await showGeneralDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: .75),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
      ),
      pageBuilder: (_, __, ___) => _ConfirmDialog(accent: _kOrange),
    ) ?? false;
  }

  // ── Game beaten dialog ────────────────────────────────────────────────────
  void _showGameBeatenDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
      pageBuilder: (_, __, ___) => _GameBeatenDialog(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    // Which level will CONTINUE resume from
    final continueLevel = _hasProgress ? _kLevelOrder[_currentLevelIndex] : null;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // scattered bg cards
        ..._bgCards.map((c) => Positioned(
          left: c.x * sw, top: c.y * sh,
          child: Transform.rotate(angle: c.rotation, child: Container(
            width: c.size, height: c.size * 1.3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withValues(alpha: c.opacity)),
            ),
            child: Center(child: Text(c.emoji, style: TextStyle(fontSize: c.size * .38))),
          )),
        )),
        // ambient glow
        AnimatedBuilder(animation: _glowAnim, builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.65), radius: .7,
              colors: [_kGreen.withValues(alpha: .08 * _glowAnim.value), Colors.transparent],
            ),
          ),
        )),
        // content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(height: 50),
              _Reveal(ctrl: _entry, delay: .00, child: _Logo(size: 34)),
              const SizedBox(height: 6),
              _Reveal(ctrl: _entry, delay: .05, child: Text('MEMORY CARD GAME',
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10,
                      letterSpacing: 5, color: _kText.withValues(alpha: .28)))),
              const SizedBox(height: 56),

              // ── Level journey strip ──────────────────────────────────
              _Reveal(ctrl: _entry, delay: .10, child: _LevelJourneyStrip(
                currentIndex: _currentLevelIndex,
                hasProgress: _hasProgress,
              )),
              const SizedBox(height: 40),

              // ── NEW GAME button ──────────────────────────────────────
              _Reveal(ctrl: _entry, delay: .18, child: _MainMenuBtn(
                icon: '🎮',
                label: 'NEW GAME',
                subtitle: 'Start from Easy',
                accent: _kGreen,
                primary: true,
                onTap: _loadingProgress ? null : _onNewGame,
              )),
              const SizedBox(height: 12),

              // ── CONTINUE button ──────────────────────────────────────
              _Reveal(ctrl: _entry, delay: .24, child: _MainMenuBtn(
                icon: '▶',
                label: 'CONTINUE',
                subtitle: continueLevel != null
                    ? 'Resume  ${_levelLabel(continueLevel).toUpperCase()}  ·  ${_levelSub(continueLevel)}'
                    : 'No saved progress',
                accent: _kCyan,
                primary: false,
                enabled: _hasProgress && !_loadingProgress,
                onTap: _hasProgress ? _onContinue : null,
              )),

              const SizedBox(height: 36),

              // ── More section ─────────────────────────────────────────
              _Reveal(ctrl: _entry, delay: .32, child: _SectionTag(label: 'MORE', accent: _kCyan)),
              const SizedBox(height: 12),
              _Reveal(ctrl: _entry, delay: .36, child: _NavTile(
                icon: '🏆', label: 'HIGH SCORE', accent: _kCyan,
                onTap: () => Navigator.push(context, _slideRoute(const HighScoreScreen())),
              )),
              const SizedBox(height: 9),
              _Reveal(ctrl: _entry, delay: .40, child: _NavTile(
                icon: 'ℹ', label: 'ABOUT', accent: _kCyan,
                onTap: () => Navigator.push(context, _slideRoute(const AboutScreen())),
              )),
              const SizedBox(height: 9),
              _Reveal(ctrl: _entry, delay: .44, child: _NavTile(
                icon: '🔒', label: 'PRIVACY POLICY', accent: _kCyan,
                onTap: () => Navigator.push(context, _slideRoute(const PrivacyPolicyScreen())),
              )),

              const SizedBox(height: 40),
              _Reveal(ctrl: _entry, delay: .50, child: Text(
                'v1.0.0  ·  Arsalan Limited Production',
                style: TextStyle(fontFamily: 'Courier', fontSize: 9,
                    letterSpacing: 2, color: _kText.withValues(alpha: .16)),
              )),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Level result enum ─────────────────────────────────────────────────────
enum _LevelResult { won, quit }

// ─── Level Journey Strip (visual progress indicator) ──────────────────────
class _LevelJourneyStrip extends StatelessWidget {
  final int  currentIndex;
  final bool hasProgress;
  const _LevelJourneyStrip({required this.currentIndex, required this.hasProgress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_kLevelOrder.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final levelIdx = i ~/ 2;
            final passed = hasProgress && levelIdx < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: passed
                      ? _levelAccent(_kLevelOrder[levelIdx]).withValues(alpha: .5)
                      : Colors.white.withValues(alpha: .08),
                ),
              ),
            );
          }
          final levelIdx = i ~/ 2;
          final level    = _kLevelOrder[levelIdx];
          final accent   = _levelAccent(level);
          final isCurrent = hasProgress && levelIdx == currentIndex;
          final isPassed  = hasProgress && levelIdx < currentIndex;
          final isLocked  = !hasProgress && levelIdx > 0;

          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed
                    ? accent.withValues(alpha: .18)
                    : isCurrent
                    ? accent.withValues(alpha: .14)
                    : Colors.white.withValues(alpha: .04),
                border: Border.all(
                  color: isPassed || isCurrent
                      ? accent.withValues(alpha: isCurrent ? .9 : .4)
                      : Colors.white.withValues(alpha: .1),
                  width: isCurrent ? 2 : 1,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: accent.withValues(alpha: .4), blurRadius: 12)]
                    : null,
              ),
              child: Center(child: isPassed
                  ? Icon(Icons.check_rounded, color: accent, size: 16)
                  : isLocked
                  ? Icon(Icons.lock_outline_rounded, color: Colors.white.withValues(alpha: .22), size: 14)
                  : Text(_levelEmoji(level), style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 5),
            Text(
              _levelLabel(level).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Courier', fontSize: 8, letterSpacing: 1.5,
                color: isCurrent
                    ? accent
                    : isPassed
                    ? accent.withValues(alpha: .5)
                    : Colors.white.withValues(alpha: .2),
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

String _levelEmoji(GameLevel l) => const {
  GameLevel.easy:   '🌱',
  GameLevel.medium: '⚡',
  GameLevel.hard:   '🔥',
  GameLevel.expert: '💀',
}[l]!;

// ─── Main menu big button ──────────────────────────────────────────────────
class _MainMenuBtn extends StatefulWidget {
  final String    icon, label, subtitle;
  final Color     accent;
  final bool      primary;
  final bool      enabled;
  final VoidCallback? onTap;

  const _MainMenuBtn({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.primary,
    this.enabled = true,
    this.onTap,
  });

  @override State<_MainMenuBtn> createState() => _MainMenuBtnState();
}
class _MainMenuBtnState extends State<_MainMenuBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _s = Tween<double>(begin: 1, end: .96).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a       = widget.accent;
    final active  = widget.enabled && widget.onTap != null;
    final opacity = active ? 1.0 : 0.38;

    return GestureDetector(
      onTapDown:   active ? (_) => _c.forward()  : null,
      onTapUp:     active ? (_) { _c.reverse(); widget.onTap?.call(); } : null,
      onTapCancel: active ? ()  => _c.reverse()  : null,
      child: ScaleTransition(
        scale: _s,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.primary
                  ? LinearGradient(colors: [a.withValues(alpha: .22), a.withValues(alpha: .07)])
                  : null,
              color: widget.primary ? null : Colors.white.withValues(alpha: .03),
              border: Border.all(color: a.withValues(alpha: widget.primary ? .5 : .22), width: widget.primary ? 1.5 : 1),
              boxShadow: widget.primary
                  ? [BoxShadow(color: a.withValues(alpha: .18), blurRadius: 20, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Row(children: [
              Text(widget.icon, style: TextStyle(fontSize: widget.primary ? 26 : 22)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label, style: TextStyle(
                  fontFamily: 'Courier', fontSize: widget.primary ? 18 : 15,
                  fontWeight: FontWeight.w900, color: a, letterSpacing: 2,
                  shadows: widget.primary ? [Shadow(color: a.withValues(alpha: .5), blurRadius: 12)] : null,
                )),
                const SizedBox(height: 3),
                Text(widget.subtitle, style: TextStyle(
                  fontFamily: 'Courier', fontSize: 10,
                  color: _kText.withValues(alpha: active ? .38 : .22), letterSpacing: 1,
                )),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: a.withValues(alpha: .45), size: 14),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Confirm reset dialog ──────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final Color accent;
  const _ConfirmDialog({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: .4)),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: .15), blurRadius: 40)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('RESET PROGRESS?',
                style: TextStyle(fontFamily: 'Courier', fontSize: 16,
                    fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
            const SizedBox(height: 10),
            Text('Your current progress will be lost\nand you\'ll start from Easy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: _kText.withValues(alpha: .45), height: 1.7)),
            const SizedBox(height: 26),
            Row(children: [
              Expanded(child: _DialogBtn(
                label: 'CANCEL',
                color: Colors.white38,
                onTap: () => Navigator.pop(context, false),
              )),
              const SizedBox(width: 10),
              Expanded(child: _DialogBtn(
                label: 'RESET',
                color: _kRed,
                onTap: () => Navigator.pop(context, true),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Game beaten dialog ────────────────────────────────────────────────────
class _GameBeatenDialog extends StatelessWidget {
  final VoidCallback onClose;
  const _GameBeatenDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 290,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kGreen.withValues(alpha: .5)),
            boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: .2), blurRadius: 50)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text('YOU BEAT THE GAME!',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Courier', fontSize: 17,
                    fontWeight: FontWeight.bold, color: _kGreen, letterSpacing: 2,
                    shadows: [Shadow(color: _kGreen.withValues(alpha: .55), blurRadius: 14)])),
            const SizedBox(height: 12),
            Text('You\'ve conquered all four levels.\nAmazing memory!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _kText.withValues(alpha: .45), height: 1.7)),
            const SizedBox(height: 28),
            _DialogBtn(label: 'BACK TO MENU', color: _kGreen, onTap: onClose),
          ]),
        ),
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color  color;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: .08),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Courier', fontSize: 12,
              fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  HIGH SCORE
// ═══════════════════════════════════════════════════════════════════════════
class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});
  @override State<HighScoreScreen> createState() => _HighScoreState();
}
class _HighScoreState extends State<HighScoreScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  final _data = [
    _ScoreEntry(level: GameLevel.easy,   score: 1240, time: '38s', moves: 8),
    _ScoreEntry(level: GameLevel.medium, score: 860,  time: '57s', moves: 16),
    _ScoreEntry(level: GameLevel.hard,   score: 0,    time: '--',  moves: 0),
    _ScoreEntry(level: GameLevel.expert, score: 0,    time: '--',  moves: 0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _TopBar(title: 'HIGH SCORE', accent: _kGreen, onBack: () => Navigator.pop(context)),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _Reveal(ctrl: _ctrl, delay: .0, child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(children: [
                const Text('🏆', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text('YOUR RECORDS', style: TextStyle(fontFamily: 'Courier',
                    fontSize: 17, letterSpacing: 4, fontWeight: FontWeight.bold,
                    color: _kGreen,
                    shadows: [Shadow(color: _kGreen.withValues(alpha: .5), blurRadius: 12)])),
              ]),
            )),
            ..._data.asMap().entries.map((e) => _Reveal(
              ctrl: _ctrl, delay: .08 + e.key * .08,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScoreCard(entry: e.value),
              ),
            )),
          ],
        )),
      ])),
    );
  }
}

class _ScoreEntry {
  final GameLevel level;
  final int score, moves;
  final String time;
  const _ScoreEntry({required this.level, required this.score, required this.time, required this.moves});
}

class _ScoreCard extends StatelessWidget {
  final _ScoreEntry entry;
  const _ScoreCard({required this.entry, super.key});
  @override
  Widget build(BuildContext context) {
    final accent   = _levelAccent(entry.level);
    final hasScore = entry.score > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: hasScore ? .3 : .1)),
        boxShadow: hasScore
            ? [BoxShadow(color: accent.withValues(alpha: .07), blurRadius: 14)]
            : null,
      ),
      child: Row(children: [
        Container(width: 4, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: accent.withValues(alpha: hasScore ? .9 : .25),
            )),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_levelLabel(entry.level).toUpperCase(),
              style: TextStyle(fontFamily: 'Courier', fontSize: 11,
                  letterSpacing: 3, color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (hasScore)
            Row(children: [
              _Mini(label: 'SCORE', value: '${entry.score}', color: accent),
              const SizedBox(width: 18),
              _Mini(label: 'TIME',  value: entry.time,       color: _kCyan),
              const SizedBox(width: 18),
              _Mini(label: 'MOVES', value: '${entry.moves}', color: _kCyan),
            ])
          else
            Text('No record yet', style: TextStyle(fontFamily: 'Courier',
                fontSize: 11, color: _kText.withValues(alpha: .22), letterSpacing: 1)),
        ])),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Mini({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 8,
        color: _kText.withValues(alpha: .3), letterSpacing: 1)),
    const SizedBox(height: 2),
    Text(value, style: TextStyle(fontFamily: 'Courier', fontSize: 16,
        fontWeight: FontWeight.bold, color: color,
        shadows: [Shadow(color: color.withValues(alpha: .45), blurRadius: 8)])),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
//  ABOUT
// ═══════════════════════════════════════════════════════════════════════════
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override State<AboutScreen> createState() => _AboutState();
}
class _AboutState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward(); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: SafeArea(child: Column(children: [
      _TopBar(title: 'ABOUT', accent: _kGreen, onBack: () => Navigator.pop(context)),
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Reveal(ctrl: _ctrl, delay: .00, child: _InfoBox(accent: _kGreen, icon: '🎮', title: 'FlipSyncoX',
            child: Text(
              'FlipSyncoX is a modern memory card game built to sharpen your recall, '
                  'improve focus, and challenge your speed. Match all pairs before the timer '
                  'runs out across four thrilling difficulty levels.',
              style: TextStyle(fontSize: 13.5, color: _kText.withValues(alpha: .58), height: 1.75),
            ),
          )),
          const SizedBox(height: 12),
          _Reveal(ctrl: _ctrl, delay: .10, child: _InfoBox(accent: _kCyan, icon: '👨‍💻', title: 'DEVELOPER',
            child: Column(children: const [
              _Row2(label: 'Studio',   value: 'Arsalan Limited Production'),
              SizedBox(height: 8),
              _Row2(label: 'Email',    value: 'mrrezabazgir68@gmail.com'),
            ]),
          )),
          const SizedBox(height: 12),
          _Reveal(ctrl: _ctrl, delay: .18, child: _InfoBox(accent: _kOrange, icon: '📋', title: 'HOW TO PLAY',
            child: Column(children: const [
              _Step(n: '01', text: 'Tap any face-down card to flip it'),
              _Step(n: '02', text: 'Tap a second card to look for a match'),
              _Step(n: '03', text: 'Matched pairs stay open — others flip back'),
              _Step(n: '04', text: 'Clear the board before the timer hits zero'),
            ]),
          )),
          const SizedBox(height: 12),
          _Reveal(ctrl: _ctrl, delay: .26, child: _InfoBox(accent: _kRed, icon: '🏆', title: 'SCORING',
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: _kRed.withValues(alpha: .06),
                  border: Border.all(color: _kRed.withValues(alpha: .22)),
                ),
                child: const Center(
                  child: Text('SCORE = (Time Left × 10) − (Moves × 2)',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 12,
                          color: _kRed, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 10),
              Text('Use fewer moves and complete faster for the best score!',
                  style: TextStyle(fontSize: 12.5, color: _kText.withValues(alpha: .4),
                      fontStyle: FontStyle.italic)),
            ]),
          )),
          const SizedBox(height: 28),
          _Reveal(ctrl: _ctrl, delay: .34, child: Text(
            '© 2025  Arsalan Limited Production\nAll Rights Reserved',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Courier', fontSize: 10,
                color: _kText.withValues(alpha: .18), letterSpacing: 2, height: 1.9),
          )),
        ],
      )),
    ])),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  PRIVACY POLICY
// ═══════════════════════════════════════════════════════════════════════════
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (request.url.startsWith('http') || request.url.startsWith('https')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadHtml();
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('Assets/privacy_policy.html');
    await _controller.loadHtmlString(html, baseUrl: 'about:blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text('Privacy Policy',
            style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Color(0xFF2979FF)),
                SizedBox(height: 12),
                Text('Loading privacy policy…',
                    style: TextStyle(color: Color(0xFF8898AA), fontSize: 13)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({required this.size});
  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: TextStyle(fontFamily: 'Courier', fontSize: size,
          fontWeight: FontWeight.w900, letterSpacing: 4),
      children: const [
        TextSpan(text: 'Flip',  style: TextStyle(color: Colors.white)),
        TextSpan(text: 'Synco', style: TextStyle(color: _kGreen)),
        TextSpan(text: 'X',     style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  final String title;
  final Color  accent;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.accent, required this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      GestureDetector(
        onTap: onBack,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: .25)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: accent, size: 16),
        ),
      ),
      const SizedBox(width: 14),
      Text(title, style: TextStyle(fontFamily: 'Courier', fontSize: 15,
          letterSpacing: 3, color: accent, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _SectionTag extends StatelessWidget {
  final String label;
  final Color  accent;
  const _SectionTag({required this.label, required this.accent});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 3, height: 13,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 10,
          letterSpacing: 3, color: accent.withValues(alpha: .8))),
    ]),
  );
}

class _NavTile extends StatefulWidget {
  final String icon, label;
  final Color  accent;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.accent, required this.onTap});
  @override State<_NavTile> createState() => _NavTileState();
}
class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _s = Tween<double>(begin: 1, end: .97).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.accent.withValues(alpha: .055),
        border: Border.all(color: widget.accent.withValues(alpha: .18)),
      ),
      child: Row(children: [
        Text(widget.icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 14),
        Expanded(child: Text(widget.label, style: TextStyle(fontFamily: 'Courier',
            fontSize: 13, letterSpacing: 2, color: widget.accent, fontWeight: FontWeight.bold))),
        Icon(Icons.arrow_forward_ios_rounded, color: widget.accent.withValues(alpha: .45), size: 13),
      ]),
    )),
  );
}

class _InfoBox extends StatelessWidget {
  final Color  accent;
  final String icon, title;
  final Widget child;
  const _InfoBox({required this.accent, required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withValues(alpha: .2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontFamily: 'Courier', fontSize: 12,
            letterSpacing: 2, color: accent, fontWeight: FontWeight.bold)),
      ]),
      Container(margin: const EdgeInsets.symmetric(vertical: 12),
          height: 1, color: accent.withValues(alpha: .11)),
      child,
    ]),
  );
}

class _Row2 extends StatelessWidget {
  final String label, value;
  const _Row2({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 62, child: Text('$label:', style: TextStyle(fontFamily: 'Courier',
        fontSize: 10, color: _kText.withValues(alpha: .3), letterSpacing: 1))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, color: _kText))),
  ]);
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(n, style: const TextStyle(fontFamily: 'Courier', fontSize: 10,
          color: _kOrange, letterSpacing: 1)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(fontSize: 13.5,
          color: _kText.withValues(alpha: .6)))),
    ]),
  );
}

// ─── Fade+Slide reveal ─────────────────────────────────────────────────────
class _Reveal extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  final Widget child;
  const _Reveal({required this.ctrl, required this.delay, required this.child});
  @override
  Widget build(BuildContext context) {
    final s = delay.clamp(0.0, .85);
    final e = (delay + .38).clamp(0.0, 1.0);
    final ca = CurvedAnimation(parent: ctrl, curve: Interval(s, e, curve: Curves.easeOut));
    return FadeTransition(opacity: ca,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .1), end: Offset.zero).animate(ca),
        child: child,
      ),
    );
  }
}

// ─── Bouncing dots ─────────────────────────────────────────────────────────
class _BounceDots extends StatefulWidget {
  final Color color;
  const _BounceDots({required this.color});
  @override State<_BounceDots> createState() => _BounceDotsState();
}
class _BounceDotsState extends State<_BounceDots> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;
  @override void initState() {
    super.initState();
    _cs = List.generate(3, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 480)));
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 155), () {
        if (mounted) _cs[i].repeat(reverse: true);
      });
    }
  }
  @override void dispose() { for (final c in _cs) c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) => AnimatedBuilder(
      animation: _cs[i],
      builder: (_, __) => Container(
        width: 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: .18 + _cs[i].value * .78),
          boxShadow: [BoxShadow(
              color: widget.color.withValues(alpha: _cs[i].value * .45), blurRadius: 7)],
        ),
      ),
    )),
  );
}

// ─── Particle painter ──────────────────────────────────────────────────────
class _Dot {
  final double x, y, speed, radius, opacity;
  const _Dot({required this.x, required this.y, required this.speed, required this.radius, required this.opacity});
}
class _DotPainter extends CustomPainter {
  final List<_Dot> dots;
  final double t;
  const _DotPainter(this.dots, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final y = ((d.y - d.speed * t) % 1.0) * size.height;
      final o = d.opacity * (.45 + .55 * sin(t * pi * 2 + d.x * 8));
      canvas.drawCircle(
        Offset(d.x * size.width, y), d.radius,
        Paint()
          ..color = _kGreen.withValues(alpha: o)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }
  @override bool shouldRepaint(_DotPainter o) => true;
}

// ─── BgCard data ───────────────────────────────────────────────────────────
class _BgCard {
  final double x, y, size, opacity, rotation;
  final String emoji;
  const _BgCard({required this.x, required this.y, required this.size,
    required this.opacity, required this.emoji, required this.rotation});
}

// ─── Routes ────────────────────────────────────────────────────────────────
PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
  transitionDuration: const Duration(milliseconds: 680),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
);
PageRouteBuilder<T> _slideRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 460),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, a, __, child) => FadeTransition(
    opacity: a,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
      child: child,
    ),
  ),
);

// ─── Level helpers ──────────────────────────────────────────────────────────
String _levelLabel(GameLevel l) => const {
  GameLevel.easy:   'Easy',
  GameLevel.medium: 'Medium',
  GameLevel.hard:   'Hard',
  GameLevel.expert: 'Expert',
}[l]!;

String _levelSub(GameLevel l) => const {
  GameLevel.easy:   '3×4  ·  12 cards  ·  60s',
  GameLevel.medium: '4×4  ·  16 cards  ·  90s',
  GameLevel.hard:   '4×5  ·  20 cards  ·  120s',
  GameLevel.expert: '4×6  ·  24 cards  ·  150s',
}[l]!;