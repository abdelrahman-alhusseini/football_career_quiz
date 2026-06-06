import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class ScoreBox extends StatelessWidget {
  final int score;
  final int round;
  final int totalRounds;

  const ScoreBox({
    super.key,
    required this.score,
    required this.round,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatPill(label: 'Score', value: score.toString(), color: AppTheme.gold),
        const SizedBox(width: 10),
        _StatPill(label: 'Round', value: '$round/$totalRounds', color: AppTheme.neonGreen),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withOpacity(0.18),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.white.withOpacity(0.55),
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
