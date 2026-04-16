import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_position.dart';
import '../../bloc/open_world_bloc.dart';
import '../../bloc/open_world_event.dart';
import '../../bloc/open_world_state.dart';
import '../../widgets/player_status_bar.dart';
import '../../widgets/world_location_marker.dart';
import '../../widgets/virtual_joystick.dart';
import '../../widgets/interaction_button.dart';
import '../../widgets/landscape_lock_overlay.dart';
import '../../widgets/newbie_guide_dialog.dart';
import '../../widgets/character_menu_popup.dart';

/// S2 - Open World Screen (Main Scene)
/// The central hub where players navigate the game world
/// Mobile-optimized with virtual joystick and touch controls
class OpenWorldScreen extends StatefulWidget {
  const OpenWorldScreen({super.key});

  @override
  State<OpenWorldScreen> createState() => _OpenWorldScreenState();
}

class _OpenWorldScreenState extends State<OpenWorldScreen>
    with WidgetsBindingObserver {
  Offset _playerPosition = const Offset(0.5, 0.5);
  bool _hasSeenTutorial = false;
  bool _isPlayerMoving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkTutorialStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_tutorial') ?? false;
    setState(() {
      _hasSeenTutorial = seen;
    });
  }

  Future<void> _markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    setState(() {
      _hasSeenTutorial = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ForceLandscape(
      child: BlocProvider(
        create: (context) => OpenWorldBloc()..add(LoadOpenWorld()),
        child: _OpenWorldView(
          playerPosition: _playerPosition,
          onPlayerMove: (offset) {
            setState(() {
              _playerPosition = offset;
              _isPlayerMoving = true;
            });
          },
          onPlayerStop: () {
            setState(() {
              _isPlayerMoving = false;
            });
          },
          hasSeenTutorial: _hasSeenTutorial,
          isPlayerMoving: _isPlayerMoving,
          onTutorialComplete: _markTutorialSeen,
        ),
      ),
    );
  }
}

class _OpenWorldView extends StatefulWidget {
  final Offset playerPosition;
  final ValueChanged<Offset> onPlayerMove;
  final VoidCallback onPlayerStop;
  final bool hasSeenTutorial;
  final VoidCallback onTutorialComplete;
  final bool isPlayerMoving;

  const _OpenWorldView({
    required this.playerPosition,
    required this.onPlayerMove,
    required this.onPlayerStop,
    required this.hasSeenTutorial,
    required this.onTutorialComplete,
    required this.isPlayerMoving,
  });

  @override
  State<_OpenWorldView> createState() => _OpenWorldViewState();
}

