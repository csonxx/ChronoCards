import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_position.dart';
import '../../bloc/open_world_bloc.dart';
import '../../bloc/open_world_event.dart';
import '../../bloc/open_world_state.dart';
import '../../widgets/player_status_bar.dart';
import '../../widgets/world_location_marker.dart';

/// S2 - Open World Screen (Main Scene)
/// The central hub where players navigate the game world
class OpenWorldScreen extends StatelessWidget {
  const OpenWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OpenWorldBloc()..add(LoadOpenWorld()),
      child: const OpenWorldView(),
    );
  }
}

class OpenWorldView extends StatelessWidget {
  const OpenWorldView({super.key});

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
                  const Icon(Icons.error_outline,
                      size: 64, color: AppTheme.healthRed),
                  const SizedBox(height: 16),
                  Text(state.message,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<OpenWorldBloc>().add(LoadOpenWorld()),
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
                _buildWorldBackground(context, state),

                // Location markers
                ..._buildLocationMarkers(context, state.locations),

                // Player status bar at top
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: PlayerStatusBar(player: state.player),
                ),

                // Current location info at bottom
                if (state.currentLocation != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildLocationInfo(context, state.currentLocation!),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildWorldBackground(BuildContext context, OpenWorldLoaded state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D1B2A), // Dark blue top
            Color(0xFF1B263B), // Mid blue
            Color(0xFF415A77), // Lighter blue bottom
          ],
        ),
      ),
      child: Stack(
        children: [
          // Stars/particles effect
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: StarsPainter(),
          ),
          // Ground/path
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
        left: location.x * MediaQuery.of(context).size.width - 30,
        top: location.y * MediaQuery.of(context).size.height - 30,
        child: WorldLocationMarker(
          location: location,
          onTap: () {
            if (location.isUnlocked) {
              context.read<OpenWorldBloc>().add(MoveToLocation(location));
            } else {
              _showLockedDialog(context, location);
            }
          },
        ),
      );
    }).toList();
  }

  Widget _buildLocationInfo(BuildContext context, WorldLocation location) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getLocationIcon(location.type),
                color: AppTheme.accentGold,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                location.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            location.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${location.recommendedLevel}+',
                style: TextStyle(
                  color: AppTheme.textGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate based on location type
                  if (location.type == WorldLocationType.battle) {
                    Navigator.pushNamed(context, '/battle');
                  } else if (location.type == WorldLocationType.cardShop) {
                    Navigator.pushNamed(context, '/card_draw');
                  }
                },
                child: const Text('Enter'),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _showLockedDialog(BuildContext context, WorldLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('🔒 Location Locked'),
        content: Text(
          '${location.name} is locked.\nReach Level ${location.recommendedLevel} to unlock.',
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
}

/// Custom painter for starry background effect
class StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Simple star positions
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
