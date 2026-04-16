import 'package:equatable/equatable.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/world_position.dart';

abstract class OpenWorldState extends Equatable {
  const OpenWorldState();

  @override
  List<Object?> get props => [];
}

class OpenWorldInitial extends OpenWorldState {}

class OpenWorldLoading extends OpenWorldState {}

class OpenWorldLoaded extends OpenWorldState {
  final Player player;
  final List<WorldLocation> locations;
  final WorldLocation? currentLocation;

  const OpenWorldLoaded({
    required this.player,
    required this.locations,
    this.currentLocation,
  });

  @override
  List<Object?> get props => [player, locations, currentLocation];

  OpenWorldLoaded copyWith({
    Player? player,
    List<WorldLocation>? locations,
    WorldLocation? currentLocation,
  }) {
    return OpenWorldLoaded(
      player: player ?? this.player,
      locations: locations ?? this.locations,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

class OpenWorldError extends OpenWorldState {
  final String message;

  const OpenWorldError(this.message);

  @override
  List<Object?> get props => [message];
}
