import 'package:equatable/equatable.dart';
import '../../../domain/entities/world_region.dart';
import '../../../domain/entities/world_location.dart';
import '../../../domain/entities/world_connection.dart';

abstract class WorldMapState extends Equatable {
  const WorldMapState();

  @override
  List<Object?> get props => [];
}

class WorldMapInitial extends WorldMapState {}

class WorldMapLoading extends WorldMapState {}

/// Navigation sub-state - extracted from WorldMapLoaded to reduce state size
class NavigationState extends Equatable {
  final bool isNavigating;
  final String? message;
  final bool success;

  const NavigationState({
    this.isNavigating = false,
    this.message,
    this.success = false,
  });

  @override
  List<Object?> get props => [isNavigating, message, success];
}

/// Selection sub-state - extracted from WorldMapLoaded
class SelectionState extends Equatable {
  final WorldLocation? location;
  final List<String> dealers;
  final int visitCount;

  const SelectionState({
    this.location,
    this.dealers = const [],
    this.visitCount = 0,
  });

  SelectionState copyWith({
    WorldLocation? location,
    List<String>? dealers,
    int? visitCount,
  }) {
    return SelectionState(
      location: location ?? this.location,
      dealers: dealers ?? this.dealers,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  @override
  List<Object?> get props => [location, dealers, visitCount];
}

class WorldMapLoaded extends Equatable {
  final String playerId;
  final List<WorldRegion> regions;
  final List<WorldLocation> locations;
  final List<WorldConnection> connections;
  final String? currentLocationId;
  final String currentRegionId;
  final String currentRegionName;
  final SelectionState selection;
  final String? activeEvent;
  final int unlockedCount;
  final int totalCount;
  final NavigationState navigationState;

  const WorldMapLoaded({
    required this.playerId,
    required this.regions,
    required this.locations,
    required this.connections,
    this.currentLocationId,
    required this.currentRegionId,
    required this.currentRegionName,
    this.selection = const SelectionState(),
    this.activeEvent,
    required this.unlockedCount,
    required this.totalCount,
    this.navigationState = const NavigationState(),
  });

  // Convenience getters for backward compatibility
  WorldLocation? get selectedLocation => selection.location;
  List<String> get selectedLocationDealers => selection.dealers;
  int get locationVisitCount => selection.visitCount;
  bool get isNavigating => navigationState.isNavigating;
  String? get navigationMessage => navigationState.message;
  bool get navigationSuccess => navigationState.success;

  WorldMapLoaded copyWith({
    String? playerId,
    List<WorldRegion>? regions,
    List<WorldLocation>? locations,
    List<WorldConnection>? connections,
    String? currentLocationId,
    String? currentRegionId,
    String? currentRegionName,
    WorldLocation? selectedLocation,
    List<String>? selectedLocationDealers,
    int? locationVisitCount,
    String? activeEvent,
    int? unlockedCount,
    int? totalCount,
    NavigationState? navigationState,
    SelectionState? selection,
  }) {
    return WorldMapLoaded(
      playerId: playerId ?? this.playerId,
      regions: regions ?? this.regions,
      locations: locations ?? this.locations,
      connections: connections ?? this.connections,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      currentRegionId: currentRegionId ?? this.currentRegionId,
      currentRegionName: currentRegionName ?? this.currentRegionName,
      selection: selection ?? this.selection.copyWith(
        location: selectedLocation ?? this.selection.location,
        dealers: selectedLocationDealers ?? this.selection.dealers,
        visitCount: locationVisitCount ?? this.selection.visitCount,
      ),
      activeEvent: activeEvent ?? this.activeEvent,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      totalCount: totalCount ?? this.totalCount,
      navigationState: navigationState ?? this.navigationState,
    );
  }

  @override
  List<Object?> get props => [
        playerId,
        regions,
        locations,
        connections,
        currentLocationId,
        currentRegionId,
        currentRegionName,
        selection,
        activeEvent,
        unlockedCount,
        totalCount,
        navigationState,
      ];
}

class WorldMapError extends WorldMapState {
  final String message;

  const WorldMapError(this.message);

  @override
  List<Object?> get props => [message];
}
