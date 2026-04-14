import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/world_region.dart';
import '../../../domain/entities/world_location.dart';
import '../../../domain/entities/world_connection.dart';
import 'world_map_event.dart';
import 'world_map_state.dart';

class WorldMapBloc extends Bloc<WorldMapEvent, WorldMapState> {
  final String playerId;

  WorldMapBloc({required this.playerId}) : super(WorldMapInitial()) {
    on<LoadWorldMap>(_onLoadWorldMap);
    on<SelectLocation>(_onSelectLocation);
    on<NavigateToLocation>(_onNavigateToLocation);
    on<RefreshWorldMap>(_onRefreshWorldMap);
  }

  Future<void> _onLoadWorldMap(
    LoadWorldMap event,
    Emitter<WorldMapState> emit,
  ) async {
    emit(WorldMapLoading());

    try {
      // Load world data - in real app this would call APIs:
      // GET /api/world/regions
      // GET /api/world/locations/{region_id}
      // GET /api/world/connections/{location_id}

      final regions = _getRegions();
      final locations = _getLocations();
      final connections = _getConnections();

      // Find player's current location (default to first unlocked)
      final currentLocation = locations.firstWhere(
        (l) => l.isUnlocked,
        orElse: () => locations.first,
      );

      final currentRegion = regions.firstWhere(
        (r) => r.id == currentLocation.regionId,
        orElse: () => regions.first,
      );

      final unlockedCount = locations.where((l) => l.isUnlocked).length;

      emit(WorldMapLoaded(
        playerId: playerId,
        regions: regions,
        locations: locations,
        connections: connections,
        currentLocationId: currentLocation.id,
        currentRegionId: currentRegion.id,
        currentRegionName: currentRegion.displayName,
        activeEvent: '限时活动：江湖秘宝',
        unlockedCount: unlockedCount,
        totalCount: locations.length,
      ));
    } catch (e) {
      emit(WorldMapError('Failed to load world map: $e'));
    }
  }

  void _onSelectLocation(
    SelectLocation event,
    Emitter<WorldMapState> emit,
  ) {
    final currentState = state;
    if (currentState is WorldMapLoaded) {
      emit(currentState.copyWith(
        selectedLocation: event.location,
        selectedLocationDealers: event.location.availableDealers,
        locationVisitCount: event.location.visitCount,
      ));
    }
  }

  Future<void> _onNavigateToLocation(
    NavigateToLocation event,
    Emitter<WorldMapState> emit,
  ) async {
    final currentState = state;
    if (currentState is WorldMapLoaded) {
      emit(currentState.copyWith(isNavigating: true));

      try {
        // Call API: POST /api/players/{id}/location/navigate
        // Request body: { "to_location_id": event.toLocationId }
        // Response: { "success": bool, "message": string, "encounter_type": string|null }

        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 800));

        final toLocation = currentState.locations.firstWhere(
          (l) => l.id == event.toLocationId,
        );

        // Check if path is valid
        final validConnection = currentState.connections.any((conn) =>
          (conn.fromLocationId == currentState.currentLocationId &&
           conn.toLocationId == event.toLocationId) ||
          (conn.fromLocationId == event.toLocationId &&
           conn.toLocationId == currentState.currentLocationId)
        );

        if (!validConnection && currentState.currentLocationId != event.toLocationId) {
          emit(currentState.copyWith(
            isNavigating: false,
            navigationSuccess: false,
            navigationMessage: '无法直接到达该地点，需要寻找其他路径。',
          ));
          return;
        }

        // Check if locked
        final connection = currentState.connections.firstWhere(
          (conn) =>
            (conn.fromLocationId == currentState.currentLocationId &&
             conn.toLocationId == event.toLocationId) ||
            (conn.fromLocationId == event.toLocationId &&
             conn.toLocationId == currentState.currentLocationId),
          orElse: () => const WorldConnection(
            id: '',
            fromLocationId: '',
            toLocationId: '',
            pathType: 'road',
          ),
        );

        if (connection.isLocked) {
          emit(currentState.copyWith(
            isNavigating: false,
            navigationSuccess: false,
            navigationMessage: '该路径被锁定，需要完成特定条件才能通行。',
          ));
          return;
        }

        // Check if location is unlocked
        if (!toLocation.isUnlocked) {
          emit(currentState.copyWith(
            isNavigating: false,
            navigationSuccess: false,
            navigationMessage: '${toLocation.name}尚未解锁，需要达到 ${toLocation.recommendedLevel} 级。',
          ));
          return;
        }

        // Navigate successfully
        final newRegion = currentState.regions.firstWhere(
          (r) => r.id == toLocation.regionId,
          orElse: () => currentState.regions.first,
        );

        // Update visit count
        final updatedLocations = currentState.locations.map((l) {
          if (l.id == toLocation.id) {
            return l.copyWith(visitCount: l.visitCount + 1);
          }
          return l;
        }).toList();

        emit(currentState.copyWith(
          currentLocationId: event.toLocationId,
          currentRegionId: newRegion.id,
          currentRegionName: newRegion.displayName,
          locations: updatedLocations,
          selectedLocation: toLocation,
          selectedLocationDealers: toLocation.availableDealers,
          locationVisitCount: toLocation.visitCount + 1,
          isNavigating: false,
          navigationSuccess: true,
          navigationMessage: '成功抵达 ${toLocation.name}！',
        ));

      } catch (e) {
        emit(currentState.copyWith(
          isNavigating: false,
          navigationSuccess: false,
          navigationMessage: '导航失败：$e',
        ));
      }
    }
  }

  void _onRefreshWorldMap(
    RefreshWorldMap event,
    Emitter<WorldMapState> emit,
  ) {
    add(LoadWorldMap());
  }

  // Mock data - in real app these come from API calls
  List<WorldRegion> _getRegions() => getDefaultWorldRegions();

  List<WorldLocation> _getLocations() => getDefaultWorldLocations();

  List<WorldConnection> _getConnections() => getDefaultWorldConnections();
}
