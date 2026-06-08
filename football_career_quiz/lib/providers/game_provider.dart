import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import '../utils/answer_checker.dart';
import '../utils/game_rules.dart';

class RoundReview {
  final String playerName;
  final String nationality;
  final String difficulty;
  final String status;
  final List<String> clubNames;
  final bool wasCorrect;
  final bool wasSkipped;
  final int hintsUsed;
  final double earnedPoints;

  const RoundReview({
    required this.playerName,
    required this.nationality,
    required this.difficulty,
    required this.status,
    required this.clubNames,
    required this.wasCorrect,
    required this.wasSkipped,
    required this.hintsUsed,
    required this.earnedPoints,
  });

  String get statusLabel {
    final value = status.trim().toLowerCase();

    if (value == 'active') return 'Current player';
    if (value == 'retired') return 'Retired player';
    if (value == 'legend') return 'Retired legend';

    if (value.isEmpty) return 'Status unknown';

    return value
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }
}

class GameProvider extends ChangeNotifier {
  final Random _random = Random();
  Timer? _timer;

  static const int maxWrongAttempts = 3;

  List<PlayerModel> _players = [];

  PlayerModel? currentPlayer;

  double score = 0;
  int currentRound = 1;
  int revealedClubCount = 1;

  int correctAnswers = 0;
  int skippedRounds = 0;

  int wrongAttemptsThisRound = 0;

  bool isLoading = true;
  bool roundEnded = false;
  bool gameFinished = false;

  bool? lastGuessWasCorrect;
  String? feedbackMessage;

  String selectedDifficulty = 'random';

  bool hintsEnabled = true;

  final List<String> revealedHints = [];
  List<String> _roundHints = [];

  final List<RoundReview> roundReviews = [];

  GameProvider() {
    loadPlayers();
  }

  bool get isCareerFullyRevealed {
    final player = currentPlayer;
    if (player == null) return false;
    return revealedClubCount >= player.clubs.length;
  }

  int get totalRounds => GameRules.totalRounds;

  int get maxScore => GameRules.totalRounds * 3;

  int get usedHints => revealedHints.length;

  int get attemptsLeft {
    final left = maxWrongAttempts - wrongAttemptsThisRound;
    return left < 0 ? 0 : left;
  }

  bool get canSubmitGuess {
    if (currentPlayer == null) return false;
    if (roundEnded || gameFinished) return false;
    return wrongAttemptsThisRound < maxWrongAttempts;
  }

  List<RoundReview> get missedRounds {
    return roundReviews.where((review) => !review.wasCorrect).toList();
  }

  int get finalAccuracyPercent {
    if (GameRules.totalRounds == 0) return 0;
    return ((correctAnswers / GameRules.totalRounds) * 100).round();
  }

  String get formattedScore {
    if (score % 1 == 0) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }

  String get formattedMaxScore {
    return maxScore.toString();
  }

  String get finalRank {
    final ratio = maxScore == 0 ? 0.0 : score / maxScore;

    if (ratio >= 0.90) return 'GOAT';
    if (ratio >= 0.70) return 'Legend';
    if (ratio >= 0.50) return 'Pro';
    return 'Amateur';
  }

  String get currentPlayerStatusText {
    final status = currentPlayer?.status.trim().toLowerCase() ?? '';

    if (status == 'active') return 'Current player';
    if (status == 'retired') return 'Retired player';
    if (status == 'legend') return 'Retired legend';

    if (status.isEmpty) return 'Status unknown';

    return status
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  bool get isCurrentPlayerRetired {
    final status = currentPlayer?.status.trim().toLowerCase() ?? '';
    return status == 'retired' || status == 'legend';
  }

  String get currentDifficultyLabel {
    return difficultyLabel(selectedDifficulty);
  }

  static String normalizeDifficulty(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'all') return 'random';
    if (normalized == 'random') return 'random';

    if (normalized == 'easy') return 'amateur';
    if (normalized == 'amateur') return 'amateur';

    if (normalized == 'medium') return 'pro';
    if (normalized == 'pro') return 'pro';

    if (normalized == 'hard') return 'legend';
    if (normalized == 'elite') return 'legend';
    if (normalized == 'legend') return 'legend';

    if (normalized == 'exceptional') return 'expert';
    if (normalized == 'goat') return 'expert';
    if (normalized == 'expert') return 'expert';

    return normalized;
  }

  static String difficultyLabel(String value) {
    switch (normalizeDifficulty(value)) {
      case 'amateur':
        return 'Amateur';
      case 'pro':
        return 'Pro';
      case 'legend':
        return 'Legend';
      case 'expert':
        return 'Expert';
      case 'random':
        return 'Random';
      default:
        return 'Random';
    }
  }

