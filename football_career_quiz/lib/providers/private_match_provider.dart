import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/player_model.dart';
import '../repositories/player_repository.dart';
import '../utils/answer_checker.dart';
import '../utils/game_rules.dart';

class PrivateMatchPlayer {
  final String userId;
  final String displayName;
  final double score;
  final int correctAnswers;

  const PrivateMatchPlayer({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.correctAnswers,
  });

  factory PrivateMatchPlayer.fromJson(Map<String, dynamic> json) {
    return PrivateMatchPlayer(
      userId: json['user_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Player',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedScore {
    if (score % 1 == 0) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }
}

class PrivateMatchProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  static const int maxWrongAttempts = 3;

  static const String _savedUserIdKey = 'career_guess_private_user_id';
  static const String _savedNameKey = 'career_guess_private_display_name';
  static const String _savedRoomCodeKey = 'career_guess_private_room_code';

  Timer? _pollTimer;
  bool _isAutoAdvancing = false;

  List<PlayerModel> _allPlayers = [];

  String userId = '';
  String displayName = '';
  String? roomCode;

  bool isLoading = false;
  bool isHost = false;
  String? errorMessage;

  Map<String, dynamic>? room;
  List<PrivateMatchPlayer> roomPlayers = [];
  List<Map<String, dynamic>> guesses = [];

  PlayerModel? currentPlayer;
  int currentRound = 1;
  bool gameFinished = false;

  String? feedbackMessage;
  bool? lastGuessWasCorrect;

  bool get hasRoom => roomCode != null && room != null;

  bool get isWaitingForFriend {
    final status = room?['status']?.toString() ?? 'waiting';
    return status == 'waiting';
  }

  bool get isMatchActive {
    final status = room?['status']?.toString() ?? 'waiting';
    return status == 'active';
  }

  bool get isUnlimitedTime {
    return room?['is_unlimited_time'] == true;
  }

  int get timeLimitSeconds {
    final value = room?['time_limit_seconds'];
    if (value is num) return value.toInt();
    return 90;
  }

  DateTime? get roundStartedAt {
    final value = room?['round_started_at'];
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  int elapsedSecondsAt(DateTime now) {
    final started = roundStartedAt;
    if (started == null) return 0;

    final elapsed = now.difference(started).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  int? timeRemainingAt(DateTime now) {
    if (isUnlimitedTime) return null;

    final remaining = timeLimitSeconds - elapsedSecondsAt(now);
    return remaining < 0 ? 0 : remaining;
  }

  bool isTimeUpAt(DateTime now) {
    if (isUnlimitedTime) return false;
    return timeRemainingAt(now) == 0;
  }

  bool get isTimeUp => isTimeUpAt(DateTime.now());

  int revealedClubCountAt(DateTime now) {
    final player = currentPlayer;
    if (player == null) return 0;

    final autoRevealed = 1 + (elapsedSecondsAt(now) ~/ GameRules.revealSeconds);
    return autoRevealed.clamp(1, player.clubs.length);
  }

  int get revealedClubCount => revealedClubCountAt(DateTime.now());

  bool get isCareerFullyRevealed {
    final player = currentPlayer;
    if (player == null) return false;

    return revealedClubCount >= player.clubs.length;
  }

  List<String> get selectedPlayerIds {
    final raw = room?['selected_player_ids'];

    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }

    return [];
  }

  int get revealedHintCount {
    final value = room?['revealed_hint_count'];
    if (value is num) return value.toInt();
    return 0;
  }

  String? get hintRequestedBy {
    return room?['hint_requested_by']?.toString();
  }

  int? get hintRequestRound {
    final value = room?['hint_request_round'];
    if (value is num) return value.toInt();
    return null;
  }

  bool get hasPendingHintRequest {
    return hintRequestedBy != null && hintRequestRound == currentRound;
  }

  bool get didIRequestHint {
    return hasPendingHintRequest && hintRequestedBy == userId;
  }

  bool get canAcceptHint {
    return hasPendingHintRequest && hintRequestedBy != userId;
  }

  List<String> get currentRoundHints {
    final player = currentPlayer;
    if (player == null) return [];

    final hints = _buildHintsForPlayer(player);
    final seed = _stableSeed('${roomCode ?? ''}_${player.id}');
    hints.shuffle(Random(seed));

    return hints;
  }

  List<String> get revealedHints {
    final hints = currentRoundHints;
    return hints.take(revealedHintCount).toList();
  }

  bool get canRequestHint {
    if (currentPlayer == null) return false;
    if (roundEnded) return false;
    if (hasPendingHintRequest) return false;

    return revealedHintCount < currentRoundHints.length;
  }

  List<Map<String, dynamic>> get currentRoundGuesses {
    final list = guesses.where((guess) {
      return (guess['round_number'] as num?)?.toInt() == currentRound;
    }).toList();

    list.sort((a, b) {
      final aTime = a['created_at']?.toString() ?? '';
      final bTime = b['created_at']?.toString() ?? '';
      return aTime.compareTo(bTime);
    });

    return list;
  }

  List<Map<String, dynamic>> get correctGuessesThisRound {
    return currentRoundGuesses.where((guess) {
      return guess['is_correct'] == true;
    }).toList();
  }

  Map<String, dynamic>? get firstCorrectGuess {
    for (final guess in currentRoundGuesses) {
      if (guess['is_correct'] == true) return guess;
    }

    return null;
  }

  String? get correctGuessPlayerName {
    if (firstCorrectGuess == null) return null;
    return currentPlayer?.name;
  }

  List<Map<String, dynamic>> guessesForUser(String targetUserId) {
    return currentRoundGuesses.where((guess) {
      return guess['user_id'] == targetUserId;
    }).toList();
  }

  List<Map<String, dynamic>> get myCurrentRoundGuesses {
    return guessesForUser(userId);
  }

  int wrongAttemptsForUser(String targetUserId) {
    return guessesForUser(targetUserId).where((guess) {
      return guess['is_correct'] != true;
    }).length;
  }

  bool hasCorrectGuessForUser(String targetUserId) {
    return guessesForUser(targetUserId).any((guess) {
      return guess['is_correct'] == true;
    });
  }

  bool isPlayerDoneForRound(String targetUserId) {
    return hasCorrectGuessForUser(targetUserId) ||
        wrongAttemptsForUser(targetUserId) >= maxWrongAttempts;
  }

  bool get areAllPlayersDoneForRound {
    if (roomPlayers.length < 2) return false;

    return roomPlayers.every((player) {
      return isPlayerDoneForRound(player.userId);
    });
  }

  bool get roundEnded {
    if (gameFinished) return true;
    if (firstCorrectGuess != null) return true;
    if (isTimeUp) return true;
    return areAllPlayersDoneForRound;
  }

  String get roundEndReason {
    if (gameFinished) return 'finished';
    if (firstCorrectGuess != null) return 'correct';
    if (isTimeUp) return 'time';
    if (areAllPlayersDoneForRound) return 'attempts_or_correct';
    return 'active';
  }

  int get myWrongAttempts => wrongAttemptsForUser(userId);

  int get attemptsLeft {
    final left = maxWrongAttempts - myWrongAttempts;
    return left < 0 ? 0 : left;
  }

  bool get hasCorrectGuessThisRound => hasCorrectGuessForUser(userId);

  bool get amIDoneForRound => isPlayerDoneForRound(userId);

  bool get canSubmitGuess {
    if (currentPlayer == null) return false;
    if (gameFinished) return false;
    if (roundEnded) return false;
    if (isTimeUp) return false;
    if (hasCorrectGuessThisRound) return false;
    if (myWrongAttempts >= maxWrongAttempts) return false;

    return true;
  }

  PrivateMatchPlayer? get me {
    for (final player in roomPlayers) {
      if (player.userId == userId) return player;
    }

    return null;
  }

  PrivateMatchPlayer? get opponent {
    for (final player in roomPlayers) {
      if (player.userId != userId) return player;
    }

    return null;
  }

  String get myFormattedScore => me?.formattedScore ?? '0';

  String get opponentFormattedScore => opponent?.formattedScore ?? '0';

  int get totalRounds {
    final value = room?['total_rounds'];
    if (value is num) return value.toInt();
    return GameRules.totalRounds;
  }

  String get difficulty {
    return room?['difficulty']?.toString() ?? 'random';
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

    for (final player in _allPlayers) {
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

  Future<void> init() async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      userId = prefs.getString(_savedUserIdKey) ?? _getOrCreateUserId();
      displayName = prefs.getString(_savedNameKey) ?? '';

      await prefs.setString(_savedUserIdKey, userId);

      if (_allPlayers.isEmpty) {
        _allPlayers = await PlayerRepository.loadPlayers();
      }

      final savedRoomCode = prefs.getString(_savedRoomCodeKey);
      if (savedRoomCode != null && savedRoomCode.trim().isNotEmpty) {
        await reconnectToSavedRoom(savedRoomCode);
      }
    } catch (e) {
      errorMessage = 'Could not initialize private match: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  String _getOrCreateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'user_${timestamp}_$random';
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    return List.generate(
      5,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }

  String _normalizeDifficulty(String value) {
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

    return 'random';
  }

  List<String> _pickPlayerIds(String selectedDifficulty) {
    final normalized = _normalizeDifficulty(selectedDifficulty);

    final pool = _allPlayers.where((player) {
      if (normalized == 'random') return true;
      return _normalizeDifficulty(player.difficulty) == normalized;
    }).toList()
      ..shuffle(_random);

    return pool.take(GameRules.totalRounds).map((player) => player.id).toList();
  }

  PlayerModel? _playerById(String id) {
    for (final player in _allPlayers) {
      if (player.id == id) return player;
    }

    return null;
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_savedUserIdKey, userId);

    if (displayName.trim().isNotEmpty) {
      await prefs.setString(_savedNameKey, displayName.trim());
    }

    final code = roomCode;
    if (code != null && code.trim().isNotEmpty) {
      await prefs.setString(_savedRoomCodeKey, code.trim().toUpperCase());
    }
  }

  Future<void> _clearSavedRoomOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedRoomCodeKey);
  }

  Future<bool> reconnectToSavedRoom(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return false;

    try {
      if (_allPlayers.isEmpty) {
        _allPlayers = await PlayerRepository.loadPlayers();
      }

      final existingRoom = await _supabase
          .from('private_rooms')
          .select()
          .eq('room_code', normalizedCode)
          .maybeSingle();

      if (existingRoom == null) {
        await _clearSavedRoomOnly();
        return false;
      }

      roomCode = normalizedCode;
      isHost = existingRoom['host_id']?.toString() == userId;

      await _refreshRoom();
      _startPolling();
      await _saveSession();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createRoom({
    required String name,
    required String selectedDifficulty,
    required bool unlimitedTime,
  }) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      errorMessage = 'Please enter your name before creating a room.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_allPlayers.isEmpty || userId.isEmpty) {
        await init();
      }

      displayName = trimmedName;
      isHost = true;

      final code = _generateRoomCode();
      final normalizedDifficulty = _normalizeDifficulty(selectedDifficulty);
      final playerIds = _pickPlayerIds(normalizedDifficulty);

      if (playerIds.isEmpty) {
        errorMessage = 'No players available for this difficulty.';
        isLoading = false;
        notifyListeners();
        return;
      }

      await _supabase.from('private_rooms').insert({
        'room_code': code,
        'status': 'waiting',
        'host_id': userId,
        'guest_id': null,
        'current_round': 1,
        'total_rounds': GameRules.totalRounds,
        'selected_player_ids': playerIds,
        'difficulty': normalizedDifficulty,
        'is_unlimited_time': unlimitedTime,
        'time_limit_seconds': 90,
        'round_started_at': DateTime.now().toUtc().toIso8601String(),
        'hint_requested_by': null,
        'hint_request_round': null,
        'revealed_hint_count': 0,
      });

      await _supabase.from('private_room_players').insert({
        'room_code': code,
        'user_id': userId,
        'display_name': displayName,
        'score': 0,
        'correct_answers': 0,
      });

      roomCode = code;
      gameFinished = false;
      currentRound = 1;
      feedbackMessage = null;
      lastGuessWasCorrect = null;

      await _saveSession();
      await _refreshRoom();
      _startPolling();
    } catch (e) {
      errorMessage = 'Could not create room: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> joinRoom({
    required String code,
    required String name,
  }) async {
    final trimmedName = name.trim();
    final normalizedCode = code.trim().toUpperCase();

    if (trimmedName.isEmpty) {
      errorMessage = 'Please enter your name before joining a room.';
      notifyListeners();
      return;
    }

    if (normalizedCode.isEmpty) {
      errorMessage = 'Please enter a room code.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_allPlayers.isEmpty || userId.isEmpty) {
        await init();
      }

      displayName = trimmedName;

      final existingRoom = await _supabase
          .from('private_rooms')
          .select()
          .eq('room_code', normalizedCode)
          .maybeSingle();

      if (existingRoom == null) {
        errorMessage = 'Room not found.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final status = existingRoom['status']?.toString() ?? 'waiting';

      if (status == 'finished') {
        errorMessage = 'This match has already finished.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final hostId = existingRoom['host_id']?.toString();
      final guestId = existingRoom['guest_id']?.toString();

      isHost = hostId == userId;

      if (guestId != null &&
          guestId.isNotEmpty &&
          guestId != userId &&
          hostId != userId) {
        errorMessage = 'This room already has two players.';
        isLoading = false;
        notifyListeners();
        return;
      }

      await _supabase.from('private_room_players').upsert({
        'room_code': normalizedCode,
        'user_id': userId,
        'display_name': displayName,
        'score': 0,
        'correct_answers': 0,
      });

      final updateData = <String, dynamic>{};

      if (hostId != userId) {
        updateData['guest_id'] = userId;
      }

      if (status == 'waiting') {
        updateData['status'] = 'active';
        updateData['round_started_at'] =
            DateTime.now().toUtc().toIso8601String();
      }

      if (updateData.isNotEmpty) {
        await _supabase
            .from('private_rooms')
            .update(updateData)
            .eq('room_code', normalizedCode);
      }

      roomCode = normalizedCode;
      gameFinished = false;
      feedbackMessage = null;
      lastGuessWasCorrect = null;

      await _saveSession();
      await _refreshRoom();
      _startPolling();
    } catch (e) {
      errorMessage = 'Could not join room: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        await _refreshRoom();
      },
    );
  }

  Future<void> _refreshRoom() async {
    final code = roomCode;
    if (code == null) return;

    try {
      final roomData = await _supabase
          .from('private_rooms')
          .select()
          .eq('room_code', code)
          .maybeSingle();

      if (roomData == null) {
        await _clearSavedRoomOnly();
        return;
      }

      final playersData = await _supabase
          .from('private_room_players')
          .select()
          .eq('room_code', code)
          .order('joined_at');

      final guessesData = await _supabase
          .from('private_guesses')
          .select()
          .eq('room_code', code)
          .order('created_at');

      final newRoom = Map<String, dynamic>.from(roomData);

      final newPlayers = (playersData as List)
          .whereType<Map<String, dynamic>>()
          .map(PrivateMatchPlayer.fromJson)
          .toList();

      final newGuesses = (guessesData as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final changed = _roomChangeKey(room) != _roomChangeKey(newRoom) ||
          _playersChangeKey(roomPlayers) != _playersChangeKey(newPlayers) ||
          _guessesChangeKey(guesses) != _guessesChangeKey(newGuesses);

      if (!changed) return;

      room = newRoom;
      roomPlayers = newPlayers;
      guesses = newGuesses;

      currentRound = (room?['current_round'] as num?)?.toInt() ?? 1;
      isHost = room?['host_id']?.toString() == userId;

      _syncCurrentPlayer();
      _syncRoundState();

      notifyListeners();
    } catch (_) {
      // Keep last good state if one poll fails.
    }
  }

  String _roomChangeKey(Map<String, dynamic>? value) {
    if (value == null) return '';

    return [
      value['room_code'],
      value['status'],
      value['host_id'],
      value['guest_id'],
      value['current_round'],
      value['difficulty'],
      value['is_unlimited_time'],
      value['time_limit_seconds'],
      value['round_started_at'],
      value['hint_requested_by'],
      value['hint_request_round'],
      value['revealed_hint_count'],
    ].join('|');
  }

  String _playersChangeKey(List<PrivateMatchPlayer> players) {
    return players.map((player) {
      return [
        player.userId,
        player.displayName,
        player.score,
        player.correctAnswers,
      ].join(':');
    }).join('|');
  }

  String _guessesChangeKey(List<Map<String, dynamic>> items) {
    return items.map((guess) {
      return [
        guess['id'],
        guess['room_code'],
        guess['round_number'],
        guess['user_id'],
        guess['guess'],
        guess['is_correct'],
        guess['points'],
        guess['created_at'],
      ].join(':');
    }).join('|');
  }

  void _syncCurrentPlayer() {
    final ids = selectedPlayerIds;
    if (ids.isEmpty) return;

    final index = currentRound - 1;

    if (index < 0 || index >= ids.length) {
      gameFinished = true;
      currentPlayer = null;
      return;
    }

    final nextPlayer = _playerById(ids[index]);

    if (currentPlayer?.id != nextPlayer?.id) {
      currentPlayer = nextPlayer;
      feedbackMessage = null;
      lastGuessWasCorrect = null;
      _isAutoAdvancing = false;
    }
  }

  void _syncRoundState() {
    if (room?['status']?.toString() == 'finished') {
      gameFinished = true;
    }

    if (currentRound > totalRounds) {
      gameFinished = true;
    }
  }

  Future<void> requestHint() async {
    final code = roomCode;
    if (code == null || !canRequestHint) return;

    await _supabase.from('private_rooms').update({
      'hint_requested_by': userId,
      'hint_request_round': currentRound,
    }).eq('room_code', code);

    await _refreshRoom();
  }

  Future<void> acceptHint() async {
    final code = roomCode;
    if (code == null || !canAcceptHint) return;

    await _supabase.from('private_rooms').update({
      'revealed_hint_count': revealedHintCount + 1,
      'hint_requested_by': null,
      'hint_request_round': null,
    }).eq('room_code', code);

    await _refreshRoom();
  }

  Future<void> declineHint() async {
    final code = roomCode;
    if (code == null || !canAcceptHint) return;

    await _supabase.from('private_rooms').update({
      'hint_requested_by': null,
      'hint_request_round': null,
    }).eq('room_code', code);

    await _refreshRoom();
  }

  List<String> _buildHintsForPlayer(PlayerModel player) {
    final hints = <String>[];

    for (final customHint in player.hints) {
      final text = customHint.trim();
      if (text.isNotEmpty) hints.add(text);
    }

    if (player.position.trim().isNotEmpty) {
      hints.add('Position: ${player.position}.');
    }

    if (player.nationality.trim().isNotEmpty) {
      hints.add('Nationality: ${player.nationality}.');
    }

    if (player.knownClubNumbers.isNotEmpty) {
      for (final entry in player.knownClubNumbers.entries) {
        if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty) {
          hints.add('Wore number ${entry.value} for ${entry.key}.');
        }
      }
    }

    return hints.toSet().toList();
  }

  int _stableSeed(String input) {
    var hash = 0;

    for (final codeUnit in input.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash = hash ^ (hash >> 6);
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash;
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

  Future<void> submitGuess(String guessText) async {
    final code = roomCode;
    final player = currentPlayer;

    if (code == null || player == null) return;
    if (!canSubmitGuess) return;

    final guess = guessText.trim();
    if (guess.isEmpty) return;

    await _refreshRoom();

    if (!canSubmitGuess) {
      feedbackMessage = 'You can no longer guess this round.';
      notifyListeners();
      return;
    }

    final isCorrect = AnswerChecker.isCorrect(
      guess: guess,
      acceptedAnswers: player.acceptedAnswers,
    );

    final visibleClubs = revealedClubCountAt(DateTime.now());

    final basePoints = isCorrect
        ? GameRules.calculatePoints(
            totalClubs: player.clubs.length,
            revealedClubs: visibleClubs,
            isCareerFullyRevealed: visibleClubs >= player.clubs.length,
          )
        : 0;

    final points = isCorrect
        ? _calculateEarnedPoints(
            basePoints: basePoints,
            hintsUsed: revealedHintCount,
          )
        : 0.0;

    try {
      await _supabase.from('private_guesses').insert({
        'room_code': code,
        'round_number': currentRound,
        'user_id': userId,
        'guess': guess,
        'is_correct': isCorrect,
        'points': points,
      });

      if (isCorrect) {
        final currentMe = me;
        final newScore = (currentMe?.score ?? 0) + points;
        final newCorrect = (currentMe?.correctAnswers ?? 0) + 1;

        await _supabase
            .from('private_room_players')
            .update({
              'score': newScore,
              'correct_answers': newCorrect,
            })
            .eq('room_code', code)
            .eq('user_id', userId);
      }

      lastGuessWasCorrect = isCorrect;

      if (isCorrect) {
        if (revealedHintCount >= 3) {
          feedbackMessage = 'Correct, but no points because 3 hints were used.';
        } else if (revealedHintCount >= 1) {
          feedbackMessage = 'Correct! +${_formatPoints(points)} point.';
        } else {
          feedbackMessage = 'Correct! +${_formatPoints(points)} points.';
        }
      } else {
        final remaining = attemptsLeft - 1;

        if (remaining <= 0) {
          feedbackMessage = 'Wrong. You used all 3 attempts.';
        } else {
          feedbackMessage = 'Wrong. $remaining attempts left.';
        }
      }

      await _refreshRoom();
    } catch (e) {
      errorMessage = 'Could not submit guess: $e';
      notifyListeners();
    }
  }

  Future<void> autoAdvanceRoundIfHost({
    Duration revealDelay = const Duration(seconds: 3),
  }) async {
    if (!isHost) return;
    if (!roundEnded) return;
    if (_isAutoAdvancing) return;

    _isAutoAdvancing = true;

    final lockedRound = currentRound;

    await Future.delayed(revealDelay);

    if (currentRound != lockedRound) {
      _isAutoAdvancing = false;
      return;
    }

    await _refreshRoom();

    if (currentRound != lockedRound) {
      _isAutoAdvancing = false;
      return;
    }

    if (!roundEnded) {
      _isAutoAdvancing = false;
      return;
    }

    await nextRoundIfHost();
    _isAutoAdvancing = false;
  }

  Future<void> nextRoundIfHost() async {
    final code = roomCode;
    if (code == null) return;
    if (!isHost) return;

    if (currentRound >= totalRounds) {
      await _supabase
          .from('private_rooms')
          .update({'status': 'finished'}).eq('room_code', code);

      gameFinished = true;
      await _refreshRoom();
      return;
    }

    await _supabase.from('private_rooms').update({
      'current_round': currentRound + 1,
      'round_started_at': DateTime.now().toUtc().toIso8601String(),
      'hint_requested_by': null,
      'hint_request_round': null,
      'revealed_hint_count': 0,
    }).eq('room_code', code);

    feedbackMessage = null;
    lastGuessWasCorrect = null;

    await _refreshRoom();
  }

  Future<void> leaveRoom() async {
    final code = roomCode;

    _pollTimer?.cancel();

    if (code != null) {
      try {
        await _supabase.from('private_rooms').update({
          'status': 'finished',
        }).eq('room_code', code);
      } catch (_) {
        // Still clear local state even if Supabase update fails.
      }
    }

    roomCode = null;
    room = null;
    roomPlayers = [];
    guesses = [];
    currentPlayer = null;
    currentRound = 1;
    gameFinished = false;
    feedbackMessage = null;
    lastGuessWasCorrect = null;
    errorMessage = null;
    isHost = false;
    _isAutoAdvancing = false;

    await _clearSavedRoomOnly();

    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
