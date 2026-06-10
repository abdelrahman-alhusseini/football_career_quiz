import 'package:flutter/material.dart';

import '../widgets/pitch_background.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({
    super.key,
    this.title = 'Coming Soon',
  });

  static const Color premiumGold = Color(0xFFD9A441);
  static const Color softGold = Color(0xFFFFD36A);
  static const Color premiumBlue = Color(0xFF2D8CFF);
  static const Color cardBlack = Color(0xEE050910);
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
                Colors.black.withOpacity(0.45),
                Colors.black.withOpacity(0.78),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(1.4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        softGold.withOpacity(0.78),
                        premiumBlue.withOpacity(0.25),
                        premiumGold.withOpacity(0.62),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.42),
                        blurRadius: 28,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: premiumGold.withOpacity(0.16),
                        blurRadius: 26,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBlack,
                      borderRadius: BorderRadius.circular(29),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xEE0A1420),
                          Color(0xEE050910),
                          Color(0xF002050A),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white10,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                premiumGold.withOpacity(0.25),
                                premiumBlue.withOpacity(0.45),
                                softGold.withOpacity(0.95),
                                premiumGold.withOpacity(0.25),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: premiumGold.withOpacity(0.24),
                                blurRadius: 22,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.38),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF07101B).withOpacity(0.96),
                              border: Border.all(
                                color: softGold.withOpacity(0.42),
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: softGold,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                softGold,
                                premiumGold,
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
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
                        const SizedBox(height: 10),
                        const Text(
                          'This mode will be added later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedSilver,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text(
                              'Back',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: premiumGold,
                              foregroundColor: const Color(0xFF05070B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 15,
                              ),
                              elevation: 0,
                              shadowColor: premiumGold.withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
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
        ),
      ),
    );
  }
}
