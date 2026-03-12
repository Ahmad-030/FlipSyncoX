// ─── Models ───────────────────────────────────────────────────────────────────

enum GameDifficulty { easy, medium, hard, expert }

extension GameDifficultyExt on GameDifficulty {
  String get label {
    switch (this) {
      case GameDifficulty.easy:   return 'Easy';
      case GameDifficulty.medium: return 'Medium';
      case GameDifficulty.hard:   return 'Hard';
      case GameDifficulty.expert: return 'Expert';
    }
  }

  String get emoji {
    switch (this) {
      case GameDifficulty.easy:   return '🌱';
      case GameDifficulty.medium: return '⚡';
      case GameDifficulty.hard:   return '🔥';
      case GameDifficulty.expert: return '💀';
    }
  }
}

/// A single playable level — identified by difficulty + stage (1-based).
class GameLevel {
  final GameDifficulty difficulty;
  final int stage; // 1, 2, or 3

  const GameLevel({required this.difficulty, required this.stage});

  String get label => '${difficulty.label} $stage';
  String get shortLabel => difficulty.label;

  int get cardCount {
    final base = _baseCards(difficulty);
    return base + (stage - 1) * 4;
  }

  int get cols {
    final c = cardCount;
    if (c <= 12) return 4;
    if (c <= 16) return 4;
    if (c <= 20) return 5;
    return 6;
  }

  int get timeSeconds {
    final base = _baseTime(difficulty);
    // Each stage adds 20s
    return base + (stage - 1) * 20;
  }

  static int _baseCards(GameDifficulty d) {
    switch (d) {
      case GameDifficulty.easy:   return 8;
      case GameDifficulty.medium: return 12;
      case GameDifficulty.hard:   return 16;
      case GameDifficulty.expert: return 20;
    }
  }

  static int _baseTime(GameDifficulty d) {
    switch (d) {
      case GameDifficulty.easy:   return 50;
      case GameDifficulty.medium: return 70;
      case GameDifficulty.hard:   return 100;
      case GameDifficulty.expert: return 130;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is GameLevel && other.difficulty == difficulty && other.stage == stage;

  @override
  int get hashCode => Object.hash(difficulty, stage);
}

class CardModel {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.id,
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });

  CardModel copyWith({bool? isFlipped, bool? isMatched}) => CardModel(
    id: id,
    emoji: emoji,
    isFlipped: isFlipped ?? this.isFlipped,
    isMatched: isMatched ?? this.isMatched,
  );
}

// ─── Full ordered level list (4 difficulties × 3 stages = 12 levels) ─────────
const List<GameLevel> kAllLevels = [
  GameLevel(difficulty: GameDifficulty.easy,   stage: 1),
  GameLevel(difficulty: GameDifficulty.easy,   stage: 2),
  GameLevel(difficulty: GameDifficulty.easy,   stage: 3),
  GameLevel(difficulty: GameDifficulty.medium, stage: 1),
  GameLevel(difficulty: GameDifficulty.medium, stage: 2),
  GameLevel(difficulty: GameDifficulty.medium, stage: 3),
  GameLevel(difficulty: GameDifficulty.hard,   stage: 1),
  GameLevel(difficulty: GameDifficulty.hard,   stage: 2),
  GameLevel(difficulty: GameDifficulty.hard,   stage: 3),
  GameLevel(difficulty: GameDifficulty.expert, stage: 1),
  GameLevel(difficulty: GameDifficulty.expert, stage: 2),
  GameLevel(difficulty: GameDifficulty.expert, stage: 3),
];