import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/private_match_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/career_timeline.dart';
import '../widgets/pitch_background.dart';

class PrivateMatchGameScreen extends StatefulWidget {
  static const String routeName = '/private-match-game';

  const PrivateMatchGameScreen({super.key});

  @override
  State<PrivateMatchGameScreen> createState() => _PrivateMatchGameScreenState();
}

class _PrivateMatchGameScreenState extends State<PrivateMatchGameScreen> {
  final TextEditingController _guessController = TextEditingController();

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _submitGuess(PrivateMatchProvider match) async {
    final text = _guessController.text.trim();
    if (text.isEmpty) return;

    await match.submitGuess(text);
    _guessController.clear();
  }

  Future<void> _copyRoomCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code $code copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatPlayerStatus(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized == 'active' || normalized == 'current') {
      return 'Active';
    }

    if (normalized == 'retired') {
      return 'Retired';
    }

    if (status.trim().isEmpty) {
      return 'Unknown';
    }

    return status.trim();
  }

  IconData _statusIcon(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized == 'active' || normalized == 'current') {
      return Icons.flash_on_rounded;
    }

    if (normalized == 'retired') {
      return Icons.history_rounded;
    }

    return Icons.info_outline_rounded;
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toLowerCase();

    if (normalized == 'active' || normalized == 'current') {
      return AppTheme.pitchGreen;
    }

    if (normalized == 'retired') {
      return AppTheme.gold;
    }

    return AppTheme.subText;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PitchBackground(
        child: SafeArea(
          child: Consumer<PrivateMatchProvider>(
            builder: (context, match, _) {
              if (match.roomCode == null) {
                return _MessageView(
                  title: 'No room found',
                  message: 'Go back and create or join a room.',
                  buttonText: 'Back',
                  onPressed: () => Navigator.pop(context),
                );
              }

              if (match.isWaitingForFriend) {
                return _WaitingRoomView(
                  roomCode: match.roomCode!,
                  difficulty: match.difficulty,
                  unlimitedTime: match.isUnlimitedTime,
                  onCopy: () => _copyRoomCode(match.roomCode!),
                  onBack: () async {
                    await match.leaveRoom();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                );
              }

              if (match.gameFinished ||
                  match.room?['status']?.toString() == 'finished') {
                return _PrivateResultView(match: match);
              }

              final player = match.currentPlayer;

              if (player == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    child: Column(
                      children: [
                        _AutoRoundAdvancer(match: match),
                        Row(
                          children: [
                            _CircleIconButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () async {
                                await match.leaveRoom();

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Private Match',
                                    style: TextStyle(
                                      color: AppTheme.text,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'Room: ${match.roomCode}',
                                    style: const TextStyle(
                                      color: AppTheme.subText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _CircleIconButton(
                              icon: Icons.copy_rounded,
                              onTap: () => _copyRoomCode(match.roomCode!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ScoreCard(
                              label: match.me?.displayName ?? 'You',
                              score: match.myFormattedScore,
                              icon: Icons.person_rounded,
                              color: AppTheme.pitchGreen,
                            ),
                            const SizedBox(width: 10),
                            _ScoreCard(
                              label: match.opponent?.displayName ?? 'Friend',
                              score: match.opponentFormattedScore,
                              icon: Icons.group_rounded,
                              color: AppTheme.gold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _RoundHeader(match: match),
                        const SizedBox(height: 10),
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
                            ),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Guess the Player',
                                          style: TextStyle(
                                            color: AppTheme.text,
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      _SmallChip(
                                        text:
                                            _formatPlayerStatus(player.status),
                                        icon: _statusIcon(player.status),
                                        color: _statusColor(player.status),
                                      ),
                                      const SizedBox(width: 8),
                                      _SmallChip(
                                        text: match.revealedHintCount == 0
                                            ? 'No hints used'
                                            : '${match.revealedHintCount} hints',
                                        icon: Icons.lightbulb_rounded,
                                        color: match.revealedHintCount == 0
                                            ? AppTheme.pitchGreen
                                            : AppTheme.gold,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _RoundMessage(match: match),
                                  if (match.roundEnded) ...[
                                    const SizedBox(height: 12),
                                    _AnswerRevealBox(match: match),
                                  ],
                                  const SizedBox(height: 14),
                                  _HintPanel(match: match),
                                  const SizedBox(height: 14),
                                  _AutoCareerTimeline(match: match),
                                  const SizedBox(height: 14),
                                  if (match.feedbackMessage != null) ...[
                                    _FeedbackBox(match: match),
                                    const SizedBox(height: 14),
                                  ],
                                  _RoundStatusBox(match: match),
                                  if (match.roundEnded) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Next round will start automatically...',
                                      style: TextStyle(
                                        color: AppTheme.subText,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AnswerSearchInput(
                          match: match,
                          controller: _guessController,
                          onSubmit: () => _submitGuess(match),
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

class _AutoRoundAdvancer extends StatefulWidget {
  final PrivateMatchProvider match;

  const _AutoRoundAdvancer({
    required this.match,
  });

  @override
  State<_AutoRoundAdvancer> createState() => _AutoRoundAdvancerState();
}

class _AutoRoundAdvancerState extends State<_AutoRoundAdvancer> {
  Timer? _timer;
  int? _lastTriggeredRound;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _check(),
    );
  }

  @override
  void didUpdateWidget(covariant _AutoRoundAdvancer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.match.currentRound != widget.match.currentRound) {
      _lastTriggeredRound = null;
    }

    _check();
  }

  void _check() {
    final match = widget.match;

    if (!match.isHost) return;
    if (!match.roundEnded) return;
    if (_lastTriggeredRound == match.currentRound) return;

    _lastTriggeredRound = match.currentRound;
    match.autoAdvanceRoundIfHost();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _AutoCareerTimeline extends StatefulWidget {
  final PrivateMatchProvider match;

  const _AutoCareerTimeline({
    required this.match,
  });

  @override
  State<_AutoCareerTimeline> createState() => _AutoCareerTimelineState();
}

class _AutoCareerTimelineState extends State<_AutoCareerTimeline> {
  Timer? _timer;
  int _visibleCount = 1;
  String? _playerId;

  @override
  void initState() {
    super.initState();

    _syncNow();

    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _syncNow();
      },
    );
  }

  @override
  void didUpdateWidget(covariant _AutoCareerTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentId = widget.match.currentPlayer?.id;

    if (_playerId != currentId) {
      _playerId = currentId;
      _visibleCount = 1;
      _syncNow();
    }
  }

  void _syncNow() {
    final player = widget.match.currentPlayer;
    if (player == null) return;

    final nextVisibleCount = widget.match.revealedClubCountAt(DateTime.now());

    if (nextVisibleCount == _visibleCount && _playerId == player.id) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _playerId = player.id;
      _visibleCount = nextVisibleCount;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.match.currentPlayer;
    if (player == null) return const SizedBox.shrink();

    final safeVisibleCount = _visibleCount.clamp(1, player.clubs.length);
    final visibleClubs = player.clubs.take(safeVisibleCount).toList();

    return RepaintBoundary(
      child: CareerTimeline(
        key: ValueKey('${player.id}_$safeVisibleCount'),
        clubs: visibleClubs,
      ),
    );
  }
}

class _AnswerRevealBox extends StatelessWidget {
  final PrivateMatchProvider match;

  const _AnswerRevealBox({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final player = match.currentPlayer;
    final name = player?.name ?? 'the player';

    String title = 'Correct Answer';

    if (match.roundEndReason == 'time') {
      title = 'Time is Up';
    } else if (match.roundEndReason == 'attempts_or_correct') {
      title = 'Round Finished';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            match.roundEndReason == 'correct'
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: AppTheme.gold,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Next round starting...',
            style: TextStyle(
              color: AppTheme.subText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final PrivateMatchProvider match;

  const _RoundHeader({
    required this.match,
  });

  String _formatTime(int? seconds) {
    if (seconds == null) return 'Unlimited';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return _TimerHeader(
      match: match,
      formatTime: _formatTime,
    );
  }
}

class _TimerHeader extends StatefulWidget {
  final PrivateMatchProvider match;
  final String Function(int?) formatTime;

  const _TimerHeader({
    required this.match,
    required this.formatTime,
  });

  @override
  State<_TimerHeader> createState() => _TimerHeaderState();
}

class _TimerHeaderState extends State<_TimerHeader> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.match.timeRemainingAt(DateTime.now());

    final timeColor = remaining != null && remaining <= 10
        ? Colors.redAccent
        : AppTheme.pitchGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF02101F).withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_soccer_rounded,
            color: AppTheme.accent,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Round ${widget.match.currentRound}/${widget.match.totalRounds}',
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _SmallChip(
            text: widget.formatTime(remaining),
            icon: Icons.timer_rounded,
            color: timeColor,
          ),
        ],
      ),
    );
  }
}

class _RoundMessage extends StatefulWidget {
  final PrivateMatchProvider match;

  const _RoundMessage({
    required this.match,
  });

  @override
  State<_RoundMessage> createState() => _RoundMessageState();
}

class _RoundMessageState extends State<_RoundMessage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.match.currentPlayer;

    String message;

    if (widget.match.roundEnded) {
      if (widget.match.roundEndReason == 'correct') {
        message =
            'Someone guessed correctly. The player was ${player?.name ?? 'the player'}.';
      } else if (widget.match.isTimeUpAt(DateTime.now())) {
        message = 'Time is up. The player was ${player?.name ?? 'the player'}.';
      } else if (widget.match.areAllPlayersDoneForRound) {
        message =
            'Round finished. The player was ${player?.name ?? 'the player'}.';
      } else {
        message =
            'Round ended. The player was ${player?.name ?? 'the player'}.';
      }
    } else if (widget.match.hasCorrectGuessThisRound) {
      message = 'You guessed correctly. Waiting for the next round.';
    } else if (widget.match.myWrongAttempts >=
        PrivateMatchProvider.maxWrongAttempts) {
      message =
          'You used all 3 wrong attempts. Waiting for your friend to finish.';
    } else if (widget.match.isCareerFullyRevealed) {
      message = 'Full career revealed. Correct guess now gives 1 point.';
    } else {
      message = 'A new club appears every 3 seconds.';
    }

    return Text(
      message,
      style: const TextStyle(
        color: AppTheme.subText,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class _AnswerSearchInput extends StatefulWidget {
  final PrivateMatchProvider match;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _AnswerSearchInput({
    required this.match,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<_AnswerSearchInput> createState() => _AnswerSearchInputState();
}

class _AnswerSearchInputState extends State<_AnswerSearchInput> {
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_updateSuggestions);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _AnswerSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateSuggestions);
      widget.controller.addListener(_updateSuggestions);
    }

    if (oldWidget.match.currentRound != widget.match.currentRound) {
      _clearSuggestions();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSuggestions);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isSelectingSuggestion) return;
    _updateSuggestions();
  }

  void _clearSuggestions() {
    if (!mounted) return;
    if (_suggestions.isEmpty) return;

    setState(() {
      _suggestions = [];
    });
  }

  void _updateSuggestions() {
    if (!mounted) return;
    if (_isSelectingSuggestion) return;

    if (!_focusNode.hasFocus || !widget.match.canSubmitGuess) {
      _clearSuggestions();
      return;
    }

    final query = widget.controller.text.trim();

    if (query.length < 2) {
      _clearSuggestions();
      return;
    }

    final next = widget.match.searchAnswerSuggestions(
      query,
      limit: 7,
    );

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

  void _selectSuggestionImmediately(String value) {
    if (!widget.match.canSubmitGuess) return;
    if (_isSelectingSuggestion) return;

    _isSelectingSuggestion = true;

    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(
      offset: value.length,
    );

    if (mounted) {
      setState(() {
        _suggestions = [];
      });
    }

    FocusScope.of(context).unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onSubmit();

      _isSelectingSuggestion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.match.canSubmitGuess;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF02101F).withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: canSubmit
              ? AppTheme.pitchGreen.withOpacity(0.55)
              : AppTheme.border.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        _selectSuggestionImmediately(suggestion);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: canSubmit,
                  onSubmitted: (_) => widget.onSubmit(),
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: canSubmit
                        ? 'Search player name...'
                        : widget.match.roundEnded
                            ? 'Round ended...'
                            : 'You can no longer guess...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: widget.controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: !canSubmit
                                ? null
                                : () {
                                    widget.controller.clear();
                                    _updateSuggestions();
                                  },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 54,
                width: 54,
                child: ElevatedButton(
                  onPressed: canSubmit ? widget.onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pitchGreen,
                    foregroundColor: const Color(0xFF02100A),
                    disabledBackgroundColor: AppTheme.border,
                    disabledForegroundColor: AppTheme.subText,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallInfoBox(
                  label: 'Wrong',
                  value:
                      '${widget.match.myWrongAttempts}/${PrivateMatchProvider.maxWrongAttempts}',
                  color: widget.match.attemptsLeft <= 1
                      ? Colors.redAccent
                      : AppTheme.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallInfoBox(
                  label: 'Left',
                  value: '${widget.match.attemptsLeft}',
                  color: widget.match.attemptsLeft <= 1
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

class _HintPanel extends StatelessWidget {
  final PrivateMatchProvider match;

  const _HintPanel({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    String penaltyText;

    if (match.revealedHintCount == 0) {
      penaltyText = 'No hints used — normal points available.';
    } else if (match.revealedHintCount >= 3) {
      penaltyText = '3+ hints used — correct guess gives 0 points.';
    } else {
      penaltyText = 'Hints used — correct guess gives 0.5 point.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.gold.withOpacity(0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared Hints',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            penaltyText,
            style: const TextStyle(
              color: AppTheme.subText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (match.revealedHints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...match.revealedHints.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Hint ${entry.key + 1}: ${entry.value}',
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          if (match.didIRequestHint)
            const Text(
              'Hint requested.\nWaiting for your friend to accept.',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            )
          else if (match.canAcceptHint)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: match.acceptHint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pitchGreen,
                      foregroundColor: const Color(0xFF02100A),
                    ),
                    child: const Text(
                      'Accept Hint',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: match.declineHint,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: match.canRequestHint ? match.requestHint : null,
                icon: const Icon(Icons.lightbulb_rounded),
                label: const Text(
                  'Request Hint',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  disabledForegroundColor: AppTheme.subText,
                  side: BorderSide(
                    color: AppTheme.gold.withOpacity(0.35),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundStatusBox extends StatefulWidget {
  final PrivateMatchProvider match;

  const _RoundStatusBox({
    required this.match,
  });

  @override
  State<_RoundStatusBox> createState() => _RoundStatusBoxState();
}

class _RoundStatusBoxState extends State<_RoundStatusBox> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _playerStatus(PrivateMatchPlayer player) {
    final isMe = player.userId == widget.match.userId;
    final name = isMe ? 'You' : player.displayName;

    if (widget.match.hasCorrectGuessForUser(player.userId)) {
      return '$name: correct';
    }

    final wrong = widget.match.wrongAttemptsForUser(player.userId);

    if (wrong >= PrivateMatchProvider.maxWrongAttempts) {
      return '$name: failed 3 attempts';
    }

    return '$name: $wrong/3 wrong attempts';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final player = match.currentPlayer;

    String text;

    if (match.roundEnded) {
      if (match.roundEndReason == 'correct') {
        text = 'Correct answer: ${player?.name ?? 'the player'}.';
      } else if (match.isTimeUpAt(DateTime.now())) {
        text = 'Time is up. The answer was ${player?.name ?? 'the player'}.';
      } else {
        text = 'Answer: ${player?.name ?? 'the player'}.';
      }
    } else {
      final statuses = match.roomPlayers.map(_playerStatus).join('\n');
      text = statuses.isEmpty ? 'Waiting for players...' : statuses;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.stadiumBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.stadiumBlue.withOpacity(0.25),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          height: 1.35,
        ),
      ),
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final PrivateMatchProvider match;

  const _FeedbackBox({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final correct = match.lastGuessWasCorrect == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: correct
            ? AppTheme.pitchGreen.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: correct
              ? AppTheme.pitchGreen.withOpacity(0.35)
              : Colors.red.withOpacity(0.35),
        ),
      ),
      child: Text(
        match.feedbackMessage ?? '',
        style: TextStyle(
          color: correct ? AppTheme.pitchGreen : const Color(0xFFFFB3B3),
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WaitingRoomView extends StatelessWidget {
  final String roomCode;
  final String difficulty;
  final bool unlimitedTime;
  final VoidCallback onCopy;
  final VoidCallback onBack;

  const _WaitingRoomView({
    required this.roomCode,
    required this.difficulty,
    required this.unlimitedTime,
    required this.onCopy,
    required this.onBack,
  });

  String get difficultyLabel {
    if (difficulty == 'amateur') return 'Amateur';
    if (difficulty == 'pro') return 'Pro';
    if (difficulty == 'legend') return 'Legend';
    if (difficulty == 'expert') return 'Expert';

    return 'Random';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF02101F).withOpacity(0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.gold.withOpacity(0.42),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.group_add_rounded,
                  color: AppTheme.gold,
                  size: 54,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Waiting for Friend',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send this room code to your friend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.subText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    roomCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _SmallChip(
                      text: difficultyLabel,
                      icon: Icons.speed_rounded,
                      color: AppTheme.accent,
                    ),
                    _SmallChip(
                      text: unlimitedTime ? 'Unlimited' : '90 seconds',
                      icon: Icons.timer_rounded,
                      color: AppTheme.pitchGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pitchGreen,
                      foregroundColor: const Color(0xFF02100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onBack,
                  child: const Text('Leave Room'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivateResultView extends StatelessWidget {
  final PrivateMatchProvider match;

  const _PrivateResultView({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final me = match.me;
    final opponent = match.opponent;

    String title = 'Match Finished';

    if (me != null && opponent != null) {
      if (me.score > opponent.score) {
        title = 'You Won!';
      } else if (me.score < opponent.score) {
        title = 'You Lost';
      } else {
        title = 'Draw';
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF02101F).withOpacity(0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.gold.withOpacity(0.42),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.gold,
                  size: 56,
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                _ResultPlayerRow(
                  name: me?.displayName ?? 'You',
                  score: me?.formattedScore ?? '0',
                  label: 'You',
                  color: AppTheme.pitchGreen,
                ),
                const SizedBox(height: 10),
                _ResultPlayerRow(
                  name: opponent?.displayName ?? 'Friend',
                  score: opponent?.formattedScore ?? '0',
                  label: 'Friend',
                  color: AppTheme.gold,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await match.leaveRoom();

                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pitchGreen,
                      foregroundColor: const Color(0xFF02100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Back Home',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SmallInfoBox({
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

class _ScoreCard extends StatelessWidget {
  final String label;
  final String score;
  final IconData icon;
  final Color color;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF02101F).withOpacity(0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              score,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPlayerRow extends StatelessWidget {
  final String name;
  final String score;
  final String label;
  final Color color;

  const _ResultPlayerRow({
    required this.name,
    required this.score,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            score,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SmallChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          child: Icon(
            icon,
            color: AppTheme.text,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _MessageView({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF02101F).withOpacity(0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.stadiumBlue.withOpacity(0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.subText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pitchGreen,
                      foregroundColor: const Color(0xFF02100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
