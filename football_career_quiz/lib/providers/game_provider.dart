import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import '../utils/answer_checker.dart';
import '../utils/game_rules.dart';

class GameProvider extends ChangeNotifier {
  final Random _random = Random();

  Timer? _timer;

  List<PlayerModel> _players = [];

  PlayerModel? currentPlayer;

  int score = 0;
  int currentRound = 1;
  int revealedClubCount = 1;

  bool isLoading = true;
  bool roundEnded = false;
  bool? lastGuessWasCorrect;
  String? feedbackMessage;

  String selectedDifficulty = 'all';

  GameProvider() {
    loadPlayers();
  }

  bool get isCareerFullyRevealed {
    final player = currentPlayer;
    if (player == null) return false;
    return revealedClubCount >= player.clubs.length;
  }

  List<PlayerModel> get availablePlayers {
    if (selectedDifficulty == 'all') return _players;

    return _players
        .where((player) => player.difficulty == selectedDifficulty)
        .toList();
  }

  Future<void> loadPlayers() async {
    isLoading = true;
    notifyListeners();

    try {
      _players = await PlayerRepository.loadPlayers();
      startNewGame();
    } catch (error) {
      feedbackMessage = 'Could not load players database.';
    }

    isLoading = false;
    notifyListeners();
  }

  void setDifficulty(String difficulty) {
    selectedDifficulty = difficulty;
    startNewGame();
  }

  void startNewGame() {
    _timer?.cancel();

    score = 0;
    currentRound = 1;
    _startRound();

    notifyListeners();
  }

  void _startRound() {
    _timer?.cancel();

    final pool = availablePlayers;

    if (pool.isEmpty) {
      currentPlayer = null;
      feedbackMessage = 'No players available for this difficulty.';
      return;
    }

    currentPlayer = pool[_random.nextInt(pool.length)];
    revealedClubCount = 1;
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
    if (player == null || roundEnded) return;

    if (revealedClubCount < player.clubs.length) {
      revealedClubCount++;
      notifyListeners();
    } else {
      _timer?.cancel();
      notifyListeners();
    }
  }

  void submitGuess(String guess) {
    final player = currentPlayer;
    if (player == null || roundEnded) return;

    final isCorrect = AnswerChecker.isCorrect(
      guess: guess,
      acceptedAnswers: player.acceptedAnswers,
    );

    if (!isCorrect) {
      lastGuessWasCorrect = false;
      feedbackMessage = 'Wrong guess. Try again!';
      notifyListeners();
      return;
    }

    final earnedPoints = GameRules.calculatePoints(
      totalClubs: player.clubs.length,
      revealedClubs: revealedClubCount,
      isCareerFullyRevealed: isCareerFullyRevealed,
    );

    score += earnedPoints;
    roundEnded = true;
    lastGuessWasCorrect = true;
    feedbackMessage =
        'Correct! +$earnedPoints points. The player was ${player.name}.';

    _timer?.cancel();
    notifyListeners();
  }

  void nextRound() {
    _timer?.cancel();

    if (currentRound >= GameRules.totalRounds) {
      currentRound = 1;
      score = 0;
    } else {
      currentRound++;
    }

    _startRound();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
