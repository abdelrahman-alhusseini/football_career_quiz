class GameRules {
  static const int totalRounds = 10;
  static const int revealSeconds = 3;

  static int calculatePoints({
    required int totalClubs,
    required int revealedClubs,
    required bool isCareerFullyRevealed,
  }) {
    if (isCareerFullyRevealed) {
      return 1;
    }

    return 2;
  }
}
