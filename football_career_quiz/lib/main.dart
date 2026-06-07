import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/game_provider.dart';
import 'providers/private_match_provider.dart';
import 'screens/coming_soon_screen.dart';
import 'screens/difficulty_screen.dart';
import 'screens/friend_mode_screen.dart';
import 'screens/home_screen.dart';
import 'screens/private_match_game_screen.dart';
import 'screens/solo_game_screen.dart';
import 'utils/app_theme.dart';
import 'utils/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const FootballCareerQuizApp());
}

class FootballCareerQuizApp extends StatelessWidget {
  const FootballCareerQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrivateMatchProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'Career Guess',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: HomeScreen.routeName,
        routes: {
          HomeScreen.routeName: (context) => const HomeScreen(),
          DifficultyScreen.routeName: (context) => const DifficultyScreen(),
          SoloGameScreen.routeName: (context) => const SoloGameScreen(),
          FriendModeScreen.routeName: (context) => const FriendModeScreen(),
          PrivateMatchGameScreen.routeName: (context) =>
              const PrivateMatchGameScreen(),
          '/coming-soon': (context) => const ComingSoonScreen(),
        },
      ),
    );
  }
}
