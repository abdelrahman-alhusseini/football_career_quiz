import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player_model.dart';
import '../providers/game_provider.dart';
import '../repositories/player_repository.dart';
import '../utils/app_theme.dart';
import '../utils/game_rules.dart';
import '../widgets/career_timeline.dart';
import '../widgets/pitch_background.dart';

class SoloGameScreen extends StatefulWidget {
  static const String routeName = '/solo';

  const SoloGameScreen({super.key});

  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> {
  final TextEditingController _controller = TextEditingController();

  static const int _maxWrongAttempts = 3;

  List<String> _answerOptions = [];

  Timer? _wrongBoxTimer;
  String? _wrongBoxMessage;

  String? _activeRoundKey;
  int _wrongAttemptsThisRound = 0;
  bool _localRoundLocked = false;

  @override
  void initState() {
    super.initState();
    _loadAnswerOptions();
  }

  @override
  void dispose() {
    _wrongBoxTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAnswerOptions() async {
    try {
      final players = await PlayerRepository.loadPlayers();
      final options = _buildSearchOptions(players);

      if (!mounted) return;

      setState(() {
        _answerOptions = options;
      });
    } catch (_) {
      // Keep the game playable even if suggestions fail to load.
    }
  }

  List<String> _buildSearchOptions(List<PlayerModel> players) {
    final answersByNormalizedText = <String, String>{};

    void addAnswer(String value, {bool preferThisText = false}) {
      final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) return;

      final key = _normalizeSearchText(cleaned);

      if (preferThisText || !answersByNormalizedText.containsKey(key)) {
        answersByNormalizedText[key] = cleaned;
      }
    }

    for (final player in players) {
      addAnswer(player.name, preferThisText: true);

      for (final answer in player.acceptedAnswers) {
        addAnswer(answer);
      }
    }

    final sorted = answersByNormalizedText.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sorted;
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

  void _syncLocalRoundState(GameProvider game, String playerId) {
    final nextKey = '${game.currentRound}_$playerId';

    if (_activeRoundKey == nextKey) return;

    _activeRoundKey = nextKey;
    _wrongAttemptsThisRound = 0;
    _localRoundLocked = false;
    _wrongBoxMessage = null;
    _wrongBoxTimer?.cancel();
  }

  void _showWrongBox() {
    final attemptsLeft = (_maxWrongAttempts - _wrongAttemptsThisRound).clamp(
      0,
      _maxWrongAttempts,
    );

    _wrongBoxTimer?.cancel();

    setState(() {
      _wrongBoxMessage = 'Wrong answer — $attemptsLeft attempts left';
    });

    _wrongBoxTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (!mounted) return;

        setState(() {
          _wrongBoxMessage = null;
        });
      },
    );
  }

  void _submitGuess(GameProvider game) {
    if (_localRoundLocked || game.roundEnded) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    game.submitGuess(text);
    _controller.clear();

    final wasCorrect = game.lastGuessWasCorrect == true;

    if (!wasCorrect) {
      _wrongAttemptsThisRound++;

      if (_wrongAttemptsThisRound >= _maxWrongAttempts) {
        _localRoundLocked = true;
      }

      _showWrongBox();
    }
  }

  void _resetAndStartNewGame() {
    _controller.clear();
    _wrongBoxTimer?.cancel();

    setState(() {
      _activeRoundKey = null;
      _wrongAttemptsThisRound = 0;
      _localRoundLocked = false;
      _wrongBoxMessage = null;
    });

    context.read<GameProvider>().startNewGame();
  }

