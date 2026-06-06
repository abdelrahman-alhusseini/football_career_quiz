import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../widgets/pitch_background.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({
    super.key,
    this.title = 'Coming Soon',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF02101F).withOpacity(0.55),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.stadiumBlue.withOpacity(0.35),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppTheme.pitchGreen,
                      size: 54,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This mode will be added later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.subText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.pitchGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
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
