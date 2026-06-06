import 'dart:ui';

import 'package:flutter/material.dart';

class PitchBackground extends StatelessWidget {
  final Widget child;

  const PitchBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/stadium_bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // Dark overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.30),
                  Colors.black.withOpacity(0.58),
                ],
              ),
            ),
          ),
        ),

        // Slight blur so UI feels cleaner
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 0.35,
              sigmaY: 0.35,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.02),
            ),
          ),
        ),

        child,
      ],
    );
  }
}