  bool get canUseHint {
    if (!hintsEnabled) return false;
    if (roundEnded || gameFinished) return false;
    if (currentPlayer == null) return false;

    return revealedHints.length < _roundHints.length;
  }

  List<PlayerModel> get availablePlayers {
    final selected = normalizeDifficulty(selectedDifficulty);

    if (selected == 'random') return _players;

    return _players.where((player) {
      return normalizeDifficulty(player.difficulty) == selected;
    }).toList();
  }

  List<String> get searchableAnswers {
    final answersByNormalizedText = <String, String>{};

    void addAnswer(String value, {bool preferThisText = false}) {
      final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) return;

      final key = _normalizeSearchText(cleaned);

      if (preferThisText || !answersByNormalizedText.containsKey(key)) {
        answersByNormalizedText[key] = cleaned;
      }
    }

    for (final player in _players) {
      addAnswer(player.name, preferThisText: true);

      for (final answer in player.acceptedAnswers) {
        addAnswer(answer);
      }
    }

    final sorted = answersByNormalizedText.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sorted;
  }

  List<String> searchAnswerSuggestions(
    String query, {
    int limit = 8,
  }) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.length < 2) return [];

    final startsWithMatches = <String>[];
    final containsMatches = <String>[];

    for (final answer in searchableAnswers) {
      final normalizedAnswer = _normalizeSearchText(answer);

      if (normalizedAnswer.startsWith(normalizedQuery)) {
        startsWithMatches.add(answer);
      } else if (normalizedAnswer.contains(normalizedQuery)) {
        containsMatches.add(answer);
      }
    }

    final combined = <String>[
      ...startsWithMatches,
      ...containsMatches,
    ];

    final unique = <String>[];
    final seen = <String>{};

    for (final item in combined) {
      final key = _normalizeSearchText(item);

      if (seen.add(key)) {
        unique.add(item);
      }

      if (unique.length >= limit) break;
    }

    return unique;
  }

  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }

  Future<void> loadPlayers() async {
    isLoading = true;
    notifyListeners();

    try {
      _players = await PlayerRepository.loadPlayers();
      _resetGameState();
      _startRound();
    } catch (_) {
      feedbackMessage = 'Could not load players database.';
    }

    isLoading = false;
    notifyListeners();
  }

  void setDifficulty(String difficulty) {
    selectedDifficulty = normalizeDifficulty(difficulty);
    startNewGame();
  }

  void startNewGame() {
    _timer?.cancel();
    _resetGameState();
    _startRound();
    notifyListeners();
  }

  void _resetGameState() {
    score = 0;
    currentRound = 1;
    revealedClubCount = 1;

    correctAnswers = 0;
    skippedRounds = 0;
    wrongAttemptsThisRound = 0;

    revealedHints.clear();
    _roundHints = [];
    roundReviews.clear();

    roundEnded = false;
    gameFinished = false;

    lastGuessWasCorrect = null;
    feedbackMessage = null;
  }

  void _startRound() {
    _timer?.cancel();

    if (gameFinished) return;

    final pool = availablePlayers;

    if (pool.isEmpty) {
      currentPlayer = null;
      feedbackMessage = 'No players available for this difficulty.';
      return;
    }

    currentPlayer = pool[_random.nextInt(pool.length)];

    revealedClubCount = 1;
    wrongAttemptsThisRound = 0;
    revealedHints.clear();

    if (currentPlayer != null) {
      _roundHints = _buildHintsForPlayer(currentPlayer!);
      _roundHints.shuffle(_random);
    } else {
      _roundHints = [];
    }

    roundEnded = false;
    lastGuessWasCorrect = null;
    feedbackMessage = null;

    _timer = Timer.periodic(
      const Duration(seconds: GameRules.revealSeconds),
      (_) {
        revealNextClub();
      },
    );
  }

  void revealNextClub() {
    final player = currentPlayer;

    if (player == null || roundEnded || gameFinished) return;

    if (revealedClubCount < player.clubs.length) {
      revealedClubCount++;
      notifyListeners();
    } else {
      _timer?.cancel();
      notifyListeners();
    }
  }

  void useHint() {
    if (!canUseHint) return;

    final nextHint = _roundHints[revealedHints.length];
    revealedHints.add(nextHint);

    notifyListeners();
  }

  List<String> _buildHintsForPlayer(PlayerModel player) {
    final hints = <String>[];

    for (final customHint in player.hints) {
      final text = customHint.trim();
      if (text.isNotEmpty) hints.add(text);
    }

    if (player.position.trim().isNotEmpty) {
      final positionHint = 'Position: ${player.position}.';
      if (!hints.contains(positionHint)) hints.add(positionHint);
    }

    if (player.nationality.trim().isNotEmpty) {
      final nationalityHint = 'Nationality: ${player.nationality}.';
      if (!hints.contains(nationalityHint)) hints.add(nationalityHint);
    }

    if (player.knownClubNumbers.isNotEmpty) {
      for (final entry in player.knownClubNumbers.entries) {
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty) {
          final numberHint = 'Wore number ${entry.value} for ${entry.key}.';
          if (!hints.contains(numberHint)) hints.add(numberHint);
        }
      }
    }

    return hints.toSet().toList();
  }

  double _calculateEarnedPoints({
    required int basePoints,
    required int hintsUsed,
  }) {
    if (hintsUsed >= 3) return 0;
    if (hintsUsed >= 1) return 0.5;
    return basePoints.toDouble();
  }

  String _formatPoints(double points) {
    if (points % 1 == 0) return points.toInt().toString();
    return points.toStringAsFixed(1);
  }

  void _saveRoundReview({
    required PlayerModel player,
    required bool wasCorrect,
    required bool wasSkipped,
    required double earnedPoints,
  }) {
    final alreadySaved = roundReviews.length >= currentRound;
    if (alreadySaved) return;

    roundReviews.add(
      RoundReview(
        playerName: player.name,
        nationality: player.nationality,
        difficulty: normalizeDifficulty(player.difficulty),
        status: player.status,
        clubNames: player.clubs.map((club) => club.name).toList(),
        wasCorrect: wasCorrect,
        wasSkipped: wasSkipped,
        hintsUsed: usedHints,
        earnedPoints: earnedPoints,
      ),
    );
  }

  void submitGuess(String guess) {
    final player = currentPlayer;

    if (player == null || roundEnded || gameFinished) return;
    if (!canSubmitGuess) return;

    final isCorrect = AnswerChecker.isCorrect(
      guess: guess,
      acceptedAnswers: player.acceptedAnswers,
    );

    if (!isCorrect) {
      wrongAttemptsThisRound++;
      lastGuessWasCorrect = false;

      if (wrongAttemptsThisRound >= maxWrongAttempts) {
        roundEnded = true;

        _saveRoundReview(
          player: player,
          wasCorrect: false,
          wasSkipped: false,
          earnedPoints: 0,
        );

        feedbackMessage =
            'Wrong answer.\nNo attempts left.\nThe player was ${player.name}.';

        _timer?.cancel();
      } else {
        feedbackMessage = 'Wrong answer.\n$attemptsLeft attempts left.';
      }

      notifyListeners();
      return;
    }

    final basePoints = GameRules.calculatePoints(
      totalClubs: player.clubs.length,
      revealedClubs: revealedClubCount,
      isCareerFullyRevealed: isCareerFullyRevealed,
    );

    final earnedPoints = _calculateEarnedPoints(
      basePoints: basePoints,
      hintsUsed: usedHints,
    );

    score += earnedPoints;
    correctAnswers++;

    _saveRoundReview(
      player: player,
      wasCorrect: true,
      wasSkipped: false,
      earnedPoints: earnedPoints,
    );

    roundEnded = true;
    lastGuessWasCorrect = true;

    final pointsText = _formatPoints(earnedPoints);

    if (usedHints >= 3) {
      feedbackMessage =
          'Correct, but no points because you used 3 hints.\nThe player was ${player.name}.';
    } else if (usedHints >= 1) {
      feedbackMessage =
          'Correct! +$pointsText point because you used hints.\nThe player was ${player.name}.';
    } else {
      feedbackMessage =
          'Correct! +$pointsText points.\nThe player was ${player.name}.';
    }

    _timer?.cancel();
    notifyListeners();
  }

  void nextRound() {
    if (gameFinished) return;

    _timer?.cancel();

    final player = currentPlayer;

    if (!roundEnded) {
      skippedRounds++;
      roundEnded = true;
      lastGuessWasCorrect = false;

      if (player != null) {
        _saveRoundReview(
          player: player,
          wasCorrect: false,
          wasSkipped: true,
          earnedPoints: 0,
        );
      }

      final playerName = player?.name;
      feedbackMessage = playerName == null
          ? 'Round skipped.'
          : 'Skipped.\nThe player was $playerName.';
    }

    if (currentRound >= GameRules.totalRounds) {
      _finishGame();
    } else {
      currentRound++;
      _startRound();
    }

    notifyListeners();
  }

  void _finishGame() {
    _timer?.cancel();

    gameFinished = true;
    roundEnded = true;
    currentPlayer = null;
    revealedClubCount = 0;
    revealedHints.clear();
    _roundHints = [];

    feedbackMessage = null;
    lastGuessWasCorrect = null;
    wrongAttemptsThisRound = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
