import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame/game.dart';
import 'core/network/network.dart';
import 'core/network/api_config.dart';
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
import 'game/arpg/arpg_game.dart';
import 'presentation/screens/arpg/arpg_battle_screen.dart';

/// Player ID storage key
const String _playerIdKey = 'player_id';
const String _deviceIdKey = 'device_id';

/// Initialize app - register device and get playerId
Future<void> _initializeApp() async {
  final prefs = await SharedPreferences.getInstance();

  // Get or create device ID
  String? deviceId = prefs.getString(_deviceIdKey);
  if (deviceId == null) {
    deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_deviceIdKey, deviceId);
  }

  // Check if playerId already exists
  String? playerId = prefs.getString(_playerIdKey);

  // Initialize global API client
  initializeApiClient(baseUrl: ApiConfig.apiBaseUrl);

  // If no playerId, register device
  if (playerId == null) {

    final response = await apiClient.registerPlayer(deviceId);

    if (response.success && response.data != null) {
      playerId = response.data!.playerId;
      await prefs.setString(_playerIdKey, playerId);
  
    } else {
      // Fallback: use device ID as player ID for offline play
  
      playerId = deviceId;
      await prefs.setString(_playerIdKey, playerId);
    }
  } else {

  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations - landscape for mobile gaming (battle/world screens)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for immersive gaming
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Initialize app - register device and get playerId
  await _initializeApp();

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
          create: (_) {
            final provider = SaveProvider();
            // Configure SaveProvider with backend URL
            provider.setApiBaseUrl(ApiConfig.apiBaseUrl);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ChronoCards',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const ArpgGameScreen(),
          '/card_draw': (context) => const CardDrawScreenEntry(),
          '/battle': (context) => const BattleScreen(),
          '/economy': (context) => const EconomyScreen(),
          '/faction_list': (context) => const FactionListScreen(),
          // ARPG游戏路由
          '/arpg': (context) => const ArpgGameScreen(),
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

/// ARPG游戏主界面
/// Flame游戏 + UI覆盖层
class ArpgGameScreen extends StatefulWidget {
  const ArpgGameScreen({super.key});
  
  @override
  State<ArpgGameScreen> createState() => _ArpgGameScreenState();
}

class _ArpgGameScreenState extends State<ArpgGameScreen> {
  late ArpgGame _game;
  
  @override
  void initState() {
    super.initState();
    _game = ArpgGame();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame游戏Canvas
          Positioned.fill(
            child: GameWidget(game: _game),
          ),
          // UI覆盖层
          const ArpgBattleScreen(),
        ],
      ),
    );
  }
}
