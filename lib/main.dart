import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/s2_open_world/open_world_screen.dart';
import 'presentation/screens/s3_card_draw/card_draw_screen.dart';
import 'presentation/screens/s5_battle/battle_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ChronoCardsApp());
}

class ChronoCardsApp extends StatelessWidget {
  const ChronoCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoCards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const OpenWorldScreen(),
        '/card_draw': (context) => const CardDrawScreen(),
        '/battle': (context) => const BattleScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == '/battle') {
          final enemyId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => BattleScreen(enemyId: enemyId),
          );
        }
        return null;
      },
    );
  }
}
