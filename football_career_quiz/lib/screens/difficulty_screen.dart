import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../utils/app_theme.dart';
import 'solo_game_screen.dart';

class DifficultyScreen extends StatelessWidget {
  static const String routeName = '/difficulty';

  const DifficultyScreen({super.key});

  // Turn this true only if you want to see the clickable areas.
  static const bool showButtonDebugBorders = false;

  void _selectDifficulty(BuildContext context, String difficulty) {
    context.read<GameProvider>().setDifficulty(difficulty);

    Navigator.pushNamed(
      context,
      SoloGameScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-screen AI generated difficulty image
                Image.asset(
                  'assets/images/difficulty_menu_bg.png',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: const Text(
                        'difficulty_menu_bg.png not found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),

                // Cool visible back button
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14, top: 10),
                      child: _CoolBackButton(
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ),

                // AMATEUR
                _InvisibleButton(
                  topFactor: 0.337,
                  leftFactor: 0.105,
                  widthFactor: 0.790,
                  heightFactor: 0.100,
                  debug: showButtonDebugBorders,
                  onTap: () {
                    _selectDifficulty(context, 'amateur');
                  },
                ),

                // PRO
                _InvisibleButton(
                  topFactor: 0.463,
                  leftFactor: 0.105,
                  widthFactor: 0.790,
                  heightFactor: 0.100,
                  debug: showButtonDebugBorders,
                  onTap: () {
                    _selectDifficulty(context, 'pro');
                  },
                ),

                // ELITE
                _InvisibleButton(
                  topFactor: 0.590,
                  leftFactor: 0.105,
                  widthFactor: 0.790,
                  heightFactor: 0.100,
                  debug: showButtonDebugBorders,
                  onTap: () {
                    _selectDifficulty(context, 'elite');
                  },
                ),

                // EXCEPTIONAL
                _InvisibleButton(
                  topFactor: 0.717,
                  leftFactor: 0.105,
                  widthFactor: 0.790,
                  heightFactor: 0.100,
                  debug: showButtonDebugBorders,
                  onTap: () {
                    _selectDifficulty(context, 'exceptional');
                  },
                ),

                // RANDOM
                _InvisibleButton(
                  topFactor: 0.844,
                  leftFactor: 0.105,
                  widthFactor: 0.790,
                  heightFactor: 0.095,
                  debug: showButtonDebugBorders,
                  onTap: () {
                    _selectDifficulty(context, 'all');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoolBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CoolBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF02101F).withOpacity(0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.stadiumBlue.withOpacity(0.70),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.pitchGreen.withOpacity(0.18),
        highlightColor: AppTheme.pitchGreen.withOpacity(0.08),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.stadiumBlue.withOpacity(0.22),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    );
  }
}

class _InvisibleButton extends StatelessWidget {
  final double topFactor;
  final double leftFactor;
  final double widthFactor;
  final double heightFactor;
  final VoidCallback onTap;
  final bool debug;

  const _InvisibleButton({
    required this.topFactor,
    required this.leftFactor,
    required this.widthFactor,
    required this.heightFactor,
    required this.onTap,
    required this.debug,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      top: size.height * topFactor,
      left: size.width * leftFactor,
      width: size.width * widthFactor,
      height: size.height * heightFactor,
      child: Material(
        color: debug ? Colors.red.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
