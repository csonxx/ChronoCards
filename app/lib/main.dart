import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/battle_provider.dart';
import 'presentation/providers/save_provider.dart';
import 'presentation/screens/s2_open_world/open_world_screen.dart';
import 'presentation/screens/s3_card_draw/card_draw_screen.dart';
import 'presentation/screens/s5_battle/battle_screen.dart';
import 'presentation/screens/s6_economy/screens/economy_screen.dart';
import 'presentation/screens/save/save_list_screen.dart';
import 'presentation/screens/save/save_detail_screen.dart';
import 'presentation/screens/save/export_import_screen.dart';
import 'presentation/screens/faction/faction_list_screen.dart';
import 'presentation/screens/faction/faction_detail_screen.dart';

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
        // SaveProvider - 云存档系统
        ChangeNotifierProvider<SaveProvider>(
          create: (_) => SaveProvider(),
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
          '/faction_list': (context) => const FactionListScreen(),
          // 云存档路由
          '/saves': (context) {
            final playerId = ModalRoute.of(context)?.settings.arguments as String? ?? 'default_player';
            return SaveListScreen(playerId: playerId);
          },
          '/saves/detail': (context) {
            final save = ModalRoute.of(context)?.settings.arguments as GameSave?;
            if (save == null) {
              return const Scaffold(
                body: Center(child: Text('存档不存在')),
              );
            }
            return SaveDetailScreen(save: save);
          },
          '/saves/export_import': (context) => const ExportImportScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/battle') {
            final enemyId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (context) => BattleScreen(enemyId: enemyId),
            );
          }
          if (settings.name == '/faction_detail') {
            final faction = settings.arguments as Faction?;
            if (faction == null) {
              return MaterialPageRoute(
                builder: (context) => const FactionListScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => FactionDetailScreen(faction: faction),
            );
          }
          return null;
        },
      ),
    );
  }
}
