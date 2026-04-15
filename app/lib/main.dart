import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/battle_provider.dart';
import 'presentation/screens/s2_open_world/open_world_screen.dart';
import 'presentation/screens/s3_card_draw/card_draw_screen.dart';
import 'presentation/screens/s5_battle/battle_screen.dart';
import 'presentation/screens/s6_economy/screens/economy_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations - landscape for mobile gaming (battle/world screens)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portrait,
  ]);

  // Set system UI overlay style for immersive gaming
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  runApp(const ChronoCardsApp());
}

class ChronoCardsApp extends StatelessWidget {
  const ChronoCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // BattleProvider - lazily created when needed
        ChangeNotifierProvider<BattleProvider>(
          create: (_) => BattleProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ChronoCards',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const OpenWorldScreen(),
          '/card_draw': (context) => const CardDrawScreen(),
          '/battle': (context) => const BattleScreen(),
          '/economy': (context) => const EconomyScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/battle') {
            final enemyId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => BattleScreen(enemyId: enemyId),
            );
          }
          return null;
        },
      ),
    );
  }
}