class _OpenWorldViewState extends State<_OpenWorldView> {
  bool _showTutorial = false;
  WorldLocation? _nearbyLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.hasSeenTutorial) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            NewbieGuideDialog.show(
              context,
              onComplete: widget.onTutorialComplete,
            );
          }
        });
      }
    });
  }

  void _handleJoystickDirection(Offset direction) {
    // Move player based on joystick direction
    final newX = (widget.playerPosition.dx + direction.dx * 0.02).clamp(0.1, 0.9);
    final newY = (widget.playerPosition.dy - direction.dy * 0.02).clamp(0.1, 0.9);
    widget.onPlayerMove(Offset(newX, newY));

    // Check for nearby locations
    _checkNearbyLocation(Offset(newX, newY));
  }

  void _checkNearbyLocation(Offset position) {
    final state = context.read<OpenWorldBloc>().state;
    if (state is OpenWorldLoaded) {
      WorldLocation? nearest;
      double minDistance = double.infinity;

      for (final location in state.locations) {
        final dx = position.dx - location.x;
        final dy = position.dy - location.y;
        final distance = (dx * dx + dy * dy);

        if (distance < minDistance && distance < 0.05) {
          minDistance = distance;
          nearest = location;
        }
      }

      if (nearest != _nearbyLocation) {
        setState(() {
          _nearbyLocation = nearest;
        });
      }
    }
  }

  void _handleInteraction() {
    if (_nearbyLocation != null) {
      if (_nearbyLocation!.isUnlocked) {
        context.read<OpenWorldBloc>().add(MoveToLocation(_nearbyLocation!));
        _showLocationActionSheet(_nearbyLocation!);
      } else {
        _showLockedDialog(_nearbyLocation!);
      }
    } else {
      // Show character menu if no location nearby
      final state = context.read<OpenWorldBloc>().state;
      if (state is OpenWorldLoaded) {
        CharacterMenuPopup.show(
          context,
          player: state.player,
          onViewStats: () => _showStatsSheet(state.player),
          onViewCards: () => Navigator.pushNamed(context, '/card_draw'),
          onSettings: () => _showSettingsSheet(),
        );
      }
    }
  }

  void _showLocationActionSheet(WorldLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getLocationColor(location.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getLocationIcon(location.type),
                    color: _getLocationColor(location.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        location.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _enterLocation(location);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Enter ${_getLocationActionVerb(location.type)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterLocation(WorldLocation location) {
    if (location.type == WorldLocationType.battle) {
      Navigator.pushNamed(context, '/battle');
    } else if (location.type == WorldLocationType.cardShop) {
      Navigator.pushNamed(context, '/card_draw');
    }
  }

  String _getLocationActionVerb(WorldLocationType type) {
    switch (type) {
      case WorldLocationType.town:
        return 'Town';
      case WorldLocationType.dungeon:
        return 'Dungeon';
      case WorldLocationType.battle:
        return 'Battle';
      case WorldLocationType.cardShop:
        return 'Draw Cards';
      case WorldLocationType.event:
        return 'Event';
      case WorldLocationType.boss:
        return 'Boss Fight';
    }
  }

  void _showLockedDialog(WorldLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Text(
              'Location Locked',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(
                color: AppTheme.textGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reach Level ${location.recommendedLevel} to unlock this location.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Current: Level 1',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStatsSheet(player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Character Stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _buildStatRow('Health', '${player.health}/${player.maxHealth}', AppTheme.healthRed),
            _buildStatRow('Mana', '${player.mana}/${player.maxMana}', Colors.blue),
            _buildStatRow('Energy', '${player.energy}/${player.maxEnergy}', Colors.green),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up, color: AppTheme.accentGold),
              title: const Text('Sound', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Music & SFX', style: TextStyle(color: AppTheme.textSecondary)),
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: AppTheme.accentGold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppTheme.accentGold),
              title: const Text('Notifications', style: TextStyle(color: AppTheme.textPrimary)),
              trailing: Switch(
                value: false,
                onChanged: (v) {},
                activeColor: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<OpenWorldBloc, OpenWorldState>(
        builder: (context, state) {
          if (state is OpenWorldLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            );
          }

          if (state is OpenWorldError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.healthRed),
                  const SizedBox(height: 16),
                  Text(state.message, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<OpenWorldBloc>().add(LoadOpenWorld()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is OpenWorldLoaded) {
            return Stack(
              children: [
                // Background
                _buildWorldBackground(context),

                // Location markers with labels
                ..._buildLocationMarkers(context, state.locations),

                // Player character
                _buildPlayerCharacter(context),

                // Player status bar at top
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: PlayerStatusBar(player: state.player),
                ),

                // Virtual joystick (bottom-left)
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: VirtualJoystick(
                    onDirectionChanged: _handleJoystickDirection,
                    onReleased: widget.onPlayerStop,
                  ),
                ),

                // Interaction button (bottom-right)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: InteractionButton(
                    onPressed: _handleInteraction,
                    label: 'E',
                    isAvailable: true,
                  ),
                ),

                // Nearby location indicator
                if (_nearbyLocation != null)
                  Positioned(
                    bottom: 110,
                    right: 24,
                    child: _buildNearbyIndicator(_nearbyLocation!),
                  ),

                // Interaction hint
                if (_nearbyLocation != null)
                  Positioned(
                    bottom: 160,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                      ),
                      child: Text(
                        '${_nearbyLocation!.name} nearby',
                        style: const TextStyle(
                          color: AppTheme.textGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNearbyIndicator(WorldLocation location) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getLocationColor(location.type).withOpacity(0.3),
        border: Border.all(color: _getLocationColor(location.type), width: 2),
      ),
      child: Icon(
        _getLocationIcon(location.type),
        color: _getLocationColor(location.type),
        size: 24,
      ),
    );
  }

  Widget _buildPlayerCharacter(BuildContext context) {
    return Positioned(
      left: widget.playerPosition.dx * MediaQuery.of(context).size.width - 25,
      top: widget.playerPosition.dy * MediaQuery.of(context).size.height - 40,
      child: GestureDetector(
        onTap: () {
          final state = context.read<OpenWorldBloc>().state;
          if (state is OpenWorldLoaded) {
            CharacterMenuPopup.show(
              context,
              player: state.player,
              onViewStats: () => _showStatsSheet(state.player),
              onViewCards: () => Navigator.pushNamed(context, '/card_draw'),
              onSettings: () => _showSettingsSheet(),
            );
          }
        },
        child: Column(
          children: [
            // Player name tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: AppTheme.textGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Player sprite
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentGold, AppTheme.accentCosmic],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.5),
                    blurRadius: widget.isPlayerMoving ? 15 : 8,
                    spreadRadius: widget.isPlayerMoving ? 3 : 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.primaryDark,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldBackground(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF415A77),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: StarsPainter(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: GroundPainter(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLocationMarkers(
      BuildContext context, List<WorldLocation> locations) {
    return locations.map((location) {
      return Positioned(
        left: location.x * MediaQuery.of(context).size.width - 40,
        top: location.y * MediaQuery.of(context).size.height - 40,
        child: WorldLocationMarker(
          location: location,
          onTap: () {
            if (location.isUnlocked) {
              context.read<OpenWorldBloc>().add(MoveToLocation(location));
              _showLocationActionSheet(location);
            } else {
              _showLockedDialog(location);
            }
          },
        ),
      );
    }).toList();
  }

  Color _getLocationColor(WorldLocationType type) {
    switch (type) {
      case WorldLocationType.town:
        return AppTheme.manaBlue;
      case WorldLocationType.dungeon:
        return AppTheme.accentCosmic;
      case WorldLocationType.battle:
        return AppTheme.healthRed;
      case WorldLocationType.cardShop:
        return AppTheme.textGold;
      case WorldLocationType.event:
        return AppTheme.accentMystic;
      case WorldLocationType.boss:
        return AppTheme.accentGold;
    }
  }

  IconData _getLocationIcon(WorldLocationType type) {
    switch (type) {
      case WorldLocationType.town:
        return Icons.home;
      case WorldLocationType.dungeon:
        return Icons.castle;
      case WorldLocationType.battle:
        return Icons.sports_kabaddi;
      case WorldLocationType.cardShop:
        return Icons.style;
      case WorldLocationType.event:
        return Icons.celebration;
      case WorldLocationType.boss:
        return Icons.whatshot;
    }
  }
}

/// Custom painter for starry background effect
class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final stars = [
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.9, size.height * 0.12),
      Offset(size.width * 0.15, size.height * 0.3),
      Offset(size.width * 0.85, size.height * 0.25),
      Offset(size.width * 0.45, size.height * 0.35),
    ];

    for (final star in stars) {
      canvas.drawCircle(star, 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for ground/path
class GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryLight.withOpacity(0.5),
          AppTheme.primaryMid,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.15,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
