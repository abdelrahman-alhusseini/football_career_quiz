import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/pitch_background.dart';
import 'solo_game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  static const String routeName = '/difficulty';

  const DifficultyScreen({super.key});

  static const Color premiumGold = Color(0xFFD9A441);
  static const Color softGold = Color(0xFFFFD36A);
  static const Color deepGold = Color(0xFF8F641D);
  static const Color premiumBlue = Color(0xFF2D8CFF);
  static const Color cardBlack = Color(0xEE050910);
  static const Color cardDark = Color(0xEE08111D);
  static const Color silverText = Color(0xFFF1F4FA);
  static const Color mutedSilver = Color(0xFFB8C2D1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.10),
                Colors.black.withOpacity(0.38),
                Colors.black.withOpacity(0.74),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CircleBackButton(
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Choose Mode',
                              style: TextStyle(
                                color: silverText,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 14,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pick your challenge. Random includes all players from every category.',
                        style: TextStyle(
                          color: mutedSilver,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: const [
                            _DifficultyCard(
                              title: 'Amateur',
                              value: 'amateur',
                              icon: Icons.sports_soccer_rounded,
                              description:
                                  'Very famous players most casual football fans know.',
                              examples:
                                  'Messi, Ronaldo, Neymar, Salah, Haaland',
                            ),
                            SizedBox(height: 14),
                            _DifficultyCard(
                              title: 'Pro',
                              value: 'pro',
                              icon: Icons.local_fire_department_rounded,
                              description:
                                  'Known players for regular football fans.',
                              examples:
                                  'Sterling, Dybala, João Félix, Brahim Díaz',
                            ),
                            SizedBox(height: 14),
                            _DifficultyCard(
                              title: 'Legend',
                              value: 'legend',
                              icon: Icons.military_tech_rounded,
                              description:
                                  'Older stars, retired icons, and harder famous careers.',
                              examples:
                                  'Legends, cult heroes, tricky transfer paths',
                            ),
                            SizedBox(height: 14),
                            _DifficultyCard(
                              title: 'Expert',
                              value: 'expert',
                              icon: Icons.psychology_rounded,
                              description:
                                  'Very hard players, journeymen, loans, and deep-ball knowledge.',
                              examples:
                                  'Mid-table players, reserves, obscure paths',
                            ),
                            SizedBox(height: 14),
                            _DifficultyCard(
                              title: 'Random',
                              value: 'random',
                              icon: Icons.shuffle_rounded,
                              description:
                                  'Anything can appear. Uses all 3000 players when the database is complete.',
                              examples: 'All categories mixed together',
                              isRandom: true,
                            ),
                            SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String description;
  final String examples;
  final bool isRandom;

  const _DifficultyCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
    required this.examples,
    this.isRandom = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainAccent =
        isRandom ? DifficultyScreen.softGold : DifficultyScreen.premiumGold;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        splashColor: mainAccent.withOpacity(0.10),
        highlightColor: mainAccent.withOpacity(0.06),
        onTap: () {
          context.read<GameProvider>().setDifficulty(value);
          Navigator.pushNamed(context, SoloGameScreen.routeName);
        },
        child: Container(
          padding: const EdgeInsets.all(1.25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DifficultyScreen.softGold.withOpacity(isRandom ? 0.95 : 0.70),
                DifficultyScreen.premiumBlue.withOpacity(0.25),
                DifficultyScreen.deepGold.withOpacity(0.72),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.42),
                blurRadius: 26,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: mainAccent.withOpacity(isRandom ? 0.18 : 0.12),
                blurRadius: 22,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DifficultyScreen.cardDark,
                  DifficultyScreen.cardBlack,
                  Color(0xF0040710),
                ],
              ),
              border: Border.all(
                color: Colors.white10,
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                _PremiumIconBadge(
                  icon: icon,
                  isRandom: isRandom,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isRandom
                                ? const [
                                    DifficultyScreen.softGold,
                                    Color(0xFFFFFFFF),
                                    DifficultyScreen.premiumGold,
                                  ]
                                : const [
                                    DifficultyScreen.silverText,
                                    Color(0xFFFFFFFF),
                                    DifficultyScreen.premiumGold,
                                  ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.15,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        style: const TextStyle(
                          color: DifficultyScreen.mutedSilver,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        examples,
                        style: TextStyle(
                          color: mainAccent,
                          fontSize: 11.4,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                          shadows: [
                            Shadow(
                              color: mainAccent.withOpacity(0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mainAccent.withOpacity(0.10),
                    border: Border.all(
                      color: mainAccent.withOpacity(0.40),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: mainAccent.withOpacity(0.14),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: mainAccent,
                    size: 14,
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

class _PremiumIconBadge extends StatelessWidget {
  final IconData icon;
  final bool isRandom;

  const _PremiumIconBadge({
    required this.icon,
    required this.isRandom,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isRandom ? DifficultyScreen.softGold : DifficultyScreen.premiumGold;

    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            accent.withOpacity(0.20),
            DifficultyScreen.premiumBlue.withOpacity(0.40),
            accent.withOpacity(0.92),
            accent.withOpacity(0.20),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF07101B).withOpacity(0.94),
          border: Border.all(
            color: accent.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: accent,
          size: 29,
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CircleBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: DifficultyScreen.premiumGold.withOpacity(0.12),
        highlightColor: DifficultyScreen.premiumGold.withOpacity(0.06),
        onTap: onTap,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1624),
                Color(0xFF02060C),
              ],
            ),
            border: Border.all(
              color: DifficultyScreen.premiumGold.withOpacity(0.62),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: DifficultyScreen.premiumGold.withOpacity(0.13),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: DifficultyScreen.softGold,
            size: 24,
          ),
        ),
      ),
    );
  }
}
