import 'package:equatable/equatable.dart';
import '../../../domain/entities/world_location.dart';

abstract class WorldMapEvent extends Equatable {
  const WorldMapEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorldMap extends WorldMapEvent {}

class SelectLocation extends WorldMapEvent {
  final WorldLocation location;

  const SelectLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class NavigateToLocation extends WorldMapEvent {
  final String toLocationId;

  const NavigateToLocation(this.toLocationId);

  @override
  List<Object?> get props => [toLocationId];
}

class RefreshWorldMap extends WorldMapEvent {}
