import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitGuess(GameProvider game) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    game.submitGuess(text);
    _controller.clear();
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

              final visibleClubs =
                  player.clubs.take(game.revealedClubCount).toList();

              final roundEnded = game.roundEnded;

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
                              onTap: () {
                                _controller.clear();
                                context.read<GameProvider>().startNewGame();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _TopInfoCard(
                              label: 'Score',
                              value: '${game.score}',
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
                                  Text(
                                    roundEnded
                                        ? 'Answer: ${player.name}'
                                        : game.isCareerFullyRevealed
                                            ? 'Full career revealed. Correct guess now gives 1 point.'
                                            : 'A new club appears every ${GameRules.revealSeconds} seconds.',
                                    style: const TextStyle(
                                      fontSize: 12.2,
                                      color: AppTheme.subText,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // This now wraps into new lines.
                                  CareerTimeline(clubs: visibleClubs),

                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _controller,
                                    enabled: !roundEnded,
                                    onSubmitted: (_) => _submitGuess(game),
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Type player name...',
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: roundEnded
                                            ? null
                                            : () => _submitGuess(game),
                                        icon: const Icon(
                                          Icons.send_rounded,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: roundEnded
                                              ? null
                                              : () => _submitGuess(game),
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
                                          onPressed: () {
                                            _controller.clear();
                                            game.nextRound();
                                          },
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
                                            roundEnded ? 'Next Round' : 'Skip',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (game.feedbackMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: game.lastGuessWasCorrect == true
                                            ? AppTheme.pitchGreen
                                                .withOpacity(0.13)
                                            : Colors.red.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: game.lastGuessWasCorrect ==
                                                  true
                                              ? AppTheme.pitchGreen
                                                  .withOpacity(0.38)
                                              : Colors.red.withOpacity(0.35),
                                        ),
                                      ),
                                      child: Text(
                                        game.feedbackMessage!,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color:
                                              game.lastGuessWasCorrect == true
                                                  ? AppTheme.pitchGreen
                                                  : const Color(0xFFFFB3B3),
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

class _TopInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _TopInfoCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
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
            Icon(
              icon,
              color: valueColor,
              size: 18,
            ),
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.pitchGreen.withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
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