  void _goNextRound(GameProvider game) {
    _controller.clear();
    _wrongBoxTimer?.cancel();

    setState(() {
      _activeRoundKey = null;
      _wrongAttemptsThisRound = 0;
      _localRoundLocked = false;
      _wrongBoxMessage = null;
    });

    game.nextRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, game, _) {
              final player = game.currentPlayer;

              if (game.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.accent,
                  ),
                );
              }

              if (game.gameFinished) {
                return _FinalResultView(game: game);
              }

              if (player == null) {
                return const Center(
                  child: Text(
                    'No players found.',
                    style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }

              _syncLocalRoundState(game, player.id);

              final visibleClubs =
                  player.clubs.take(game.revealedClubCount).toList();

              final roundEnded = game.roundEnded;
              final inputEnabled = !roundEnded && !_localRoundLocked;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Image.asset(
                                  'assets/images/career_guess_logo.png',
                                  height: 62,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Text(
                                      'Career Guess',
                                      style: TextStyle(
                                        color: AppTheme.text,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CircleIconButton(
                              icon: Icons.refresh_rounded,
                              onTap: _resetAndStartNewGame,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _TopInfoCard(
                              label: 'Score',
                              value: game.formattedScore,
                              valueColor: AppTheme.gold,
                              icon: Icons.emoji_events_rounded,
                            ),
                            const SizedBox(width: 10),
                            _TopInfoCard(
                              label: 'Round',
                              value:
                                  '${game.currentRound}/${GameRules.totalRounds}',
                              valueColor: AppTheme.accent,
                              icon: Icons.sports_soccer_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: const Color(0xFF02101F).withOpacity(0.45),
                              border: Border.all(
                                color: AppTheme.stadiumBlue.withOpacity(0.34),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.22),
                                  blurRadius: 22,
                                  offset: const Offset(0, 14),
                                ),
                                BoxShadow(
                                  color: AppTheme.stadiumBlue.withOpacity(0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Expanded(
                                        child: Row(
                                          children: [
                                            _GlowingTargetIcon(),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Guess the Player',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: AppTheme.text,
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!roundEnded)
                                        _StatusChip(
                                          text: game.isCareerFullyRevealed
                                              ? '+1 available'
                                              : 'Revealing...',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _RoundInfoBlock(
                                    game: game,
                                    playerName: player.name,
                                    roundEnded: roundEnded,
                                    localRoundLocked: _localRoundLocked,
                                  ),
                                  if (_wrongBoxMessage != null) ...[
                                    const SizedBox(height: 12),
                                    _WrongAnswerBox(
                                      message: _wrongBoxMessage!,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  CareerTimeline(clubs: visibleClubs),
                                  const SizedBox(height: 14),
                                  if (!roundEnded && game.hintsEnabled) ...[
                                    _HintBox(game: game),
                                    const SizedBox(height: 14),
                                  ],
                                  _SoloAnswerSearchBox(
                                    controller: _controller,
                                    enabled: inputEnabled,
                                    answerOptions: _answerOptions,
                                    wrongAttempts: _wrongAttemptsThisRound,
                                    maxWrongAttempts: _maxWrongAttempts,
                                    onSubmit: () => _submitGuess(game),
                                    onSelected: (value) {
                                      _controller.text = value;
                                      _controller.selection =
                                          TextSelection.collapsed(
                                        offset: value.length,
                                      );

                                      _submitGuess(game);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: inputEnabled
                                              ? () => _submitGuess(game)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.pitchGreen,
                                            foregroundColor:
                                                const Color(0xFF02100A),
                                            disabledBackgroundColor:
                                                AppTheme.border,
                                            disabledForegroundColor:
                                                AppTheme.subText,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: const Text(
                                            'Submit Guess',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _goNextRound(game),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.text,
                                            side: BorderSide(
                                              color: AppTheme.stadiumBlue
                                                  .withOpacity(0.38),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 13,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: Text(
                                            roundEnded || _localRoundLocked
                                                ? game.currentRound >=
                                                        GameRules.totalRounds
                                                    ? 'See Results'
                                                    : 'Next Round'
                                                : 'Skip',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (game.feedbackMessage != null &&
                                      game.lastGuessWasCorrect == true) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.pitchGreen
                                            .withOpacity(0.13),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppTheme.pitchGreen
                                              .withOpacity(0.38),
                                        ),
                                      ),
                                      child: Text(
                                        game.feedbackMessage!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.pitchGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SoloAnswerSearchBox extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final List<String> answerOptions;
  final int wrongAttempts;
  final int maxWrongAttempts;
  final VoidCallback onSubmit;
  final ValueChanged<String> onSelected;

  const _SoloAnswerSearchBox({
    required this.controller,
    required this.enabled,
    required this.answerOptions,
    required this.wrongAttempts,
    required this.maxWrongAttempts,
    required this.onSubmit,
    required this.onSelected,
  });

  @override
  State<_SoloAnswerSearchBox> createState() => _SoloAnswerSearchBoxState();
}

class _SoloAnswerSearchBoxState extends State<_SoloAnswerSearchBox> {
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_updateSuggestions);
    _focusNode.addListener(_updateSuggestions);
  }

  @override
  void didUpdateWidget(covariant _SoloAnswerSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateSuggestions);
      widget.controller.addListener(_updateSuggestions);
    }

    if (oldWidget.answerOptions != widget.answerOptions ||
        oldWidget.enabled != widget.enabled) {
      _updateSuggestions();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSuggestions);
    _focusNode.removeListener(_updateSuggestions);
    _focusNode.dispose();
    super.dispose();
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

  void _updateSuggestions() {
    if (!mounted) return;

    if (!_focusNode.hasFocus || !widget.enabled) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }

    final query = _normalizeSearchText(widget.controller.text);

    if (query.length < 2) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
        });
      }
      return;
    }

    final startsWithMatches = <String>[];
    final containsMatches = <String>[];
    final seen = <String>{};

    for (final option in widget.answerOptions) {
      final normalizedOption = _normalizeSearchText(option);

      if (seen.contains(normalizedOption)) continue;
      seen.add(normalizedOption);

      if (normalizedOption.startsWith(query)) {
        startsWithMatches.add(option);
      } else if (normalizedOption.contains(query)) {
        containsMatches.add(option);
      }
    }

    final next = <String>[
      ...startsWithMatches,
      ...containsMatches,
    ].take(7).toList();

    if (_sameList(_suggestions, next)) return;

    setState(() {
      _suggestions = next;
    });
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  Future<void> _selectSuggestion(String value) async {
    if (!widget.enabled) return;

    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(offset: value.length);

    if (mounted) {
      setState(() {
        _suggestions = [];
      });
    }

    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    widget.onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    final attemptsLeft = (widget.maxWrongAttempts - widget.wrongAttempts).clamp(
      0,
      widget.maxWrongAttempts,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF02101F).withOpacity(0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.enabled
              ? AppTheme.pitchGreen.withOpacity(0.45)
              : AppTheme.border.withOpacity(0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_suggestions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 190),
              decoration: BoxDecoration(
                color: const Color(0xFF061B30).withOpacity(0.98),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.stadiumBlue.withOpacity(0.38),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: AppTheme.stadiumBlue.withOpacity(0.18),
                ),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppTheme.gold,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  color: AppTheme.text,
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.touch_app_rounded,
                              color: AppTheme.subText,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            onSubmitted: (_) => widget.onSubmit(),
            style: const TextStyle(
              color: AppTheme.text,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: widget.enabled
                  ? 'Search player name...'
                  : attemptsLeft <= 0
                      ? 'No attempts left...'
                      : 'Round ended...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: widget.controller.text.trim().isEmpty
                  ? IconButton(
                      onPressed: widget.enabled ? widget.onSubmit : null,
                      icon: const Icon(Icons.send_rounded),
                    )
                  : IconButton(
                      onPressed: !widget.enabled
                          ? null
                          : () {
                              widget.controller.clear();
                              _updateSuggestions();
                            },
                      icon: const Icon(Icons.close_rounded),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AttemptMiniBox(
                  label: 'Wrong',
                  value: '${widget.wrongAttempts}/${widget.maxWrongAttempts}',
                  color: attemptsLeft <= 1 ? Colors.redAccent : AppTheme.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttemptMiniBox(
                  label: 'Left',
                  value: '$attemptsLeft',
                  color: attemptsLeft <= 1
                      ? Colors.redAccent
                      : AppTheme.pitchGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WrongAnswerBox extends StatelessWidget {
  final String message;

  const _WrongAnswerBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.close_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFB3B3),
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttemptMiniBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.subText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundInfoBlock extends StatelessWidget {
  final GameProvider game;
  final String playerName;
  final bool roundEnded;
  final bool localRoundLocked;

  const _RoundInfoBlock({
    required this.game,
    required this.playerName,
    required this.roundEnded,
    required this.localRoundLocked,
  });

  @override
  Widget build(BuildContext context) {
    final retired = game.isCurrentPlayerRetired;

    String message;

    if (roundEnded) {
      message = 'Answer: $playerName';
    } else if (localRoundLocked) {
      message = 'No attempts left.\nPress Next Round to continue.';
    } else if (game.isCareerFullyRevealed) {
      message = 'Full career revealed.\nCorrect guess now gives 1 point.';
    } else {
      message = 'A new club appears every ${GameRules.revealSeconds} seconds.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 12.2,
            color: AppTheme.subText,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: retired
                ? AppTheme.gold.withOpacity(0.12)
                : AppTheme.pitchGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: retired
                  ? AppTheme.gold.withOpacity(0.35)
                  : AppTheme.pitchGreen.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                retired ? Icons.history_rounded : Icons.flash_on_rounded,
                color: retired ? AppTheme.gold : AppTheme.pitchGreen,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                game.currentPlayerStatusText,
                style: TextStyle(
                  color: retired ? AppTheme.gold : AppTheme.pitchGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HintBox extends StatelessWidget {
  final GameProvider game;

  const _HintBox({
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final hintsUsed = game.usedHints;

    String penaltyText;
    if (hintsUsed == 0) {
      penaltyText = 'No hints used — normal points available';
    } else if (hintsUsed >= 3) {
      penaltyText = 'Hints used: $hintsUsed — correct answer gives 0 points';
    } else {
      penaltyText = 'Hints used: $hintsUsed — correct answer gives 0.5 point';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: game.canUseHint ? game.useHint : null,
                icon: const Icon(Icons.lightbulb_rounded, size: 18),
                label: Text(
                  hintsUsed == 0 ? 'Use Hint' : 'Use Another Hint',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  disabledForegroundColor: AppTheme.subText,
                  side: BorderSide(
                    color: AppTheme.gold.withOpacity(0.42),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (game.revealedHints.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.gold.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  penaltyText,
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...game.revealedHints.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          'Hint ${entry.key + 1}: ${entry.value}',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FinalResultView extends StatelessWidget {
  final GameProvider game;

  const _FinalResultView({
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final missedRounds = game.missedRounds;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Image.asset(
                      'assets/images/career_guess_logo.png',
                      height: 68,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Career Guess',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 52),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF02101F).withOpacity(0.72),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppTheme.gold.withOpacity(0.45),
                            width: 1.3,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppTheme.gold,
                              size: 52,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Final Results',
                              style: TextStyle(
                                color: AppTheme.text,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rank: ${game.finalRank}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _ResultStatCard(
                                  label: 'Score',
                                  value:
                                      '${game.formattedScore}/${game.formattedMaxScore}',
                                  icon: Icons.stars_rounded,
                                  color: AppTheme.gold,
                                ),
                                const SizedBox(width: 10),
                                _ResultStatCard(
                                  label: 'Accuracy',
                                  value: '${game.finalAccuracyPercent}%',
                                  icon: Icons.track_changes_rounded,
                                  color: AppTheme.pitchGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ResultStatCard(
                                  label: 'Correct',
                                  value: '${game.correctAnswers}',
                                  icon: Icons.check_circle_rounded,
                                  color: AppTheme.pitchGreen,
                                ),
                                const SizedBox(width: 10),
                                _ResultStatCard(
                                  label: 'Skipped',
                                  value: '${game.skippedRounds}',
                                  icon: Icons.skip_next_rounded,
                                  color: AppTheme.accent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _MissedPlayersPanel(missedRounds: missedRounds),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<GameProvider>().startNewGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pitchGreen,
                            foregroundColor: const Color(0xFF02100A),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.text,
                            side: BorderSide(
                              color: AppTheme.stadiumBlue.withOpacity(0.42),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Back Home',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissedPlayersPanel extends StatelessWidget {
  final List<RoundReview> missedRounds;

  const _MissedPlayersPanel({
    required this.missedRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF02101F).withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: missedRounds.isEmpty
              ? AppTheme.pitchGreen.withOpacity(0.35)
              : Colors.red.withOpacity(0.28),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: missedRounds.isNotEmpty,
        iconColor: AppTheme.text,
        collapsedIconColor: AppTheme.text,
        title: Text(
          missedRounds.isEmpty
              ? 'No missed players'
              : 'Players you missed (${missedRounds.length})',
          style: const TextStyle(
            color: AppTheme.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          missedRounds.isEmpty
              ? 'Perfect — you knew every player.'
              : 'Open this to review the names and careers.',
          style: const TextStyle(
            color: AppTheme.subText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          if (missedRounds.isEmpty)
            const Text(
              'Great job. You did not skip any player.',
              style: TextStyle(
                color: AppTheme.pitchGreen,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...missedRounds.asMap().entries.map(
                  (entry) => _MissedPlayerCard(
                    index: entry.key + 1,
                    review: entry.value,
                  ),
                ),
        ],
      ),
    );
  }
}

class _MissedPlayerCard extends StatelessWidget {
  final int index;
  final RoundReview review;

  const _MissedPlayerCard({
    required this.index,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final clubPath = review.clubNames.join(' → ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${review.playerName}',
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _SmallReviewChip(
                text: review.statusLabel,
                icon: review.statusLabel == 'Retired player'
                    ? Icons.history_rounded
                    : Icons.flash_on_rounded,
              ),
              _SmallReviewChip(
                text: review.nationality.isEmpty
                    ? 'Nationality unknown'
                    : review.nationality,
                icon: Icons.flag_rounded,
              ),
              _SmallReviewChip(
                text: GameProvider.difficultyLabel(review.difficulty),
                icon: Icons.speed_rounded,
              ),
              _SmallReviewChip(
                text: review.wasSkipped ? 'Skipped' : 'Missed',
                icon: Icons.close_rounded,
              ),
              if (review.hintsUsed > 0)
                _SmallReviewChip(
                  text: '${review.hintsUsed} hints used',
                  icon: Icons.lightbulb_rounded,
                ),
            ],
          ),
          if (clubPath.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              clubPath,
              style: const TextStyle(
                color: AppTheme.subText,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallReviewChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SmallReviewChip({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.stadiumBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accent, size: 13),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResultStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.subText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _TopInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF02101F).withOpacity(0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.stadiumBlue.withOpacity(0.42),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: valueColor, size: 18),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF02101F).withOpacity(0.72),
      shape: CircleBorder(
        side: BorderSide(
          color: AppTheme.stadiumBlue.withOpacity(0.42),
          width: 1.1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppTheme.text, size: 24),
        ),
      ),
    );
  }
}

class _GlowingTargetIcon extends StatelessWidget {
  const _GlowingTargetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.pitchGreen.withOpacity(0.14),
        border: Border.all(
          color: AppTheme.pitchGreen.withOpacity(0.58),
          width: 1.2,
        ),
      ),
      child: const Icon(
        Icons.track_changes_rounded,
        color: AppTheme.pitchGreen,
        size: 22,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.pitchGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.pitchGreen.withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.pitchGreen,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
