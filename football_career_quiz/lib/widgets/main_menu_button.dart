import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class MainMenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const MainMenuButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: highlighted
              ? AppTheme.neonGreen.withOpacity(0.16)
              : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: highlighted
                ? AppTheme.neonGreen.withOpacity(0.8)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: highlighted
                    ? AppTheme.neonGreen.withOpacity(0.22)
                    : Colors.white.withOpacity(0.08),
              ),
              child: Icon(icon, color: highlighted ? AppTheme.neonGreen : AppTheme.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.white.withOpacity(0.65),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
