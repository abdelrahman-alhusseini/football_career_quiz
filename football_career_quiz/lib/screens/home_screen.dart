import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';
import 'difficulty_screen.dart';
import 'friend_mode_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/';

  const HomeScreen({super.key});

  // Set this to true only if you want to see the invisible button areas.
  static const bool showButtonDebugBorders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/home_menu_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // SOLO MODE invisible button
              _InvisibleMenuButton(
                topFactor: 0.425,
                leftFactor: 0.085,
                widthFactor: 0.830,
                heightFactor: 0.120,
                debug: showButtonDebugBorders,
                onTap: () {
                  Navigator.pushNamed(context, DifficultyScreen.routeName);
                },
              ),

              // PLAY WITH FRIENDS invisible button
              _InvisibleMenuButton(
                topFactor: 0.570,
                leftFactor: 0.085,
                widthFactor: 0.830,
                heightFactor: 0.120,
                debug: showButtonDebugBorders,
                onTap: () {
                  Navigator.pushNamed(context, FriendModeScreen.routeName);
                },
              ),

              // ONLINE RANKED invisible button
              _InvisibleMenuButton(
                topFactor: 0.715,
                leftFactor: 0.085,
                widthFactor: 0.830,
                heightFactor: 0.120,
                debug: showButtonDebugBorders,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ComingSoonScreen(
                        title: 'Online Ranked',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvisibleMenuButton extends StatelessWidget {
  final double topFactor;
  final double leftFactor;
  final double widthFactor;
  final double heightFactor;
  final VoidCallback onTap;
  final bool debug;

  const _InvisibleMenuButton({
    required this.topFactor,
    required this.leftFactor,
    required this.widthFactor,
    required this.heightFactor,
    required this.onTap,
    required this.debug,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * topFactor,
      left: MediaQuery.of(context).size.width * leftFactor,
      width: MediaQuery.of(context).size.width * widthFactor,
      height: MediaQuery.of(context).size.height * heightFactor,
      child: Material(
        color: debug ? Colors.red.withOpacity(0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          splashColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.04),
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
