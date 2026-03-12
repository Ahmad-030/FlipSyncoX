// ─── Models ───────────────────────────────────────────────────────────────────

enum GameLevel { easy, medium, hard, expert }

extension GameLevelExt on GameLevel {
  String get label {
    switch (this) {
      case GameLevel.easy:   return 'Easy';
      case GameLevel.medium: return 'Medium';
      case GameLevel.hard:   return 'Hard';
      case GameLevel.expert: return 'Expert';
    }
  }

  int get cardCount {
    switch (this) {
      case GameLevel.easy:   return 12;
      case GameLevel.medium: return 16;
      case GameLevel.hard:   return 20;
      case GameLevel.expert: return 24;
    }
  }

  int get cols {
    switch (this) {
      case GameLevel.easy:   return 4;
      case GameLevel.medium: return 4;
      case GameLevel.hard:   return 5;
      case GameLevel.expert: return 6;
    }
  }

  int get timeSeconds {
    switch (this) {
      case GameLevel.easy:   return 60;
      case GameLevel.medium: return 90;
      case GameLevel.hard:   return 120;
      case GameLevel.expert: return 150;
    }
  }
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