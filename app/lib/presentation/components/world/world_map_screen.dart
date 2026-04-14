import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../bloc/world_map/world_map_bloc.dart';
import '../../bloc/world_map/world_map_event.dart';
import '../../bloc/world_map/world_map_state.dart';
import 'world_map_view.dart';
import 'world_hud.dart';

/// World Map Screen - Full screen 2D map for world exploration
/// Navigable world map showing all 6 regions with their locations
class WorldMapScreen extends StatelessWidget {
  final String? playerId;

  const WorldMapScreen({super.key, this.playerId});

  @override
  Widget build(BuildContext context) {
    return ForceLandscape(
      child: BlocProvider(
        create: (context) => WorldMapBloc(playerId: playerId ?? 'player_1')
          ..add(LoadWorldMap()),
        child: const _WorldMapScreenContent(),
      ),
    );
  }
}

class _WorldMapScreenContent extends StatefulWidget {
  const _WorldMapScreenContent();

  @override
  State<_WorldMapScreenContent> createState() => _WorldMapScreenContentState();
}

class _WorldMapScreenContentState extends State<_WorldMapScreenContent> {
  bool _showHud = true;
  bool _showLocationPanel = false;

  void _toggleHud() {
    setState(() {
      _showHud = !_showHud;
    });
  }

  void _openLocationPanel() {
    setState(() {
      _showLocationPanel = true;
    });
  }

  void _closeLocationPanel() {
    setState(() {
      _showLocationPanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<WorldMapBloc, WorldMapState>(
        builder: (context, state) {
          if (state is WorldMapLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            );
          }

          if (state is WorldMapError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.healthRed),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<WorldMapBloc>().add(LoadWorldMap()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is WorldMapLoaded) {
            return Stack(
              children: [
                // Main world map view
                WorldMapView(
                  regions: state.regions,
                  locations: state.locations,
                  connections: state.connections,
                  currentLocationId: state.currentLocationId,
                  currentPlayerRegionId: state.currentRegionId,
                  onLocationTap: (location) {
                    context.read<WorldMapBloc>().add(SelectLocation(location));
                    _openLocationPanel();
                  },
                  onNavigate: (toLocationId) {
                    context.read<WorldMapBloc>().add(
                      NavigateToLocation(toLocationId),
                    );
                  },
                ),

                // World HUD overlay (top)
                if (_showHud)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: WorldHud(
                      currentRegionName: state.currentRegionName,
                      activeEvent: state.activeEvent,
                      unlockedCount: state.unlockedCount,
                      totalCount: state.totalCount,
                      onToggleHud: _toggleHud,
                    ),
                  ),

                // Location info panel (bottom slide-up)
                if (_showLocationPanel && state.selectedLocation != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LocationInfoPanel(
                      location: state.selectedLocation!,
                      dealers: state.selectedLocationDealers,
                      visitCount: state.locationVisitCount,
                      onClose: _closeLocationPanel,
                      onNavigate: (locationId) {
                        context.read<WorldMapBloc>().add(
                          NavigateToLocation(locationId),
                        );
                        _closeLocationPanel();
                      },
                    ),
                  ),

                // Toggle HUD button
                Positioned(
                  top: 60,
                  right: 16,
                  child: IconButton(
                    onPressed: _toggleHud,
                    icon: Icon(
                      _showHud ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textGold,
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
}

/// Landscape lock wrapper
class ForceLandscape extends StatelessWidget {
  final Widget child;

  const ForceLandscape({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return RotatedBox(
            quarterTurns: 1,
            child: child,
          );
        }
        return child;
      },
    );
  }
}
