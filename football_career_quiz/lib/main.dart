import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/game_provider.dart';
import 'screens/difficulty_screen.dart';
import 'screens/home_screen.dart';
import 'screens/solo_game_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const FootballCareerQuizApp());
}

class FootballCareerQuizApp extends StatelessWidget {
  const FootballCareerQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Football Career Quiz',
        theme: AppTheme.darkTheme,
        initialRoute: HomeScreen.routeName,
        routes: {
          HomeScreen.routeName: (_) => const HomeScreen(),
          DifficultyScreen.routeName: (_) => const DifficultyScreen(),
          SoloGameScreen.routeName: (_) => const SoloGameScreen(),
        },
      ),
    );
  }
}
