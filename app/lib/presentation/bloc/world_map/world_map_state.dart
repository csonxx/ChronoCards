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

class WorldMapLoaded extends WorldMapState {
  final String playerId;
  final List<WorldRegion> regions;
  final List<WorldLocation> locations;
  final List<WorldConnection> connections;
  final String? currentLocationId;
  final String currentRegionId;
  final String currentRegionName;
  final WorldLocation? selectedLocation;
  final List<String> selectedLocationDealers;
  final int locationVisitCount;
  final String? activeEvent;
  final int unlockedCount;
  final int totalCount;
  final bool isNavigating;
  final String? navigationMessage;
  final bool navigationSuccess;

  const WorldMapLoaded({
    required this.playerId,
    required this.regions,
    required this.locations,
    required this.connections,
    this.currentLocationId,
    required this.currentRegionId,
    required this.currentRegionName,
    this.selectedLocation,
    this.selectedLocationDealers = const [],
    this.locationVisitCount = 0,
    this.activeEvent,
    required this.unlockedCount,
    required this.totalCount,
    this.isNavigating = false,
    this.navigationMessage,
    this.navigationSuccess = false,
  });

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
    bool? isNavigating,
    String? navigationMessage,
    bool? navigationSuccess,
  }) {
    return WorldMapLoaded(
      playerId: playerId ?? this.playerId,
      regions: regions ?? this.regions,
      locations: locations ?? this.locations,
      connections: connections ?? this.connections,
      currentLocationId: currentLocationId ?? this.currentLocationId,
      currentRegionId: currentRegionId ?? this.currentRegionId,
      currentRegionName: currentRegionName ?? this.currentRegionName,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedLocationDealers: selectedLocationDealers ?? this.selectedLocationDealers,
      locationVisitCount: locationVisitCount ?? this.locationVisitCount,
      activeEvent: activeEvent ?? this.activeEvent,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      totalCount: totalCount ?? this.totalCount,
      isNavigating: isNavigating ?? this.isNavigating,
      navigationMessage: navigationMessage,
      navigationSuccess: navigationSuccess ?? this.navigationSuccess,
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
        selectedLocation,
        selectedLocationDealers,
        locationVisitCount,
        activeEvent,
        unlockedCount,
        totalCount,
        isNavigating,
        navigationMessage,
        navigationSuccess,
      ];
}

class WorldMapError extends WorldMapState {
  final String message;

  const WorldMapError(this.message);

  @override
  List<Object?> get props => [message];
}
