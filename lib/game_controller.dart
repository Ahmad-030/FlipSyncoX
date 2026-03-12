import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'game_models.dart';

const List<String> _kEmojis = [
  '🦊','🐉','🌙','⚡','🔮','💎','🎯','🌊',
  '🔥','🍄','🦋','🎸','🏆','🌸','🚀','🎭',
  '🦄','🐺','🌈','💫','🎪','🧊','🌺','🦅',
];

enum GameStatus { idle, playing, paused, won, lost }

class GameController extends ChangeNotifier {
  GameLevel _level;
  List<CardModel> cards = [];
  List<int> _flippedIndices = [];
  bool _locked = false;
  int moves = 0;
  int timeLeft = 0;
  GameStatus status = GameStatus.idle;
  int finalScore = 0;

  Timer? _timer;

  GameController({GameLevel level = GameLevel.easy}) : _level = level {
    _initGame();
  }

  GameLevel get level => _level;
  int get totalPairs => _level.cardCount ~/ 2;
  int get matchedPairs => cards.where((c) => c.isMatched).length ~/ 2;

  int get currentScore {
    final s = (timeLeft * 10) - (moves * 2);
    return s < 0 ? 0 : s;
  }

  double get timerProgress => timeLeft / _level.timeSeconds;
  double get matchProgress => matchedPairs / totalPairs;

  void changeLevel(GameLevel level) {
    _level = level;
    _initGame();
  }

  void _initGame() {
    _timer?.cancel();
    final pairs = _kEmojis.sublist(0, _level.cardCount ~/ 2);
    final all = [...pairs, ...pairs];
    all.shuffle(Random());
    cards = all.asMap().entries
        .map((e) => CardModel(id: e.key, emoji: e.value))
        .toList();
    _flippedIndices = [];
    _locked = false;
    moves = 0;
    timeLeft = _level.timeSeconds;
    status = GameStatus.idle;
    finalScore = 0;
    notifyListeners();
  }

  void restart() => _initGame();

  void flipCard(int index) {
    if (_locked) return;
    if (cards[index].isMatched) return;
    if (cards[index].isFlipped) return;
    if (_flippedIndices.length >= 2) return;

    if (status == GameStatus.idle) _startTimer();

    cards[index] = cards[index].copyWith(isFlipped: true);
    _flippedIndices.add(index);
    notifyListeners();

    if (_flippedIndices.length == 2) {
      moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final a = _flippedIndices[0];
    final b = _flippedIndices[1];

    if (cards[a].emoji == cards[b].emoji) {
      // Match!
      Future.delayed(const Duration(milliseconds: 350), () {
        cards[a] = cards[a].copyWith(isMatched: true);
        cards[b] = cards[b].copyWith(isMatched: true);
        _flippedIndices = [];
        _locked = false;

        if (cards.every((c) => c.isMatched)) {
          _timer?.cancel();
          finalScore = currentScore;
          status = GameStatus.won;
        }
        notifyListeners();
      });
    } else {
      // No match — flip back
      _locked = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        cards[a] = cards[a].copyWith(isFlipped: false);
        cards[b] = cards[b].copyWith(isFlipped: false);
        _flippedIndices = [];
        _locked = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void _startTimer() {
    status = GameStatus.playing;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeft <= 1) {
        _timer?.cancel();
        timeLeft = 0;
        status = GameStatus.lost;
        notifyListeners();
        return;
      }
      timeLeft--;
      notifyListeners();
    });
  }

  void togglePause() {
    if (status == GameStatus.playing) {
      _timer?.cancel();
      status = GameStatus.paused;
    } else if (status == GameStatus.paused) {
      _startTimer();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}