import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/pitch_background.dart';
import 'solo_game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  static const String routeName = '/difficulty';

  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
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
                              color: AppTheme.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pick your challenge. Random includes all players from every category.',
                      style: TextStyle(
                        color: AppTheme.subText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
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
                            examples: 'Messi, Ronaldo, Neymar, Salah, Haaland',
                          ),
                          SizedBox(height: 12),
                          _DifficultyCard(
                            title: 'Pro',
                            value: 'pro',
                            icon: Icons.local_fire_department_rounded,
                            description:
                                'Known players for regular football fans.',
                            examples:
                                'Sterling, Dybala, João Félix, Brahim Díaz',
                          ),
                          SizedBox(height: 12),
                          _DifficultyCard(
                            title: 'Legend',
                            value: 'legend',
                            icon: Icons.military_tech_rounded,
                            description:
                                'Older stars, retired icons, and harder famous careers.',
                            examples:
                                'Legends, cult heroes, tricky transfer paths',
                          ),
                          SizedBox(height: 12),
                          _DifficultyCard(
                            title: 'Expert',
                            value: 'expert',
                            icon: Icons.psychology_rounded,
                            description:
                                'Very hard players, journeymen, loans, and deep-ball knowledge.',
                            examples:
                                'Mid-table players, reserves, obscure paths',
                          ),
                          SizedBox(height: 12),
                          _DifficultyCard(
                            title: 'Random',
                            value: 'random',
                            icon: Icons.shuffle_rounded,
                            description:
                                'Anything can appear. Uses all 3000 players when the database is complete.',
                            examples: 'All categories mixed together',
                          ),
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
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String description;
  final String examples;

  const _DifficultyCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF02101F).withOpacity(0.70),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          context.read<GameProvider>().setDifficulty(value);
          Navigator.pushNamed(context, SoloGameScreen.routeName);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: value == 'random'
                  ? AppTheme.gold.withOpacity(0.42)
                  : AppTheme.stadiumBlue.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value == 'random'
                      ? AppTheme.gold.withOpacity(0.14)
                      : AppTheme.pitchGreen.withOpacity(0.12),
                  border: Border.all(
                    color: value == 'random'
                        ? AppTheme.gold.withOpacity(0.50)
                        : AppTheme.pitchGreen.withOpacity(0.38),
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                      value == 'random' ? AppTheme.gold : AppTheme.pitchGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.subText,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      examples,
                      style: TextStyle(
                        color:
                            value == 'random' ? AppTheme.gold : AppTheme.accent,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.text,
                size: 17,
              ),
            ],
          ),
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
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.text,
            size: 24,
          ),
        ),
      ),
    );
  }
}
