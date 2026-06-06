class GameRules {
  static const int totalRounds = 10;
  static const int revealSeconds = 3;

  static int calculatePoints({
    required int totalClubs,
    required int revealedClubs,
    required bool isCareerFullyRevealed,
  }) {
    if (revealedClubs <= 1) {
      return 3;
    }

    if (totalClubs > 8 && revealedClubs <= 2) {
      return 3;
    }

    if (isCareerFullyRevealed) {
      return 1;
    }

    return 2;
  }
}
