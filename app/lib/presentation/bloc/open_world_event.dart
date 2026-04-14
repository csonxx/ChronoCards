import 'package:equatable/equatable.dart';
import '../../../domain/entities/world_position.dart';

abstract class OpenWorldEvent extends Equatable {
  const OpenWorldEvent();

  @override
  List<Object?> get props => [];
}

class LoadOpenWorld extends OpenWorldEvent {}

class MoveToLocation extends OpenWorldEvent {
  final WorldLocation location;

  const MoveToLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class InteractWithLocation extends OpenWorldEvent {
  final WorldLocation location;

  const InteractWithLocation(this.location);

  @override
  List<Object?> get props => [location];
}
